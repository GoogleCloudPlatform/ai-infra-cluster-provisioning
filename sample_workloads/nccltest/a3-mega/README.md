# GPUDirect-TCPXO NCCL Level Benchmarks

This document will walk you through how to build, push, and deploy the nccl-benchmark image for use on a GKE cluster configured with an A3 Mega nodepool.

## Building the Benchmark Docker Image

To build the latest benchmark docker image, run:

```shell
cd docker && docker build . -t nccl-benchmarks
```

**Note: A pre-built image is available in the values.yaml file**

## Running the TCPX NCCL Benchmarks

This section describes how you can run a 2-node world-level all-gather
benchmark at message sizes 1G and 8G.


If you intend to run with GKE, run:

```shell
cd gke
PARAMS="cluster.nNodes=2,"
PARAMS+="ncclBenchmarks.benchmarks=all_reduce_perf,"
PARAMS+="ncclBenchmarks.masks=0x0,"
helm install "${USER}-nccl-bm" . --set "$PARAMS"
```

Once the job is scheduled, find your master pod by running

```shell
kubectl get pods | grep "${USER}-nccl-bm.*pod0"
```

You can then follow the logs with

```shell
kubectl logs --follow <master-pod-name> -c nccl-benchmarks
```

### Finding Results

The container will log the output of Nvidia's nccl-test binaries for each of the tests that are requested in the parameters.

Each test run is logged separately. If you specify a release that uses multiple tests and multiple runs, the logs will be ordered by Test0Run0...Test0RunN...TestNRunN.

If `gcsBucket` is specified in the values.yaml file, then the logs will also be uploaded to the specified bucket.

### Breaking Down the Parameters

*Disclaimer: This is not a comprehensive list. Refer to `values.yaml` for a full list of tunable parameters.

#### Benchmark Parameters

|yaml path|Explanation|
|---|---|
|`ncclBenchmarks.benchmarks`|A CSV of benchmarks to run.|
|`ncclBenchmarks.masks`|A CSV of hexadecimal masks to use.|
|`ncclBenchmarks.msgSizeBegin`|The minimum message size to use,  |
|`ncclBenchmarks.msgSizeEnd`|The maximum message size to use, specified using 'G', 'M', 'K', or no suffix for bytes. [Source](https://github.com/NVIDIA/nccl-tests/blob/master/src/common.cu#L86). |
|`ncclBenchmarks.nGpusPerNode`|Number of GPUs per node to use.|
|`ncclBenchmarks.warmupIters`|Number of warmup iterations.|
|`ncclBenchmarks.runIters`|Number of iterations per run.|
|`ncclBenchmarks.nRuns`|Number of runs to aggregate over.|

##### Benchmarks, masks, and message sizes

You can specify multiple benchmarks, each with its own hexadecimal mask. **The
message sizes to sweep over are shared across all benchmarks.** Supported
benchmarks are `all_gather_perf`, `all_reduce_perf`, `reduce_scatter_perf`, `broadcast_perf`,
`reduce_perf`, `sendrecv_perf`, `scatter_perf`, `gather_perf`, `alltoall_perf`, and `hypercube_perf`.

*Note: If you want to use orchestrators relying on SSH to launch processes (e.g. MPI) to run communication patterns doing send-recvs between many GPU pairs (e.g. all-to-all), be sure to set `ulimit -n 1048576` for every process you start. To do this, you would need `CAP_SYS_RESOURCE` capability in your workload container, or make it privileged. If you are unsure whether your job orchestrator uses SSH, we recommend doing this out of caution.*

For each benchmark, you must supply a mask. The benchmark does a bitwise AND
between the rank and the mask to get a color, and ranks with the same color
goes in the same NCCL communicator. Examples:

- For a world-level NCCL operation, `MASK=0x0`.
- For a rail-aligned NCCL operation using all 8 GPUs on a VM, `MASK=0x7`.
- For a rail-aligned NCCL operation using only 4 GPUs on a VM, `MASK=0x3`.

*Note: Providing a mask larger than the numbers of GPUs on a VM will result in asymetric network traffic between VMs.*

Message sizes should be specified using 'G', 'M', 'K', or no suffix for bytes. For example 1G == 1024M == (1024 * 1024)K == (1024 * 1024 * 1024). [Source](https://github.com/NVIDIA/nccl-tests/blob/1292b25553bd0384f2faa2965f9d82b99797a348/src/common.cu#L86C1-L120C2).

##### WARMUP_ITERS, and RUN_ITERS

For each message size, the benchmark will measure the average latency and bus
bandwidth used. Each run consists of a few
warmup iterations, followed by the actual measurements used to derive
performance.

#### Switching Out Software Components

|GKE|Explanation|
|---|---|
|`rxdm.image`|Image for the TCPX RxDM.|
|`rxdm.tag`|Tag for the TCPX RxDM.|
|`rxdm.flags`|Runtime flags for the TCPX RxDM.|
|`ncclPlugin.image`|Image for the TCPX NCCL plugin.|
|`ncclPlugin.tag`|Tag for the TCPX NCCL plugin.|
|`ncclPlugin.unreservedCores`|Application reserved cores.|
|`ncclPlugin.envs`|Environment variables for the TCPX NCCL plugin.|

**For TCPX NCCL, any environment variables starting with `NCCL` will be picked
up by the benchmarking container.**

#### More Fine-Grained Node Placement Control

|yaml path|Explanation|
|---|---|
|`cluster.npPlacement`|If deliberate node pool placement should be enabled.|
|`cluster.nNps`|Number of node pools for job to span over.|
|`cluster.startNp`|Which node pool to start job on.|

In GKE, we have a flag to toggle deliberate superblock placement. If enabled,
we will try to split the job among `cluster.nNps` node pools, starting
from node pool `cluster.startNp`. **This guarantees closer affinity
between the job nodes and should be enabled for performance benchmarking.**
