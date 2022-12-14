# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import sys
import subprocess
import torch
from torch.utils.data import DataLoader
from torchvision.datasets import CIFAR10
import torchvision.transforms as transforms

import ray
from ray.util.sgd.torch import TorchTrainer
from ray.util.sgd.torch import TrainingOperator
from ray.util.sgd.torch.resnet import ResNet18

def cifar_creator(config):
    """Returns dataloaders to be used in `train` and `validate`."""
    tfms = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize((0.4914, 0.4822, 0.4465),
                             (0.2023, 0.1994, 0.2010)),
    ])  # meanstd transformation

    # Using CIFAR-10 data set https://www.cs.toronto.edu/~kriz/cifar.html
    train_loader = DataLoader(
        CIFAR10(root="~/data", download=True, transform=tfms), batch_size=config["batch"])
    validation_loader = DataLoader(
        CIFAR10(root="~/data", download=True, transform=tfms), batch_size=config["batch"])
    return train_loader, validation_loader

def optimizer_creator(model, config):
    """Returns an optimizer (or multiple)"""
    return torch.optim.SGD(model.parameters(), lr=config["lr"])

subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'ray[tune]', 'ray[rllib]', 'torchvision'])
ray.init(address='auto')

CustomTrainingOperator = TrainingOperator.from_creators(
    model_creator=ResNet18, # A function that returns a nn.Module
    optimizer_creator=optimizer_creator, # A function that returns an optimizer
    data_creator=cifar_creator, # A function that returns dataloaders
    loss_creator=torch.nn.CrossEntropyLoss  # A loss function
    )

trainer = TorchTrainer(
    training_operator_cls=CustomTrainingOperator,
    config={"lr": 0.01, # used in optimizer_creator
            "batch": 64 # used in data_creator
           },
    num_workers=2,  # amount of parallelism
    use_gpu=torch.cuda.is_available(),
    use_tqdm=True)

stats = trainer.train()
print(trainer.validate())

trainer.shutdown()
print("success!")