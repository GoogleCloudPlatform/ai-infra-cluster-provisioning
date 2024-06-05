#!/bin/bash

len() {
  local -r arr=($@)
  echo "${#arr[@]}"
}

NRANKS_FACTORS=(1 2 4 8)

NHOSTS=$(len "$@")
echo "generating hostfiles for ${NHOSTS} hosts: "
for h in "$@"; do echo "$h"; done

mkdir -p "hostfiles${NHOSTS}"

for nr in "${NRANKS_FACTORS[@]}";
do
  rm -f "hostfiles${NHOSTS}/hostfile${nr}"
  touch "hostfiles${NHOSTS}/hostfile${nr}"
  for h in "$@";
  do
    echo "$h port=222 slots=${nr}" >> "hostfiles${NHOSTS}/hostfile${nr}"
  done
done
