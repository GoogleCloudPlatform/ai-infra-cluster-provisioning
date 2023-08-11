#!/bin/bash

. ./test/runner.sh

. ./test/continuous/a3/terraform/modules/cluster/mig/tests.sh
. ./test/continuous/a3/terraform/modules/cluster/mig-with-container/tests.sh
. ./test/continuous/a3/terraform/modules/cluster/slurm/tests.sh
. ./test/continuous/a3/terraform/modules/cluster/gke/tests.sh

runner::main "${@}"
