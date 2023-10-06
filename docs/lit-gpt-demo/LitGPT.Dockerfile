# syntax=docker/dockerfile:experimental

ARG LITGPT_BASE

FROM ${LITGPT_BASE} as litgpt-base

RUN apt-get update && \
  apt-get install -y \
  tcpdump \
  iproute2 && \
  rm -rf /var/lib/apt/lists/*


COPY scripts /workspace/scripts


ENTRYPOINT ["/bin/bash", "/workspace/scripts/litgpt_container_entrypoint.sh"]