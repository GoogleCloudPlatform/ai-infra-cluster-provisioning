import os

import torch
import torch.distributed

local_rank = int(os.environ["LOCAL_RANK"])

print(f'Setting CUDA device to {local_rank}.')
torch.cuda.set_device(local_rank)

torch.distributed.init_process_group(backend="nccl")

x = torch.ones(100, device='cuda')
torch.distributed.all_reduce(x)
print(f'x: {x}')
