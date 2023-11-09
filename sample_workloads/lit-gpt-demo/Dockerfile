# syntax=docker/dockerfile:experimental

FROM nvcr.io/nvidia/pytorch:23.09-py3


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

WORKDIR /workspace/

COPY requirements.txt requirements.txt

RUN MAX_JOBS=4 FLASH_ATTENTION_FORCE_BUILD=TRUE pip install 'flash-attn==2.0.0post1' --no-build-isolation \
  && pip install -r requirements.txt tokenizers sentencepiece ujson

RUN pip install nvidia-dlprof-pytorch-nvtx nvidia-pyindex nvidia-dlprof

COPY . .

# Check install
RUN python -c "from lit_gpt.model import GPT, Block, Config" && \
  python -c "import lightning as L" && \
  python -c "from lightning.fabric.strategies import FSDPStrategy"


