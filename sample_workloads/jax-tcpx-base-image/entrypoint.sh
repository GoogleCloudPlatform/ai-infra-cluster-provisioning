#!/usr/bin/env bash

set -x

function on_script_completion {
  # semaphore to cleanly exit hardware utilization monitor
  touch /run/tcpx/workload_terminated
}
trap on_script_completion EXIT

exec "$@"
