# Copyright Lightning AI. Licensed under the Apache License 2.0, see LICENSE file.

import math
import sys
import time
from pathlib import Path
from typing import Optional, Tuple, Union

import lightning as L
import numpy as np
import torch
from lightning.fabric.loggers import CSVLogger
from lightning.fabric.strategies import FSDPStrategy
from lightning.fabric.utilities import ThroughputMonitor, measure_flops
from torch.utils.data import DataLoader, IterableDataset

# support running without installing as a package
wd = Path(__file__).parent.parent.resolve()
sys.path.append(str(wd))

from lit_gpt import Config
from lit_gpt.args import EvalArgs, IOArgs, TrainArgs
from lit_gpt.model import GPT, Block
from lit_gpt.utils import chunked_cross_entropy, estimate_flops, get_default_supported_precision, num_parameters


def setup(
    model_name: str = "Llama-2-13b-hf",
    data_dir: Path = Path("/data"),
    out_dir: Path = Path("out/openwebtext"),
    precision: Optional[str] = None,
    resume: Union[bool, Path] = False,
    eval_interval: int = 1000,
    save_interval: int = 1000,
    eval_iters: int = 100,
    log_interval: int = 1,
    devices: int = 4,
    learning_rate: float = 6e-4,
    weight_decay: float = 1e-1,
    beta1: float = 0.9,
    beta2: float = 0.95,
    lr_warmup_steps: int = 100,
    min_lr: float = 6e-5,
    global_batch_size: int = 6,
    micro_batch_size: int = 6,
    max_norm: float = 1.0,
    epochs: int = 1,
    train_epoch_size: int = 30,
) -> None:
    print(locals())
    precision = precision or get_default_supported_precision(training=True)

    if devices > 1:
        strategy = FSDPStrategy(
            auto_wrap_policy={Block},
            activation_checkpointing_policy={Block},
            state_dict_type="full",
            limit_all_gathers=True,
            cpu_offload=False,
        )
    else:
        strategy = "auto"

    logger = CSVLogger(out_dir.parent, out_dir.name, flush_logs_every_n_steps=log_interval)
    fabric = L.Fabric(devices=devices, strategy=strategy, precision=precision, loggers=logger)

    fabric.launch(
        main,
        devices,
        resume,
        Config.from_name(name=model_name),
        IOArgs(train_data_dir=data_dir, val_data_dir=data_dir, out_dir=out_dir),
        TrainArgs(
            save_interval=save_interval,
            log_interval=log_interval,
            global_batch_size=global_batch_size,
            micro_batch_size=micro_batch_size,
            lr_warmup_steps=lr_warmup_steps,
            epochs=epochs,
            epoch_size=train_epoch_size,
            learning_rate=learning_rate,
            weight_decay=weight_decay,
            beta1=beta1,
            beta2=beta2,
            max_norm=max_norm,
            min_lr=min_lr,
        ),
        EvalArgs(interval=eval_interval, max_iters=eval_iters),
    )


def main(
    fabric: L.Fabric,
    devices: int,
    resume: Union[bool, Path],
    config: Config,
    io_args: IOArgs,
    train_args: TrainArgs,
    eval_args: EvalArgs,
) -> None:
    validate_args(io_args, train_args, eval_args)

    if fabric.global_rank == 0:
        io_args.out_dir.mkdir(parents=True, exist_ok=True)

    fabric.seed_everything(1337, workers=True)  # same seed for every process to init model (FSDP)

    fabric.print(f"Loading model with {config.__dict__}")
    t0 = time.perf_counter()
    with fabric.init_module(empty_init=(fabric.world_size > 1)):
        model = GPT(config)
    model.apply(model._init_weights)

    fabric.print(f"Time to instantiate model: {time.perf_counter() - t0:.02f} seconds.")
    fabric.print(f"Total parameters {num_parameters(model):,}")

    model = fabric.setup(model)
    optimizer = torch.optim.AdamW(
        model.parameters(),
        lr=train_args.learning_rate,
        weight_decay=train_args.weight_decay,
        betas=(train_args.beta1, train_args.beta2),
        foreach=False,
    )
    optimizer = fabric.setup_optimizers(optimizer)

    train_data, val_data = load_datasets(io_args, max_seq_length=model.max_seq_length)
    train_dataloader = DataLoader(train_data, batch_size=train_args.micro_batch_size, num_workers=2)
    val_dataloader = DataLoader(val_data, batch_size=train_args.micro_batch_size, num_workers=2)
    train_dataloader, val_dataloader = fabric.setup_dataloaders(train_dataloader, val_dataloader)

    state = {"model": model, "optimizer": optimizer, "iter_num": 0, "step_count": 0}

    if resume is True:
        resume = max(io_args.out_dir.glob("*.pth"), key=lambda p: int(p.name.split("-")[1]))
    if resume:
        fabric.print(f"Resuming training from {resume}")
        fabric.load(resume, state)

    train_time = time.perf_counter()
    train(fabric, devices, state, train_dataloader, val_dataloader, io_args, train_args, eval_args)
    fabric.print(f"Training time: {(time.perf_counter()-train_time):.2f}s")
    if fabric.device.type == "cuda":
        fabric.print(f"Memory used: {torch.cuda.max_memory_allocated() / 1e9:.02f} GB")


