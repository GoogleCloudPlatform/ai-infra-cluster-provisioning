#!/bin/bash

. ./test/runner.sh

. ./test/pr/a3/terraform/modules/cluster/mig/tests.sh
. ./test/pr/a3/terraform/modules/cluster/mig-cos/tests.sh
. ./test/pr/a3/terraform/modules/cluster/slurm/tests.sh
. ./test/pr/a3/terraform/modules/cluster/gke/tests.sh
. ./test/pr/a3/terraform/modules/common/dashboard/tests.sh
. ./test/pr/a3/terraform/modules/common/instance_template/tests.sh
. ./test/pr/a3/terraform/modules/common/instance_group_manager/tests.sh
. ./test/pr/a3/terraform/modules/common/network/tests.sh
. ./test/pr/a3/terraform/modules/common/resource_policy/tests.sh
. ./test/pr/scripts/enable_ops_agent.sh
. ./test/pr/scripts/entrypoint_helpers.sh

runner::main "${@}"
