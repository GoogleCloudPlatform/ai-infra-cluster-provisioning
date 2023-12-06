#!/bin/bash

set -e

# Dumps the irq binding of $ifname for sanity checking.
dump_irq_binding() {
  local -r ifname="$1"
  echo -e "\n\ndump_irq_binding: ifname=${ifname}\n"
  for irq in $(ls "/sys/class/net/${ifname}/device/msi_irqs/"); do
    smp_affinity_list=$(cat "/proc/irq/${irq}/smp_affinity_list")
    echo irq="$irq" smp_affinity_list="$smp_affinity_list"
  done
}

set_irq_range() {
  local -r nic="$1"
  local core_start="$2"
  local num_cores="$3"

  # The user may not have this $nic configured on their VM, if not, just skip
  # it, no need to error out.
  if [[ ! -d "/sys/class/net/${nic}/device" ]]; then
    return;
  fi

  echo "Setting irq binding for ${nic}..."

  # We count the number of rx queues and assume number of rx queues == tx
  # queues. Currently the GVE configuration at boot is 16 rx + 16 tx.
  num_q=$(ls -1 "/sys/class/net/${nic}/queues/" | grep rx | wc -l)

  irq_start=$(ls -1 "/sys/class/net/${nic}/device/msi_irqs" | sort -n | head -n 1)
  idx=0
  for ((queue = 0; queue < "$num_q"; queue++)); do
    irq=$((irq_start + "$queue"))

    core=$(( core_start + idx ))

    # this is GVE's TX irq. See gve_tx_idx_to_ntfy().
    echo "$core" > /proc/irq/"$irq"/smp_affinity_list

    # this is GVE's RX irq. See gve_rx_idx_to_ntfy().
    echo "$core" > /proc/irq/$(("$irq" + "$num_q"))/smp_affinity_list

    idx=$(( (idx + 1) % num_cores ))
  done
}

a3_bind_irqs() {
  set_irq_range eth0 32 4
  set_irq_range eth1 36 8
  set_irq_range eth2 44 8
  set_irq_range eth3 88 8
  set_irq_range eth4 96 8
}

a3_bind_irqs

dump_irq_binding eth0
dump_irq_binding eth1
dump_irq_binding eth2
dump_irq_binding eth3
dump_irq_binding eth4