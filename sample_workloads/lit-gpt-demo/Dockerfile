# syntax=docker/dockerfile:experimental

FROM nvcr.io/nvidia/pytorch:24.01-py3


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

COPY requirements-all.txt .
COPY requirements.txt .

RUN pip install -r requirements-all.txt tokenizers sentencepiece ujson
RUN pip install --upgrade torchvision

RUN pip install nvidia-dlprof-pytorch-nvtx nvidia-pyindex nvidia-dlprof

COPY . .

# Check install
RUN python -c "from lit_gpt.model import GPT, Block, Config" && \
  python -c "import lightning as L" && \
  python -c "from lightning.fabric.strategies import FSDPStrategy"