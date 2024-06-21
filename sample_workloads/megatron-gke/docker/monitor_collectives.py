"""A utility to trace torch.distributed calls.

Traces torch.distributed collectives before dispatch. In particular, logs the
collective kind (all_reduce, all_to_all, ..), message size (10 MB), and which
GPU devices are participating ([0, 1, 6, 7]). These are logged as NVTX markers
by NVIDIA Nsight, as well as printed to stdout. By default, we only log
cross-node collective communications.

To assist with computing the effective bandwidth of a collective, a nominal
expression is provided in the doc string of each 'traced_<collective>'. This
also requires extracting the timings of the corresponding NCCL kernels.

Typical usage example:

  import utilities.monitor_collectives
  utilities.monitor_collectives.shunt_torch_communication()

When running a workload, also define TORCH_DISTRIBUTED_TRACING to be one of
'ALL' or 'CROSSNODE'. See `should_rank_record_comm` for added details.
"""


import functools
import inspect
import io
import json
import os
import pickle
import sys

import nvtx
import torch.cuda
import torch.distributed


_TRACE_MODE = os.environ.get('TORCH_DISTRIBUTED_TRACING', 'CROSSNODE').lower()


# Note: By default, we only target tracing *cross-node* communications.
# See 'should_rank_record_comm'
def shunt_torch_communication():
  if _TRACE_MODE == 'none':
    print('Tracing torch.distributed collectives disabled.', flush=True)
    return

  _shunt_torch_communication_objects()
  _shunt_torch_communication_calls()

  print('NVTX and print tracing of torch.distributed collectives enabled.',
        flush=True)


# Each wrapper should match format 'traced_<collective>'
def _shunt_torch_communication_calls():
  """Replaces torch.distributed.<target_collective> with a traced version.
  """
  target_collectives = [
      'barrier',
      'broadcast_object_list',
      'broadcast',
      'gather',
      'scatter',
      'reduce',
      'reduce_scatter',
      'reduce_scatter_tensor',
      'all_reduce',
      'all_gather',
      'all_gather_into_tensor',
      'all_to_all',
      'all_to_all_single',
      'batch_isend_irecv',
      'isend',
      'irecv',
      'send',
      'recv',
  ]

  this_module = sys.modules[__name__]
  for collective in target_collectives:
    original_fn = getattr(torch.distributed, collective)
    replaced_fn = getattr(this_module, 'traced_' + collective)
    setattr(torch.distributed, 'untraced_' + collective, original_fn)
    setattr(torch.distributed, collective, replaced_fn)


def _shunt_torch_communication_objects():
  original_p2p = torch.distributed.P2POp
  setattr(torch.distributed, 'UntracedP2POp', original_p2p)
  setattr(torch.distributed, 'P2POp', _TracedP2POp)


# Each 'traced_<comm>' defines a 'message_size' to compute B/W.
# Ref https://github.com/NVIDIA/nccl-tests/blob/master/doc/PERFORMANCE.md


# For each 'traced_<comm>' the corresponding API docs (including args, return)
# are available at https://pytorch.org/docs/stable/distributed.html


def traced_barrier(group=None, async_op=False, device_ids=None):
  """Intercepts invocations of torch.distributed.barrier.

  Args:
    group: Passed to torch.distributed.barrier
    async_op: Passed to torch.distributed.barrier
    device_ids: Passed to torch.distributed.barrier

  Returns:
    Output of torch.distributed.barrier
  """
  if _should_rank_record_comm(group):
    _emit_call_description('barrier', message_size=1, group=group)

  return torch.distributed.untraced_barrier(group, async_op, device_ids)


def traced_broadcast_object_list(object_list, src=0, group=None, device=None):
  """Intercepts invocations of torch.distributed.broadcast_object_list.

  Converts objects to tensor data using the pickle library. Then conducts a
  torch.distributed.broadcast call.

  Args:
    object_list: Passed to torch.distributed.broadcast_object_list
    src: Passed to torch.distributed.broadcast_object_list
    group: Passed to torch.distributed.broadcast_object_list
    device: Passed to torch.distributed.broadcast_object_list

  Returns:
    Output of torch.distributed.broadcast_object_list
  """

  if _should_rank_record_comm(group, root_rank=src):
    message_size = 0
    for obj in object_list:
      # Note: This computation is sadly redundant with underlying call :(
      # For now we don't expect this invocation to be in critical path.
      buf = io.BytesIO()
      pickle.Pickler(buf).dump(obj)
      message_size += buf.getbuffer().nbytes
    _emit_call_description(
        'broadcast_object_list', message_size, group, root_rank=src)

  return torch.distributed.untraced_broadcast_object_list(
      object_list, src, group, device)


