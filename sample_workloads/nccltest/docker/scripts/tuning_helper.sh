#!/bin/bash
set_and_verify() {
  local -r file="$1"
  local -r expected="$2"

  echo "${expected}" > "${file}"
  local -r value="$(< "${file}")"

  if [[ "$?" -ne 0 ]]; then
    logger "type=error file=\"${file}\""
    ((GLOBAL_NETBASE_ERROR_COUNTER+=1))
  else
    if [[ "${value}" != "${expected}" ]]; then
      logger "type=diff file=\"${file}\" value=${value} expected=${expected}"
      ((GLOBAL_NETBASE_ERROR_COUNTER+=1))
    fi
  fi
}

# Sets the file to some expected value, unless its
# current value is already larger than the expected value.
set_if_lt() {
  local -r file="$1"
  local -r expected="$2"

  local -r actual=$(cat "${file}")

  if [[ "${expected}" -gt "${actual}" ]]; then
    set_and_verify "${file}" "${expected}"
  else
    logger "skip setting file=\"${file}\" to smaller value=\"${expected}\", current value=\"${actual}\""
  fi
}


# Get all NIC names and populates a global array named "nics" where the first
# NIC in the array is the host NIC.
get_nics() {
  # Define an array for host NICs and one for GPU NICs
  local -a gpu_nics

  # Iterate over all network interfaces, excluding 'lo' and 'docker0'
  for interface in $(ls /sys/class/net | grep -v -E '^(lo|docker0)$'); do
      # Check if the interface is a symbolic link point to "device/virtual"
      if ls -l /sys/class/net/"${interface}" | grep -q "/devices/virtual"; then
          continue
      fi

      # Get default interface
      default_interface=$(ip route | awk '/^default/ { print $5 }')

      # Exclude default interface
      if [[ "$interface" != "$default_interface" ]]; then
        gpu_nics+=($interface)
      fi
  done

  nics=("${gpu_nics[@]}")
}
