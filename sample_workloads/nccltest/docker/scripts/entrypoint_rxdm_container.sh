#!/bin/bash
set -x

func_trap() {
  # Forward the received signal
  kill -"$1" "$pid"
}

trap_with_arg() {
    func="$1" ; shift
    for sig ; do
        trap "$func $sig" "$sig"
    done
}

chmod 755 /fts/kernel_tuning.sh
chmod 755 /fts/cleanup_tuning.sh
chmod 755 /fts/tuning_helper.sh
/fts/kernel_tuning.sh
# Make sure the dangling sctp connection has timeout from DXS.
# More details: b/321318973#comment39
sleep 15
chmod +x /fts/mtest_fastrak_gpumem_manager
/fts/mtest_fastrak_gpumem_manager "$@" &
pid=$!
trap_with_arg func_trap INT TERM

# Wait until a signal is triggered to stop the manager
wait $pid

# Because the manager uses custom signal handler, the process still runs its
# cleanup logic after the `wait` come back. So we have a polling loop to check
# if the process finish.
while kill -0 $pid 2>/dev/null; do
  sleep 1
done

/fts/cleanup_tuning.sh