def traced_broadcast(tensor, src, group=None, async_op=False):
  """Intercepts invocations of torch.distributed.broadcast.

  Calculate [Ring-B/W] = [Message Size]/[Kernel Time] for large [Message Size]

  https://images.nvidia.com/events/sc15/pdfs/NCCL-Woolley.pdf

  Args:
    tensor: Passed to torch.distributed.broadcast
    src: Passed to torch.distributed.broadcast
    group: Passed to torch.distributed.broadcast
    async_op: Passed to torch.distributed.broadcast

  Returns:
    Output of torch.distributed.broadcast
  """
  if _should_rank_record_comm(group, root_rank=src):
    message_size = tensor.nelement() * tensor.element_size()
    _emit_call_description('broadcast', message_size, group, root_rank=src)

  return torch.distributed.untraced_broadcast(
      tensor, src, group, async_op)


def traced_gather(
    tensor, gather_list=None, dst=0, group=None, async_op=False):
  """Intercepts invocations of torch.distributed.gather.

  Let T := sum([Receive Kernel Time from Rank i] for i != dst)
  Calculate [P2P-B/W] = [Message Size]/T

  Each of (n-1) ranks sends a message to the root.

  Note that any correction factors for the bus bandwidth (e.g. [n-1]/n) depend
  on the *definition* of 'Message Size'. In some cases, such as for 'gather', we
  define 'Message Size' so as to omit the size of data that is already local
  to the destination GPU for the 'gather' operation. In this case, no correction
  factor is needed. In NCCL tests, they assume all ranks send equal sized
  messages and include this size of data already resident on the destination
  GPU. Thus, in there case you see a (n-1)/n correction factor on calculating
  the bus bandwidth. In general, the goal of computing the bus bandwidth is
  to compare data transfer rates on the bus relative to peak bus bandwidth.
  See https://github.com/NVIDIA/nccl-tests/blob/master/doc/PERFORMANCE.md.

  https://github.com/NVIDIA/nccl-tests/blob/1a5f551ffd6e/src/gather.cu#L54
  https://github.com/pytorch/pytorch/blob/bfd995f0d6bf/torch/csrc/cuda/nccl.cpp#L1040

  Args:
    tensor: Passed to torch.distributed.gather
    gather_list: Passed to torch.distributed.gather
    dst: Passed to torch.distributed.gather
    group: Passed to torch.distributed.gather
    async_op: Passed to torch.distributed.gather

  Returns:
    Output of torch.distributed.gather
  """
  if _should_rank_record_comm(group, root_rank=dst, is_ring=False):
    message_size = functools.reduce(
        lambda sz, x: sz + x.nelement() * x.element_size(), gather_list, 0)
    message_size -= tensor.nelement() * tensor.element_size()

    _emit_call_description('gather', message_size, group, root_rank=dst)

  return torch.distributed.untraced_gather(
      tensor, gather_list, dst, group, async_op)


def traced_scatter(
    tensor, scatter_list=None, src=0, group=None, async_op=False):
  """Intercepts invocations of torch.distributed.scatter.

  Let T := sum([Send Kernel Time from Rank i] for i != src)
  Calculate [P2P-B/W] = [Message Size]/T

  Each of (n-1) ranks receives a message from the root.
  There is no (n-1)/n factor as we factor it in [Message Size].

  https://github.com/NVIDIA/nccl-tests/blob/1a5f551ffd6e/src/scatter.cu#L50
  https://github.com/pytorch/pytorch/blob/bfd995f0d6bf/torch/csrc/cuda/nccl.cpp#L1089

  Args:
    tensor: Passed to torch.distributed.scatter.
    scatter_list: Passed to torch.distributed.scatter.
    src: Passed to torch.distributed.scatter
    group: Passed to torch.distributed.scatter
    async_op: Passed to torch.distributed.scatter

  Returns:
    Output of torch.distributed.scatter
  """
  if _should_rank_record_comm(group, root_rank=src, is_ring=False):
    message_size = functools.reduce(
        lambda sz, x: sz + x.nelement() * x.element_size(), scatter_list, 0)
    message_size -= tensor.nelement() * tensor.element_size()

    _emit_call_description('scatter', message_size, group, root_rank=src)

  return torch.distributed.untraced_scatter(
      tensor, scatter_list, src, group, async_op)


