FROM nvcr.io/nvidia/pytorch:23.11-py3

WORKDIR /workspace

RUN git clone https://github.com/NVIDIA/Megatron-LM.git &&\
    cd Megatron-LM &&\
    git checkout 81dab6067a0ef4635270b7e6e56bdf79ccfd7731 &&\
    git -c user.name='dummy_user' -c user.email='dummy_email' cherry-pick --strategy=recursive -X theirs 0fda386c041e8d60d07e7aeeb77f96dd70f96a23 &&\
    git switch -c benchmark

COPY mixtral-8x7b-needed-fix.patch /workspace/Megatron-LM/mixtral-8x7b-needed-fix.patch
RUN cd Megatron-LM && git apply mixtral-8x7b-needed-fix.patch &&\
    git add megatron/core/transformer/attention.py &&\ 
    git -c user.name='dummy_user' -c user.email='dummy_email' commit -m "mixtral-8x7b-needed-fix"

# (We still need to verify the Grouped GEMM is launching CUDA kernels as expected)
RUN pip install sentencepiece
RUN TORCH_CUDA_ARCH_LIST="9.0" pip install git+https://github.com/fanshiqing/grouped_gemm@v1.0

# GCSfuse components (used to provide shared storage, not intended for high performance)
RUN apt-get update && apt-get install --yes --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
  && echo "deb https://packages.cloud.google.com/apt gcsfuse-buster main" \
    | tee /etc/apt/sources.list.d/gcsfuse.list \
  && echo "deb https://packages.cloud.google.com/apt cloud-sdk main" \
    | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
  && apt-get update \
  && apt-get install --yes gcsfuse \
  && apt-get install --yes google-cloud-cli \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && mkdir /gcs
