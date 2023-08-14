# Overview

## Purpose

The purpose of this tool is to provide a very quick and simple way to provision
a Google Cloud Platform (GCP) compute clusters of specifically
[accelerator optimized machines](https://cloud.google.com/compute/docs/accelerator-optimized-machines).

# Machine Type Comparison

| Feature \ Machine | A2 | [A3](./a3) |
| --- | --- | --- |
| Nvidia GPU Type | [A100 40GB](https://www.nvidia.com/en-us/data-center/a100/) and [A100 80GB](https://www.nvidia.com/en-us/data-center/a100/) | [H100](https://www.nvidia.com/en-us/data-center/h100/) |
| VM Shapes | [Several](https://cloud.google.com/compute/docs/gpus#a100-gpus) | 8 GPUs |
| GPUDirect-TCPX | Unsupported | Supported |
| Multi-NIC | Unsupported | 5 vNICS -- 1 for CPU and 4 for GPUs (one per pair of GPUs) |