def traced_reduce(
    tensor, dst, op=torch.distributed.ReduceOp.SUM, group=None, async_op=False):
  """Intercepts invocations of torch.distributed.reduce.

  Calculate [Ring-B/W] = [Message Size]/[Kernel Time] for large [Message Size]
  Also see 'traced_broadcast'

  Args:
    tensor: Passed to torch.distributed.reduce
    dst: Passed to torch.distributed.reduce
    op: Passed to torch.distributed.reduce
    group: Passed to torch.distributed.reduce
    async_op: Passed to torch.distributed.reduce

  Returns:
    Output of torch.distributed.reduce
  """
  if _should_rank_record_comm(group, root_rank=dst):
    message_size = tensor.nelement() * tensor.element_size()
    _emit_call_description('reduce', message_size, group, root_rank=dst)

  return torch.distributed.untraced_reduce(tensor, dst, op, group, async_op)


def traced_reduce_scatter(
    output,
    input_list,
    op=torch.distributed.ReduceOp.SUM,
    group=None,
    async_op=False):
  """Intercepts invocations of torch.distributed.reduce_scatter.

  Let n := [Group Size].
  Calculate [Ring-B/W] = (n-1)/n * [Message Size]/[Kernel Time]
  Assumes equal tensor sizes. It's the same as first half of ring All-Reduce.

  Args:
    output: Passed to torch.distributed.reduce_scatter
    input_list: Passed to torch.distributed.reduce_scatter
    op: Passed to torch.distributed.reduce_scatter
    group: Passed to torch.distributed.reduce_scatter
    async_op: Passed to torch.distributed.reduce_scatter

  Returns:
    Output of torch.distributed.reduce_scatter
  """
  if _should_rank_record_comm(group):
    message_size = output.nelement() * output.element_size()
    _emit_call_description('reduce_scatter', message_size, group)

  return torch.distributed.untraced_reduce_scatter(
      output, input_list, op, group, async_op)


# pylint: disable=redefined-builtin
def traced_reduce_scatter_tensor(
    output,
    input,
    op=torch.distributed.ReduceOp.SUM,
    group=None,
    async_op=False):
  """Intercepts invocations of torch.distributed.reduce_scatter_tensor.

  Similar to 'traced_reduce_scatter'

  Args:
    output: Passed to torch.distributed.reduce_scatter_tensor
    input: Passed to torch.distributed.reduce_scatter_tensor
    op: Passed to torch.distributed.reduce_scatter_tensor
    group: Passed to torch.distributed.reduce_scatter_tensor
    async_op: Passed to torch.distributed.reduce_scatter_tensor

  Returns:
    Output of torch.distributed.reduce_scatter_tensor
  """

  if _should_rank_record_comm(group):
    message_size = output.nelement() * output.element_size()
    _emit_call_description('reduce_scatter', message_size, group)

  return torch.distributed.untraced_reduce_scatter_tensor(
      output, input, op, group, async_op)


def traced_all_reduce(
    tensor, op=torch.distributed.ReduceOp.SUM, group=None, async_op=False):
  """Intercepts invocations of torch.distributed.all_reduce.

  Let n := [Group Size]
  Calculate [Ring-B/W] = 2(n-1)/n * [Message Size] / [Kernel Time]

  https://images.nvidia.com/events/sc15/pdfs/NCCL-Woolley.pdf

  Args:
    tensor: Passed to torch.distributed.all_reduce
    op: Passed to torch.distributed.all_reduce
    group: Passed to torch.distributed.all_reduce
    async_op: Passed to torch.distributed.all_reduce

  Returns:
    Output of torch.distributed.all_reduce
  """
  if _should_rank_record_comm(group):
    message_size = tensor.nelement() * tensor.element_size()
    _emit_call_description('all_reduce', message_size, group)

  return torch.distributed.untraced_all_reduce(
      tensor, op, group, async_op)


