#!/bin/bash

. ./test/runner.sh

. ./test/pr/a3/terraform/modules/cluster/gke/tests.sh

runner::main "${@}"
