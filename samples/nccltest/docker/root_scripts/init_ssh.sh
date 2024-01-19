#!/bin/bash

PORT=${PORT:-222}

while true; do
  host=$1
  if [[ -z $host ]]; then
    break
  fi
  ssh -o StrictHostKeyChecking=no -p "${PORT}" "$host" \
    echo "Hello from ${host}"
  shift
done