def traced_all_gather(tensor_list, tensor, group=None, async_op=False):
  """Intercepts invocations of torch.distributed.all_gather.

  Let n := [Group Size]
  Calculate [Ring-B/W] = (n-1)/n * [Message Size] / [Kernel Time]
  Assuming equal tensor sizes.

  Args:
    tensor_list: Passed to torch.distributed.all_gather
    tensor: Passed to torch.distributed.all_gather
    group: Passed to torch.distributed.all_gather
    async_op: Passed to torch.distributed.all_gather

  Returns:
    Output of torch.distributed.all_gather
  """
  if _should_rank_record_comm(group):
    message_size = functools.reduce(
        lambda size, x: size + x.nelement() * x.element_size(), tensor_list, 0)
    _emit_call_description('all_gather', message_size, group)

  return torch.distributed.untraced_all_gather(
      tensor_list, tensor, group, async_op)


def traced_all_gather_into_tensor(
    output_tensor, input_tensor, group=None, async_op=False):
  """Intercepts invocations of torch.distributed.all_gather_into_tensor.

  Similar 'traced_all_gather'

  Args:
    output_tensor: Passed to torch.distributed.all_gather_into_tensor
    input_tensor: Passed to torch.distributed.all_gather_into_tensor
    group: Passed to torch.distributed.all_gather_into_tensor
    async_op: Passed to torch.distributed.all_gather_into_tensor

  Returns:
    Output of torch.distributed.all_gather_into_tensor
  """
  if _should_rank_record_comm(group):
    message_size = output_tensor.nelement() * output_tensor.element_size()
    _emit_call_description('all_gather', message_size, group)

  return torch.distributed.untraced_all_gather_into_tensor(
      output_tensor, input_tensor, group, async_op)


# Note: The TCP Direct team intends to implement a custom version of AllToAll.
def traced_all_to_all(
    output_tensor_list, input_tensor_list, group=None, async_op=False):
  """Intercepts invocations of torch.distributed.all_to_all.

  Let S := sum([Message Size on Rank i] for i = 1..n) where n := [Group Size]
  Let T := [End of last Receive last rank] - [Start of first Send first rank]
  Calculate [Algo B/W] = S / T.

  There is no n/(n-1) correction factor as we factor it in [Message Size].

  https://github.com/NVIDIA/nccl-tests/blob/1a5f551ffd6e/src/alltoall.cu#L57
  https://github.com/pytorch/pytorch/blob/bfd995f0d6bf/torch/csrc/cuda/nccl.cpp#L911

  Args:
    output_tensor_list: Passed to torch.distributed.all_to_all.
    input_tensor_list: Passed to torch.distributed.all_to_all
    group: Passed to torch.distributed.all_to_all
    async_op: Passed to torch.distributed.all_to_all

  Returns:
    Output of torch.distributed.all_to_all
  """
  if _should_rank_record_comm(group):
    message_size = functools.reduce(
        lambda s, x: s + x.nelement() * x.element_size(), input_tensor_list, 0)

    # Omit bytes corresponding to send and receive on the same rank
    self_tensor = input_tensor_list[torch.distributed.get_rank(group)]
    message_size -= self_tensor.nelement() * self_tensor.element_size()

    _emit_call_description('all_to_all', message_size, group)

  return torch.distributed.untraced_all_to_all(
      output_tensor_list, input_tensor_list, group, async_op)


def traced_all_to_all_single(
    output,
    input,
    output_split_sizes=None,
    input_split_sizes=None,
    group=None,
    async_op=False):
  """Intercepts invocations of torch.distributed.all_to_all_single.

  Similar to 'traced_all_to_all'

  Args:
    output: Passed to torch.distributed.all_to_all_single.
    input: Passed to torch.distributed.all_to_all_single
    output_split_sizes: Passed to torch.distributed.all_to_all_single.
    input_split_sizes: Passed to torch.distributed.all_to_all_single
    group: Passed to torch.distributed.all_to_all_single
    async_op: Passed to torch.distributed.all_to_all_single

  Returns:
    Output of torch.distributed.all_to_all_single
  """
  if _should_rank_record_comm(group):
    self_rank = torch.distributed.get_rank(group)

    if input_split_sizes is not None:
      self_slice = input_split_sizes[self_rank]
    else:
      self_slice = input.size(dim=0) / torch.distributed.get_world_size(group)

    slice_nelement = input.nelement() / input.size(dim=0)
    message_size = input.nelement() * input.element_size()
    message_size -= self_slice * slice_nelement * input.element_size()

    _emit_call_description('all_to_all_single', message_size, group)

  return torch.distributed.untraced_all_to_all_single(
      output, input, output_split_sizes, input_split_sizes, group, async_op)


