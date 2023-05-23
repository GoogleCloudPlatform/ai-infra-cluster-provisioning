#!/bin/bash

. ./test/runner.sh

. ./test/scripts/enable_ops_agent.sh
. ./test/scripts/entrypoint_helpers.sh
. ./test/terraform/modules/cluster/mig/tests.sh
. ./test/terraform/modules/cluster/slurm/tests.sh
. ./test/terraform/modules/cluster/gke/tests.sh
. ./test/terraform/modules/common/dashboard/tests.sh
. ./test/terraform/modules/common/instance_template/tests.sh
. ./test/terraform/modules/common/network/tests.sh

runner::main "${@}"
