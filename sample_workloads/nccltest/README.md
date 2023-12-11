# TCPX NCCL Level Benchmarks

This document will walk you through how to build, push, and deploy the nccl-benchmark image for use on a GKE cluster configured with an A3 nodepool.

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
PARAMS+="ncclBenchmarks.benchmarks=AllGather,"
PARAMS+="ncclBenchmarks.masks=0x0,"
PARAMS+="ncclBenchmarks.msgSizes=1G\,8G"
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

An example test output would look like:
```
benchmark: all_reduce_perf, mask: 0x0, run 1/1
# nThread 1 nGpus 1 minBytes 1048576 maxBytes 8589934592 step: 2(factor) warmup iters: 2 iters: 2 agg iters: 1 validation: 0 graph: 0
#
#                                                              out-of-place                       in-place
#       size         count      type   redop    root     time   algbw   busbw #wrong     time   algbw   busbw #wrong
#        (B)    (elements)                               (us)  (GB/s)  (GB/s)            (us)  (GB/s)  (GB/s)
     1048576        262144     float     sum      -1   1788.7    0.59    1.10    N/A   1725.9    0.61    1.14    N/A
     2097152        524288     float     sum      -1   1645.1    1.27    2.39    N/A   1649.8    1.27    2.38    N/A
     4194304       1048576     float     sum      -1   1701.3    2.47    4.62    N/A   1691.6    2.48    4.65    N/A
     8388608       2097152     float     sum      -1   1891.3    4.44    8.32    N/A   1911.9    4.39    8.23    N/A
    16777216       4194304     float     sum      -1   1932.8    8.68   16.28    N/A   2014.4    8.33   15.62    N/A
    33554432       8388608     float     sum      -1   2190.8   15.32   28.72    N/A   2395.8   14.01   26.26    N/A
    67108864      16777216     float     sum      -1   2367.6   28.34   53.15    N/A   2389.8   28.08   52.65    N/A
   134217728      33554432     float     sum      -1   3539.5   37.92   71.10    N/A   3266.7   41.09   77.04    N/A
   268435456      67108864     float     sum      -1   5969.3   44.97   84.32    N/A   5850.8   45.88   86.03    N/A
   536870912     134217728     float     sum      -1    11625   46.18   86.59    N/A    11737   45.74   85.77    N/A
  1073741824     268435456     float     sum      -1    23144   46.39   86.99    N/A    38777   27.69   51.92    N/A
  2147483648     536870912     float     sum      -1    45662   47.03   88.18    N/A    45522   47.17   88.45    N/A
  4294967296    1073741824     float     sum      -1    90227   47.60   89.25    N/A    90354   47.53   89.13    N/A
  8589934592    2147483648     float     sum      -1   179880   47.75   89.54    N/A   178867   48.02   90.05    N/A
# Out of bounds values : 0 OK
# Avg bus bandwidth    : 49.6371
```

If `gcsBucket` is specified in the values.yaml file, then the logs will also be uploaded to the specified bucket.

### Breaking Down the Parameters

*Disclaimer: This is not a comprehensive list. Refer to `values.yaml` for a full list of tunable parameters.

#### Benchmark Parameters

|yaml path|Explanation|
|---|---|
|`ncclBenchmarks.benchmarks`|A CSV of benchmarks to run.|
|`ncclBenchmarks.masks`|A CSV of hexadecimal masks to use.|
|`ncclBenchmarks.msgSizeEnd`|The minimum message size to use,  |
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

For each benchmark, you must supply a mask. The benchmark does a bitwise AND
between the rank and the mask to get a color, and ranks with the same color
goes in the same NCCL communicator. Examples:

- For a world-level NCCL operation, `MASK=0x0`.
- For a rail-aligned NCCL operation using all 8 GPUs on a VM, `MASK=0x7`.
- For a rail-aligned NCCL operation using only 4 GPUs on a VM, `MASK=0x3`.

*To guarantee symmetry in communication pattern across multiple VMs, we require
the mask to be less than the number of GPUs used per node.*

Message sizes should be specified using 'G', 'M', 'K', or no suffix for bytes. For example 1G == 1024M == (1024 * 1024)K == (1024 * 1024 * 1024). [Source](https://github.com/NVIDIA/nccl-tests/blob/1292b25553bd0384f2faa2965f9d82b99797a348/src/common.cu#L86C1-L120C2).

##### WARMUP_ITERS, and RUN_ITERS

For each iteration, the benchmark will measure the average latency and bus
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
|`cluster.sbPlacement`|If deliberate superblock placement should be enabled.|
|`cluster.nSuperblocks`|Number of superblocks for job to span over.|
|`cluster.startSuperblock`|Which superblock to start job on.|

In GKE, we have a flag to toggle deliberate superblock placement. If enabled,
we will try to split the job among `cluster.nSuperblocks` superblocks, starting
from superblock `cluster.startSuperblock`. **This guarantees closer affinity
between the job nodes and should be enabled for performance benchmarking.**

*Note that this feature is based on a `superblock` label in the Kubernetes
cluster and would not work if that label is missing. For example, Superblock 1 should be labeled with `superblock`: 1 *