# Note: Each send and receive occurs on indepenent CUDA streams
def traced_batch_isend_irecv(p2p_op_list):
  """Intercepts invocations of torch.distributed.batch_isend_irecv.

  Calculate [P2P-B/W] = [Message Size]/[Kernel Time] for each send and recv.

  Args:
    p2p_op_list: Passed to torch.distributed.batch_isend_irecv.

  Returns:
    Output of torch.distributed.batch_isend_irecv
  """
  for p2p in p2p_op_list:
    if _should_rank_record_comm(p2p.group, peer_rank=p2p.peer, is_ring=False):
      api = 'send' if p2p.op == torch.distributed.untraced_isend else 'recv'

      message_size = p2p.tensor.nelement() * p2p.tensor.element_size()
      _emit_call_description(api, message_size, p2p.group, p2p.peer)

  return torch.distributed.untraced_batch_isend_irecv(p2p_op_list)


def traced_isend(tensor, dst, group=None, tag=0):
  """Intercepts invocations of torch.distributed.isend.

  Calculate [P2P-B/W] = [Message Size]/[Kernel Time]

  Args:
    tensor: Passed to torch.distributed.isend
    dst: Passed to torch.distributed.isend
    group: Passed to torch.distributed.isend
    tag: Passed to torch.distributed.isend.

  Returns:
    Output of torch.distributed.isend
  """
  if _should_rank_record_comm(group, peer_rank=dst, is_ring=False):
    message_size = tensor.nelement() * tensor.element_size()
    _emit_call_description('send', message_size, group, dst)

  return torch.distributed.untraced_isend(tensor, dst, group, tag)


def traced_irecv(tensor, src=None, group=None, tag=0):
  """Intercepts invocations of torch.distributed.irecv.

  Args:
    tensor: Passed to torch.distributed.irecv
    src: Passed to torch.distributed.irecv
    group: Passed to torch.distributed.irecv
    tag: Passed to torch.distributed.irecv.

  Returns:
    Output of torch.distributed.irecv
  """
  if _should_rank_record_comm(group, peer_rank=src, is_ring=False):
    message_size = tensor.nelement() * tensor.element_size()
    _emit_call_description('recv', message_size, group, src)

  return torch.distributed.untraced_irecv(tensor, src, group, tag)


def traced_send(tensor, dst, group=None, tag=0):
  """Intercepts invocations of torch.distributed.send.

  Args:
    tensor: Passed to torch.distributed.send
    dst: Passed to torch.distributed.send
    group: Passed to torch.distributed.send
    tag: Passed to torch.distributed.send.

  Returns:
    Output of torch.distributed.send
  """
  if _should_rank_record_comm(group, peer_rank=dst, is_ring=False):
    message_size = tensor.nelement() * tensor.element_size()
    _emit_call_description('send', message_size, group, dst)

  return torch.distributed.untraced_send(tensor, dst, group, tag)


def traced_recv(tensor, src=None, group=None, tag=0):
  """Intercepts invocations of torch.distributed.recv.

  Args:
    tensor: Passed to torch.distributed.recv
    src: Passed to torch.distributed.recv
    group: Passed to torch.distributed.recv
    tag: Passed to torch.distributed.recv.

  Returns:
    Output of torch.distributed.recv
  """
  if _should_rank_record_comm(group, peer_rank=src, is_ring=False):
    message_size = tensor.nelement() * tensor.element_size()
    _emit_call_description('recv', message_size, group, src)

  return torch.distributed.untraced_recv(tensor, src, group, tag)


