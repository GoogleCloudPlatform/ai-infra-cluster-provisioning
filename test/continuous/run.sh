#!/bin/bash

. ./test/runner.sh

. ./test/continuous/a3/terraform/modules/cluster/gke/tests.sh
. ./test/continuous/a3/terraform/modules/cluster/gke-beta/tests.sh
. ./test/continuous/a3/terraform/modules/cluster/mig/tests.sh
. ./test/continuous/a3/terraform/modules/cluster/mig-cos/tests.sh
. ./test/continuous/a3/terraform/modules/cluster/slurm/tests.sh

runner::main "${@}"
