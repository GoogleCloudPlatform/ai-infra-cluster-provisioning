import torch
import sys
from typing import Optional, Tuple, Union, Any
import nvtx
import inspect

class NsightCallback:
    def init(self):
        self.nsys_profile_step_multiple = 5
        self.backward_nvtx_range = None

    def on_train_batch_start(self, batch_idx: int, gradient_accumulation_steps: int) -> None:
        global_batch_idx = batch_idx / gradient_accumulation_steps
        print("In callback: {}".format(inspect.currentframe().f_code.co_name))
        if (
            global_batch_idx > 0
            and global_batch_idx % self.nsys_profile_step_multiple == 0
        ):
            print(f"Starting Nsys profiling")
            torch.cuda.cudart().cudaProfilerStart()

    def on_train_batch_end(
        self, batch_idx: int, gradient_accumulation_steps: int
    ) -> None:
        print("In callback: {}".format(inspect.currentframe().f_code.co_name))
        global_batch_idx = batch_idx // gradient_accumulation_steps
        global_batch_offset = batch_idx % gradient_accumulation_steps
        is_last_microbatch = global_batch_offset == gradient_accumulation_steps - 1

        if (
            global_batch_idx > 1
            and global_batch_idx % self.nsys_profile_step_multiple == 0
            and is_last_microbatch
        ):
            self.print(f"Stopping Nsys profiling")
            torch.cuda.cudart().cudaProfilerStop()
        if is_last_microbatch:
            self.print(f"HEARTBEAT: {global_batch_idx=}, {batch_idx=}")
            self.print(
                f"Max memory used: {torch.cuda.max_memory_allocated() / 1e9:.02f} GB"
            )
            sys.stdout.flush()
            sys.stderr.flush()

    
    def on_before_backward(self):
        print("In callback: {}".format(inspect.currentframe().f_code.co_name))
        self.backward_nvtx_range = nvtx.start_range(message="backward", color="red")

    def on_after_backward(self):
        print("In callback: {}".format(inspect.currentframe().f_code.co_name))
        if self.backward_nvtx_range:
            nvtx.end_range(self.backward_nvtx_range)

    def on_train_epoch_start(self) -> None:
        print("Resetting max memory allocation")
        torch.cuda.reset_peak_memory_stats()