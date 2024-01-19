# Ref: https://pytorch.org/tutorials/intermediate/dist_tuto.html

import os

import torch
import torch.distributed as dist


def run(local_rank):
  global_rank = dist.get_rank()
  tensor = torch.zeros(1).cuda(local_rank)

  if global_rank == 0:
    for rank_recv in range(1, dist.get_world_size()):
      dist.send(tensor=tensor, dst=rank_recv)
      print("Rank {} sent data to Rank {}\n".format(0, rank_recv))
  else:
    dist.recv(tensor=tensor, src=0)
    print("Rank {} has received data from rank {}\n".format(global_rank, 0))


def init_processes(local_rank, backend="nccl"):
  dist.init_process_group(backend)
  run(local_rank)


if __name__ == "__main__":
  local_rank = int(os.environ["LOCAL_RANK"])
  print("local_rank: %d" % local_rank)
  init_processes(local_rank=local_rank)
