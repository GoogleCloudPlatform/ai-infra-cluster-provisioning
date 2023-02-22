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

attempt () {
    local max_attempts=${1}
    local command_to_attempt="${2}"

    local attempt=1
    while [ "${attempt}" -le "${max_attempts}" ]; do
        echo "${command_to_attempt}: (attempt ${attempt} / ${max_attempts})..."
        if ${command_to_attempt}; then
            echo "${command_to_attempt}: success"
            return 0
        fi
        ((++attempt))
    done

    if [ "${attempt}" -gt "${max_attempts}" ]; then
        fail "${command_to_attempt}: max attempts ($max_attempts) exceeded"
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

        systemctl start nvidia-dcgm
    }

    start_dcgm() {
        if ! systemctl is-active --quiet nvidia-dcgm; then
            systemctl reset-failed
            systemctl restart nvidia-dcgm
            sleep 5
        fi
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

    start_dcgm() {
        fail "start_dcgm: not implemented for redhat"
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
    attempt 3 install_opsagent

    echo "Install DCGM"
    install_dcgm

    echo "Start DCGM"
    attempt 3 start_dcgm
}

main
