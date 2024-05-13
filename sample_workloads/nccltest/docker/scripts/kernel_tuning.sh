#!/bin/bash

source "/fts/tuning_helper.sh"
GLOBAL_NETBASE_ERROR_COUNTER=0

set -x
set -e

echo "Fastrak tuning setup starts..."

declare -a nics
get_nics

echo "${nics[@]}"

SYSFS="/hostsysfs"
PROCSYSFS="/hostprocsysfs"

if [[ -d $SYSFS && -d $PROCSYSFS ]]; then
  echo "Use mounted '$PROCSYSFS' and '$SYSFS' ."
else
  PROCSYSFS="/proc/sys"
  SYSFS="/sys"
  echo "Fall back to '$PROCSYSFS' and '$SYSFS' ."
fi

## Configure rp.filter for fabric nics
set_and_verify "$PROCSYSFS/net/ipv4/conf/all/rp_filter" "0"
for nic_name in "${nics[@]}"; do
  set_and_verify "$PROCSYSFS/net/ipv4/conf/${nic_name}/rp_filter" "0"
done

# Reduce interrupt coalescing for fabric nics
for nic_name in "${nics[@]}"; do
  ethtool -C "${nic_name}" rx-usecs 0 tx-usecs 0
done

# TCP tuning
set_and_verify "$PROCSYSFS/net/ipv4/tcp_mtu_probing" "0" # matches prodkernel; done: /b/297252196
set_and_verify "$PROCSYSFS/net/ipv4/tcp_slow_start_after_idle" "0" # matches prodkernel
set_and_verify "$PROCSYSFS/net/ipv4/tcp_no_metrics_save" "1" # matches prodkernel
set_and_verify "$PROCSYSFS/net/ipv4/tcp_rmem" "$(printf "4096\t540000\t15728640")" # matches prodkernel
set_and_verify "$PROCSYSFS/net/ipv4/tcp_wmem" "$(printf "4096\t262144\t67108864")" # matches prodkernel
set_if_lt "$PROCSYSFS/net/core/somaxconn" "4096" # matches prodkernel
set_and_verify "$PROCSYSFS/net/ipv4/tcp_max_syn_backlog" "4096" # matches prodkernel

set_and_verify "$SYSFS/module/tcp_cubic/parameters/hystart_detect" "2"

if [[ "${GLOBAL_NETBASE_ERROR_COUNTER}" -ne 0 ]]; then
  echo "Setup incomplete and incorrect! Number of Errors: ${GLOBAL_NETBASE_ERROR_COUNTER}"
  exit "${GLOBAL_NETBASE_ERROR_COUNTER}"
fi

echo "Fastrak tuning setup completes..."

