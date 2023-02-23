#!/bin/bash
# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LEGACY_MONITORING_PACKAGE='stackdriver-agent'
LEGACY_LOGGING_PACKAGE='google-fluentd'
OPSAGENT_PACKAGE='google-cloud-ops-agent'

fail() {
    echo >&2 "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $*"
    [ "${ON_INSTALL_OPS_AGENT_FAILURE}" == "continue" ]
    exit $?
}

# starting with `b^0==1` and ending with `b^(n-1)==y`,
# this function chooses base `b==y^(1/(n-1))` in order to
# output `n` values increasing exponentially from `1` to `y`
gen_exponential () {
    local n="${1}"
    local y="${2}"

    if [ "${n}" -eq 1 ]; then
        # edge case
        if [ "${y}" -eq 1 ]; then
            echo 1
            return 0
        else
            echo >&2 "${0}: n may not be 1 while y is not 1"
            return 1
        fi
    fi

    if [ "${n}" -le 1 ]; then
        echo >&2 "${0}: invalid n (${n}) -- must be greater than 1"
        return 1
    fi

    if [ "${y}" -lt 1 ]; then
        echo >&2 "${0}: invalid y (${y}) -- must be greater than or equal to 1"
        return 1
    fi

    awk -v n="${n}" -v y="${y}" \
        'BEGIN {
            b=(y^(1/((n - 1))));
            for (k=0; k<n; ++k) {
                y=b^k;
                printf("%.1f\n", y);
            }
        }'
}

# generate backoff times the way [this blog post]
# (https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)
# describes. Slight modification with the calculation of `base` that makes the
# `rand_between` upper bound output random numbers with maximums exponentially
# increasing to `max_backoff` over `retry_count` intervals.
gen_backoff_times () {
    local retry_count="${1}"
    local max_backoff="${2}"

    if [ "${retry_count}" -eq 0 ]; then
        return 0
    fi

    {
        if [ "${retry_count}" -eq 1 ]; then
            echo "${max_backoff}"
        else
            gen_exponential "${retry_count}" "${max_backoff}"
        fi;
    } | awk -v s="${RANDOM}" 'BEGIN {srand(s)} {printf("%.1f\n", rand()*$0)}'
}

# attempt a command at most `attempt_count` times with backoff times generated
# with `gen_backoff_times` above.
retry_with_backoff () {
    local attempt_count="${1}"
    local max_backoff="${2}"
    local command_to_attempt="${3}"

    # attempt outside the retry loop first
    local attempt=1
    echo "${command_to_attempt}: (attempt ${attempt} / ${attempt_count})..."
    if ${command_to_attempt}; then
        echo "${command_to_attempt}: success"
        return 0
    fi

    # retry up to `attempt_count - 1` times
    while read time_to_sleep; do
        ((++attempt))
        echo "${command_to_attempt}: sleeping ${time_to_sleep}s until next attempt"
        sleep "${time_to_sleep}"

        echo "${command_to_attempt}: (attempt ${attempt} / ${attempt_count})..."
        if ${command_to_attempt}; then
            echo "${command_to_attempt}: success"
            return 0
        fi
    done < <(gen_backoff_times "$((attempt_count - 1))" "${max_backoff}")

    echo >&2 "${command_to_attempt}: max attempts (${attempt_count}) exceeded"
    return 1
}


handle_debian() {
    is_legacy_monitoring_installed() {
        dpkg-query --show --showformat 'dpkg-query: ${Package} is installed\n' ${LEGACY_MONITORING_PACKAGE} |
            grep "${LEGACY_MONITORING_PACKAGE} is installed"
    }

    is_legacy_logging_installed() {
        dpkg-query --show --showformat 'dpkg-query: ${Package} is installed\n' ${LEGACY_LOGGING_PACKAGE} |
            grep "${LEGACY_LOGGING_PACKAGE} is installed"
    }

    is_legacy_installed() {
        is_legacy_monitoring_installed || is_legacy_logging_installed
    }

    is_opsagent_installed() {
        dpkg-query --show --showformat 'dpkg-query: ${Package} is installed\n' ${OPSAGENT_PACKAGE} |
            grep "${OPSAGENT_PACKAGE} is installed"
    }

    install_opsagent() {
        curl -s https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh |
            REPO_SUFFIX=20230214-1.1.1 bash -s -- --also-install
    }

    install_dcgm() {
        echo 'nvidia-uvm' >>/etc/modules

        # TODO: move to GCS
        cat >/etc/google-cloud-ops-agent/config.yaml <<EOF
metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
      collection_interval: 10s
    nvml:
      type: nvml
      collection_interval: 10s
    dcgm:
      type: dcgm
      collection_interval: 10s
  service:
    pipelines:
      dcgm:
        receivers:
          - dcgm
EOF
        systemctl restart google-cloud-ops-agent

        local distribution=$(. /etc/os-release;echo $ID$VERSION_ID | sed -e 's/\.//g')
        echo "Installing DCGM for distribution '${distribution}'"
        wget "https://developer.download.nvidia.com/compute/cuda/repos/${distribution}/x86_64/cuda-keyring_1.0-1_all.deb"
        dpkg -i cuda-keyring_1.0-1_all.deb && rm cuda-keyring_1.0-1_all.deb
        apt-get update
        apt-get install -y datacenter-gpu-manager

        sed -i '/\[Service\]/a RestartSec=2' /lib/systemd/system/nvidia-dcgm.service
        systemctl start nvidia-dcgm
    }
}

handle_redhat() {
    is_legacy_monitoring_installed() {
        rpm --query --queryformat 'package %{NAME} is installed\n' ${LEGACY_MONITORING_PACKAGE} |
            grep "${LEGACY_MONITORING_PACKAGE} is installed"
    }

    is_legacy_logging_installed() {
        rpm --query --queryformat 'package %{NAME} is installed\n' ${LEGACY_LOGGING_PACKAGE} |
            grep "${LEGACY_LOGGING_PACKAGE} is installed"
    }

    is_legacy_installed() {
        is_legacy_monitoring_installed || is_legacy_logging_installed
    }

    is_opsagent_installed() {
        rpm --query --queryformat 'package %{NAME} is installed\n' ${OPSAGENT_PACKAGE} |
            grep "${OPSAGENT_PACKAGE} is installed"
    }

    install_opsagent() {
        curl -s https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh | bash -s -- --also-install
    }

    install_dcgm() {
        fail "install_dcgm: not implemented for redhat"
    }
}

main() {
    if [ -f /etc/centos-release ] || [ -f /etc/redhat-release ] || [ -f /etc/oracle-release ] || [ -f /etc/system-release ]; then
        handle_redhat
    elif [ -f /etc/debian_version ] || grep -qi ubuntu /etc/lsb-release || grep -qi ubuntu /etc/os-release; then
        handle_debian
    else
        fail "Unsupported platform."
    fi

    if is_legacy_installed || is_opsagent_installed; then
        fail "Legacy or Ops Agent is already installed."
    fi

    echo "Install Ops Agent"
    retry_with_backoff 10 32 install_opsagent

    echo "Install DCGM"
    install_dcgm
}

main