@functools.lru_cache(maxsize=None)
def _should_rank_record_comm(
    group=None, peer_rank=None, root_rank=None, is_ring=True):
  """Decides whether a given torch.distributed collective should be recorded.

  Args:
    group: The torch process group (i.e. participating GPUs) in this collective.
    peer_rank: In direct peer to peer operations, the global rank of the peer.
    root_rank: The global rank of the root GPU, for collectives with a root.
    is_ring: Whether the default NCCL implementation uses a ring algorithm.
    Specifying 'peer_rank' and 'is_ring=True' are incompatible.

  Returns:
    Whether to record a descriptive NVTX marker, and possibly print a log trace.
  """
  if not _is_current_process_in_group(group):
    return False
  if _TRACE_MODE == 'crossnode' and not _is_crossnode_comm(group, peer_rank):
    return False
  if not is_ring and root_rank is not None:
    return torch.distributed.get_rank() == root_rank

  return True


def _is_current_process_in_group(group=None):
  return torch.distributed.get_rank(group) >= 0


@functools.lru_cache(maxsize=None)
def _is_crossnode_comm(group=None, peer_rank=None):
  """Whether this collective involves communication across nodes.

  Args:
    group: The torch process group (i.e. participating GPUs) in this collective.
    peer_rank: In direct peer to peer operations, the global rank of the peer.

  Returns:
    Whether this collective involves communications across nodes.
  """
  count_per_node = torch.cuda.device_count()

  if peer_rank is not None:
    this_node = int(torch.distributed.get_rank() / count_per_node)
    peer_node = int(peer_rank / count_per_node)
    return this_node != peer_node
  else:
    if group is not None:
      ranks = torch.distributed.get_process_group_ranks(group=group)
    else:
      ranks = [*range(torch.distributed.get_world_size())]

    nodes = list(map(lambda rank: int(rank / count_per_node), ranks))
    return any([node != nodes[0] for node in nodes])


def _emit_call_description(
    name, message_size, group=None, peer_rank=None, root_rank=None):
  call_description = _TorchDistributedCallDescriptor(
      name, message_size, group, peer_rank, root_rank).to_json()

  nvtx.mark(call_description)
  if _should_rank_print(group, peer_rank, root_rank):
    print(call_description)


class _TorchDistributedCallDescriptor:
  """Description of a torch.distributed comm call to be stored as NVTX marker.
  """

  def __init__(
      self, name, message_size, group=None, peer_rank=None, root_rank=None):
    self.name = name
    self.rank = torch.distributed.get_rank()
    self.source_line = _get_call_source_line()
    self.message_size = message_size
    self.device = torch.cuda.current_device()
    if group is not None:
      self.group_ranks = torch.distributed.get_process_group_ranks(group=group)
    if peer_rank is not None:
      self.peer_rank = peer_rank
    if root_rank is not None:
      self.root_rank = root_rank

  def to_json(self):
    return json.dumps(self, default=lambda o: o.__dict__)


def _should_rank_print(group=None, peer_rank=None, root_rank=None):
  if root_rank is not None:
    leader = root_rank
  elif group is not None:
    leader = torch.distributed.get_global_rank(group, 0)
  else:
    leader = 0

  return (peer_rank is not None) or torch.distributed.get_rank() == leader


# A fixed depth works for all cases here
def _get_call_source_line(depth=4):
  caller = inspect.getframeinfo(inspect.stack()[depth][0])
  return f'{caller.filename}:{caller.lineno}'


# We need to un-hide the original type for 'batch_isend_irecv' due to type
# checks performed by torch.distributed. This is not an issue as by then we
# have already recorded the call.
class _TracedP2POp(torch.distributed.P2POp):
  """Used to redirect torch.distributed.i{send,recv} on 'batch_isend_irecv'.
  """

  def __init__(self, op, tensor, peer, group=None, tag=0):
    original_op = _get_original_p2p_op(op)
    torch.distributed.UntracedP2POp.__init__(
        self, original_op, tensor, peer, group, tag)

  def __new__(cls, op, tensor, peer, group=None, tag=0):
    original_op = _get_original_p2p_op(op)
    return torch.distributed.UntracedP2POp.__new__(
        cls, original_op, tensor, peer, group, tag)


def _get_original_p2p_op(op):
  if op == torch.distributed.isend:
    return torch.distributed.untraced_isend
  elif op == torch.distributed.irecv:
    return torch.distributed.untraced_irecv


