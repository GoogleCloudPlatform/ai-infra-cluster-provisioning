#!/bin/bash

. ./test/runner.sh

. ./test/continuous/a3/terraform/modules/cluster/gke/tests.sh
# removing gke-beta tests for A3 until we have A3 capacity available for testing.
# . ./test/continuous/a3/terraform/modules/cluster/gke-beta/tests.sh
. ./test/continuous/a3/terraform/modules/cluster/mig/tests.sh
. ./test/continuous/a3/terraform/modules/cluster/mig-cos/tests.sh
# Removing until slurm actually works on `a3-highgpu-8g`
#. ./test/continuous/a3/terraform/modules/cluster/slurm/tests.sh

runner::main "${@}"
