#!/bin/bash

. ./test/runner.sh

. ./test/pr/scripts/enable_ops_agent.sh
. ./test/pr/scripts/entrypoint_helpers.sh
. ./test/pr/terraform/modules/cluster/mig/tests.sh
. ./test/pr/terraform/modules/cluster/slurm/tests.sh
. ./test/pr/terraform/modules/cluster/gke/tests.sh
. ./test/pr/terraform/modules/common/dashboard/tests.sh
. ./test/pr/terraform/modules/common/instance_template/tests.sh
. ./test/pr/terraform/modules/common/network/tests.sh

runner::main "${@}"
