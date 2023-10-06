# syntax=docker/dockerfile:experimental

FROM nvcr.io/nvidia/pytorch:23.07-py3


# Ensure apt-get won't prompt for selecting options
ENV DEBIAN_FRONTEND=noninteractive
# libavdevice-dev rerquired for latest torchaudio
RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y \
  libsndfile1 sox \
  libfreetype6 \
  swig \
  ffmpeg \
  libavdevice-dev && \
  rm -rf /var/lib/apt/lists/*

# GCSfuse components
RUN apt-get update && apt-get install --yes --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
  && echo "deb http://packages.cloud.google.com/apt gcsfuse-focal main" \
    | tee /etc/apt/sources.list.d/gcsfuse.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
  && apt-get update \
  && apt-get install --yes gcsfuse \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && mkdir -p /gcs/training-data && mkdir -p /gcs/checkpoints

# NFS components (needed if using PD-SSD for shared file-system)
RUN apt-get -y update && apt-get install -y nfs-common

WORKDIR /workspace/

COPY requirements.txt requirements.txt

RUN MAX_JOBS=4 pip install 'flash-attn>=2.0.0.post1' --no-build-isolation \
  && pip install -r requirements.txt tokenizers sentencepiece ujson

RUN pip install nvidia-dlprof-pytorch-nvtx nvidia-pyindex nvidia-dlprof

COPY . .

# Check install
RUN python -c "from lit_gpt.model import GPT, Block, Config" && \
  python -c "import lightning as L" && \
  python -c "from lightning.fabric.strategies import FSDPStrategy"


