import os
import builtins
import argparse
import torch
import numpy as np 
import random
import torch.distributed as dist
import torch.nn as nn
import torch.utils.data as data

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--net', default='resnet18', type=str)
    parser.add_argument('--lr', default=1e-3, type=float, help='learning rate')
    parser.add_argument('--batch_size', default=16, type=int, help='batch size per GPU')
    parser.add_argument('--gpu', default=None, type=int)
    parser.add_argument('--start_epoch', default=0, type=int, 
                        help='start epoch number (useful on restarts)')
    parser.add_argument('--epochs', default=10, type=int, help='number of total epochs to run')
    # DDP configs:
    parser.add_argument('--world-size', default=-1, type=int, 
                        help='number of nodes for distributed training')
    parser.add_argument('--rank', default=-1, type=int, 
                        help='node rank for distributed training')
    parser.add_argument('--dist-url', default='env://', type=str, 
                        help='url used to set up distributed training')
    parser.add_argument('--dist-backend', default='nccl', type=str, 
                        help='distributed backend')
    parser.add_argument('--local_rank', default=-1, type=int, 
                        help='local rank for distributed training')
    args = parser.parse_args()
    return args

class ToyModel(nn.Module):
    def __init__(self):
        super(ToyModel, self).__init__()
        self.net1 = nn.Linear(10, 10)
        self.relu = nn.ReLU()
        self.net2 = nn.Linear(10, 5)

    def forward(self, x):
        return self.net2(self.relu(self.net1(x)))

class RandomDataset(torch.utils.data.Dataset):
    def __init__(self, num_samples):
        super().__init__()
        self.num_samples = num_samples

    def __len__(self):
        return self.num_samples

    def __getitem__(self, index):
        return torch.randn(20, 10), torch.randn(20, 5)

class DDPTraininer():

    def __init__(self, args) -> None:
        # DDP setting
        if "WORLD_SIZE" in os.environ:
            args.world_size = int(os.environ["WORLD_SIZE"])

        args.distributed = args.world_size > 1
        ngpus_per_node = torch.cuda.device_count()

        if args.distributed:
            if args.local_rank != -1: # for torch.distributed.launch
                args.rank = args.local_rank
                args.gpu = args.local_rank
            elif 'SLURM_PROCID' in os.environ: # for slurm scheduler
                args.rank = int(os.environ['SLURM_PROCID'])
                args.gpu = args.rank % torch.cuda.device_count()

            dist.init_process_group(backend=args.dist_backend, init_method=args.dist_url,
                                    world_size=args.world_size, rank=args.rank)

    
    def setup(self, args):
        ### Model ###
        model = ToyModel()
        if args.distributed:
            # For multiprocessing distributed, DistributedDataParallel constructor
            # should always set the single device scope, otherwise,
            # DistributedDataParallel will use all available devices.
            if args.gpu is not None:
                torch.cuda.set_device(args.gpu)
                model.cuda(args.gpu)
                model = torch.nn.parallel.DistributedDataParallel(model, device_ids=[args.gpu])
            else:
                model.cuda()
                model = torch.nn.parallel.DistributedDataParallel(model)
        else:
            raise NotImplementedError("Only DistributedDataParallel is supported. Failed to initialize model")
        
        ### optimizer ###
        optimizer = torch.optim.Adam(model.parameters(), lr=args.lr, weight_decay=1e-5)
    
        ### data ###
        train_dataset = RandomDataset()
        train_sampler = data.distributed.DistributedSampler(train_dataset, shuffle=True)
        train_loader = torch.utils.data.DataLoader(
                train_dataset, batch_size=args.batch_size, shuffle=(train_sampler is None),
                num_workers=args.workers, pin_memory=True, sampler=train_sampler, drop_last=True)
    
    
        torch.backends.cudnn.benchmark = True
        return model, optimizer, train_loader
    
    def train(self, train_loader, model, criterion, optimizer, args):
        print ("Starting to train")
        model, optimizer, train_loader = self.setup(args)

        ### main loop ###
        for epoch in range(args.start_epoch, args.epochs):
            np.random.seed(epoch)
            random.seed(epoch)
            # fix sampling seed such that each gpu gets different part of dataset
            if args.distributed: 
                train_loader.sampler.set_epoch(epoch)

            self.train_one_epoch(train_loader, model, criterion, optimizer, epoch, args)
        
        dist.destroy_process_group()


    def train_one_epoch(self, train_loader, model, criterion, optimizer, epoch, args):
        optimizer.zero_grad()
        for input, labels in train_loader:
            output = model(input)
            criterion(output, labels).backward()
            optimizer.step()

if __name__ == '__main__':
    args = parse_args()
    trainer = DDPTraininer(args)
    trainer.train(args)