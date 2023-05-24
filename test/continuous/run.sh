#!/bin/bash

. ./test/runner.sh

. ./test/continuous/terraform/modules/cluster/mig/tests.sh
. ./test/continuous/terraform/modules/cluster/slurm/tests.sh
. ./test/continuous/terraform/modules/cluster/gke/tests.sh

runner::main "${@}"
