FROM us-docker.pkg.dev/kernel-net-team/gpudirect-tcpx/nccl-tcpx-internal-testing:latest

ENV DEBIAN_FRONTEND='noninteractive'

# Install benchmark dependencies.
RUN apt-get update \
  && apt-get install --yes \
      curl lsb-release cuda-nsight-systems-12-0 python3 python3-pip \
      iproute2 tcpdump ethtool sysstat util-linux \
  && echo "deb https://packages.cloud.google.com/apt gcsfuse-$(lsb_release -c -s) main" \
    | tee /etc/apt/sources.list.d/gcsfuse.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
  && apt-get update \
  && apt-get install -y gcsfuse \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && mkdir /gcs

# Install required python3 packages.
RUN pip3 install humanize matplotlib numpy pandas requests

ADD scripts /workspace

WORKDIR /workspace
ENTRYPOINT ["/bin/bash", "/workspace/container_entry.sh"]
