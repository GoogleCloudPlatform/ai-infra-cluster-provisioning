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
    exit 1
}

# generate backoff times the way [this blog post]
# (https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/)
# describes. Slight modification  with the calculation of `base` that makes the
# output random numbers with maximums exponentially increasing to `max_backoff`
# over `max_attempts` intervals.
gen_backoff_times () {
    local max_attempts="${1}"
    local max_backoff="${2}"

    if [ "${max_attempts}" -le 1 ]; then
        fail "${0}: invalid max_attempts (${max_attempts}) -- must be greater than 1"
    fi

    if [ "${max_backoff}" -le 1 ]; then
        fail "${0}: invalid max_backoff (${max_backoff}) -- must be greater than 1"
    fi

    awk \
        -v max_attempts="${max_attempts}" \
        -v max_backoff="${max_backoff}" \
        -v seed="${RANDOM}" \
        'BEGIN {
            srand(seed);
            base=(max_backoff^(1/((max_attempts - 1))));
            for (attempt=0; attempt<max_attempts; ++attempt) {
                time_to_sleep=(rand() * base^attempt);
                printf("%.1f\n", time_to_sleep);
            }
        }'
}

# attempt a command at most `max_attempts` times with backoff times generated from `gen_backoff_times` above.
attempt () {
    local max_attempts="${1}"
    local max_backoff="${2}"
    local command_to_attempt="${3}"

    local attempt=1
    gen_backoff_times "${max_attempts}" "${max_backoff}" \
    | while read time_to_sleep; do
            echo "${command_to_attempt}: (attempt ${attempt} / ${max_attempts})..."
            if ${command_to_attempt}; then
                echo "${command_to_attempt}: success"
                return 0
            fi
            echo "${command_to_attempt}: sleeping ${time_to_sleep}s until next attempt"
            sleep "${time_to_sleep}"
            ((++attempt))
        done

    if [ "${attempt}" -gt "${max_attempts}" ]; then
        fail "${command_to_attempt}: max attempts (${max_attempts}) exceeded"
    fi
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
    attempt 10 32 install_opsagent

    echo "Install DCGM"
    install_dcgm
}

main
