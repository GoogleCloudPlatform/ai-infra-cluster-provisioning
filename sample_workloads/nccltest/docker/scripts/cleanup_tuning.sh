#!/bin/bash

source "/fts/tuning_helper.sh"
GLOBAL_NETBASE_ERROR_COUNTER=0

set -x
set -e

echo "Fastrak tuning cleanup starts..."

declare -a nics
get_nics

SYSFS="/hostsysfs"
PROCSYSFS="/hostprocsysfs"

if [[ -d $SYSFS && -d $PROCSYSFS ]]; then
  echo "Use mounted '$PROCSYSFS' and '$SYSFS' ."
else
  PROCSYSFS="/proc/sys"
  SYSFS="/sys"
  echo "Fall back to '$PROCSYSFS' and '$SYSFS' ."
fi

# Reset global
set_and_verify "$PROCSYSFS/net/ipv4/conf/all/rp_filter" "1"

# Reset interfaces
for nic_name in "${nics[@]}"; do
  set_and_verify "$PROCSYSFS/net/ipv4/conf/${nic_name}/rp_filter" "1"
done

# Reset interrupt coalescing
for nic_name in "${nics[@]}"; do
  ethtool -C "${nic_name}" rx-usecs 20 tx-usecs 50
done

set_and_verify "$PROCSYSFS/net/ipv4/tcp_mtu_probing" "0"
set_and_verify "$PROCSYSFS/net/ipv4/tcp_slow_start_after_idle" "0"
set_and_verify "$PROCSYSFS/net/ipv4/tcp_no_metrics_save" "0"
set_and_verify "$PROCSYSFS/net/ipv4/tcp_rmem" "$(printf "4096\t131072\t6291456")"
set_and_verify "$PROCSYSFS/net/ipv4/tcp_wmem" "$(printf "4096\t16384\t4194304")"
set_if_lt "$PROCSYSFS/net/core/somaxconn" "4096"
set_and_verify "$PROCSYSFS/net/ipv4/tcp_max_syn_backlog" "4096"

# Re-enable default Hystart: HYSTART_ACK_TRAIN (0x1) | HYSTART_DELAY (0x2):
set_and_verify "$SYSFS/module/tcp_cubic/parameters/hystart_detect" "3"

if [[ "${GLOBAL_NETBASE_ERROR_COUNTER}" -ne 0 ]]; then
  echo "Cleanup incomplete and incorrect! Number of Errors: ${GLOBAL_NETBASE_ERROR_COUNTER}"
  exit "${GLOBAL_NETBASE_ERROR_COUNTER}"
fi

echo "Fastrak tuning cleanup completes..."