def train(
    fabric: L.Fabric,
    devices: int,
    state: dict,
    train_dataloader: DataLoader,
    val_dataloader: DataLoader,
    io_args: IOArgs,
    train_args: TrainArgs,
    eval_args: EvalArgs,
) -> None:
    model = state["model"]
    optimizer = state["optimizer"]

    validate(fabric, model, val_dataloader, max_iters=2)  # sanity check

    with torch.device("meta"):
        meta_model = GPT(model.config)
        # "estimated" is not as precise as "measured". Estimated is optimistic but widely used in the wild.
        # When comparing MFU or FLOP numbers with other projects that use estimated FLOPs,
        # consider passing `flops_per_batch=estimated_flops` instead
        estimated_flops = estimate_flops(meta_model, training=True) * train_args.micro_batch_size
        fabric.print(f"Estimated TFLOPs: {estimated_flops * fabric.world_size / 1e12:.2f}")
        x = torch.randint(0, 1, (train_args.micro_batch_size, model.max_seq_length))
        forward_fn = lambda: meta_model(x)
        loss_fn = lambda y: chunked_cross_entropy(y, x, chunk_size=0)
        measured_flops = measure_flops(meta_model, forward_fn, loss_fn)
        fabric.print(f"Measured TFLOPs: {measured_flops * fabric.world_size / 1e12:.2f}")
        del meta_model, x

    throughput = ThroughputMonitor(fabric, window_size=50)
    total_t0 = time.perf_counter()

    train_iter = iter(train_dataloader)

    lr_warmup_iters = train_args.lr_warmup_steps * train_args.gradient_accumulation_iters(devices)
    for state["iter_num"] in range(state["iter_num"], train_args.max_iters(devices)):
        # determine and set the learning rate for this iteration
        lr = get_lr(
            train_args.learning_rate,
            state["iter_num"],
            lr_warmup_iters,
            train_args.max_iters(devices),
            min_lr=train_args.min_lr,
        )
        for param_group in optimizer.param_groups:
            param_group["lr"] = lr

        iter_num = state["iter_num"] + 1
        iter_t0 = time.perf_counter()

        input_ids, targets = next(train_iter)

        is_accumulating = iter_num % train_args.gradient_accumulation_iters(devices) != 0
        with fabric.no_backward_sync(model, enabled=is_accumulating):
            logits = model(input_ids)
            loss = chunked_cross_entropy(logits, targets, chunk_size=0)
            fabric.backward(loss / train_args.gradient_accumulation_iters(devices))

        if not is_accumulating:
            fabric.clip_gradients(model, optimizer, max_norm=train_args.max_norm)
            optimizer.step()
            optimizer.zero_grad()
            state["step_count"] += 1

        if iter_num % train_args.log_interval == 0:
            loss_item = loss.item()  # expensive device-to-host synchronization
            t1 = time.perf_counter()
            throughput.update(
                time=t1 - total_t0,
                batches=iter_num,
                samples=iter_num * train_args.micro_batch_size,
                lengths=iter_num * train_args.micro_batch_size * model.max_seq_length,
                flops=measured_flops * train_args.log_interval,
            )
            throughput.compute_and_log(step=iter_num)
            fabric.print(
                f"iter {iter_num} step {state['step_count']}: loss {loss_item:.4f}, iter time:"
                f" {(t1 - iter_t0) * 1000:.2f}ms{' (optimizer.step)' if not is_accumulating else ''}"
            )

        if not is_accumulating and state["step_count"] % eval_args.interval == 0:
            t0 = time.perf_counter()
            val_loss = validate(fabric, model, val_dataloader, max_iters=eval_args.max_iters)
            t1 = time.perf_counter() - t0
            fabric.print(f"step {iter_num}: val loss {val_loss.item():.4f}, val time: {t1 * 1000:.2f}ms")
            fabric.barrier()
        if not is_accumulating and state["step_count"] % train_args.save_interval == 0:
            checkpoint_path = io_args.out_dir / f"iter-{iter_num:06d}-ckpt.pth"
            fabric.print(f"Saving checkpoint to {str(checkpoint_path)!r}")
            fabric.save(checkpoint_path, state)


