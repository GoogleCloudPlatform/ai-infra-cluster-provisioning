
# syntax=docker/dockerfile:experimental
ARG LITGPT_BASE
FROM ${LITGPT_BASE} as litgpt-base
RUN apt-get update && \
  apt-get install -y \
  tcpdump \
  iproute2 && \
  rm -rf /var/lib/apt/lists/*

RUN pip install ujson

# Prerequisite for removing GCSFuse dependency
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | \
  tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - \
  && apt-get update -y && apt-get install google-cloud-cli -y

COPY scripts /workspace/scripts
COPY openwebtext_trainer.py /workspace/pretrain/

ENTRYPOINT ["/bin/bash", "/workspace/scripts/litgpt_container_entrypoint.sh"]

