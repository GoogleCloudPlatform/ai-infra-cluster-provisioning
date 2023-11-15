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

COPY trainer_dpp.py trainer_dpp.py

RUN pip install nvidia-dlprof-pytorch-nvtx nvidia-pyindex nvidia-dlprof

# Check install
RUN python trainer_dpp.py