# FSDP has issues with `inference_mode`
@torch.no_grad()
def validate(fabric: L.Fabric, model: torch.nn.Module, val_dataloader: DataLoader, max_iters: int) -> torch.Tensor:
    fabric.print("Validating ...")
    model.eval()
    val_iter = iter(val_dataloader)

    losses = torch.zeros(max_iters, device=fabric.device)
    for k in range(max_iters):
        input_ids, targets = next(val_iter)
        logits = model(input_ids)
        losses[k] = chunked_cross_entropy(logits, targets, chunk_size=0)
    out = losses.mean()

    model.train()
    return out


def load_datasets(io_args: IOArgs, max_seq_length: int) -> Tuple["Dataset", "Dataset"]:
    train_data = Dataset(io_args.train_data_dir / "train.bin", max_seq_length)
    val_data = Dataset(io_args.val_data_dir / "val.bin", max_seq_length)
    return train_data, val_data


class Dataset(IterableDataset):
    def __init__(self, data_file: Path, max_seq_length: int):
        super().__init__()
        self.data_file = data_file
        self.max_seq_length = max_seq_length

    def __iter__(self):
        data = np.memmap(self.data_file, dtype=np.uint16, mode="r")
        while True:
            i = torch.randint(len(data) - self.max_seq_length, (1,)).item()
            x = torch.from_numpy((data[i : i + self.max_seq_length]).astype(np.int64))
            y = torch.from_numpy((data[i + 1 : i + 1 + self.max_seq_length]).astype(np.int64))
            yield x, y


# learning rate decay scheduler (cosine with linear warmup)
def get_lr(learning_rate: float, it: int, warmup_iters: int, max_iters: int, min_lr: float) -> float:
    # 1) linear warmup for warmup_iters steps
    if it < warmup_iters:
        return learning_rate * it / warmup_iters
    # 2) if it > max_iters, return min learning rate
    if it > max_iters:
        return min_lr
    # 3) in between, use cosine decay down to min learning rate
    decay_ratio = (it - warmup_iters) / (max_iters - warmup_iters)
    assert 0 <= decay_ratio <= 1
    coeff = 0.5 * (1.0 + math.cos(math.pi * decay_ratio))  # coeff ranges 0..1
    return min_lr + coeff * (learning_rate - min_lr)


def validate_args(io_args: IOArgs, train_args: TrainArgs, eval_args: EvalArgs) -> None:
    unsupported = [(io_args, ["checkpoint_dir"]), (train_args, ["max_tokens"]), (eval_args, ["max_new_tokens"])]
    for args, names in unsupported:
        for name in names:
            if getattr(args, name) is not None:
                raise ValueError(f"{__file__} doesn't support the {name!r} argument. This is set in {args}")
    required = [(io_args, ["train_data_dir", "val_data_dir"]), (train_args, ["epoch_size", "epochs", "max_norm"])]
    for args, names in required:
        for name in names:
            if getattr(args, name) is None:
                raise ValueError(f"{__file__} requires the {name!r} argument. This is set in {args}")


if __name__ == "__main__":
    torch.set_float32_matmul_precision("high")

    from jsonargparse import CLI

    CLI(setup)