FROM nvidia/cuda:12.0.0-devel-ubuntu20.04
ENV DEBIAN_FRONTEND='noninteractive'

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
        git openssh-server wget iproute2 vim libopenmpi-dev build-essential \
        cmake gdb python3 \
  protobuf-compiler libprotobuf-dev rsync libssl-dev \
  && rm -rf /var/lib/apt/lists/*

ARG CUDA12_GENCODE='-gencode=arch=compute_90,code=sm_90'
ARG CUDA12_PTX='-gencode=arch=compute_90,code=compute_90'

WORKDIR /third_party
RUN git clone https://github.com/NVIDIA/nccl.git nccl-netsupport && \
  cd nccl-netsupport && \
  git fetch --all --tags && \
  git checkout -b github_nccl_2_18_5 05121c8191984aada7ed57dd8081bd987f73288f
WORKDIR nccl-netsupport
RUN make NVCC_GENCODE="$CUDA12_GENCODE $CUDA12_PTX" -j 16

WORKDIR /third_party
RUN git clone https://github.com/NVIDIA/nccl-tests.git nccl-tests-mpi
WORKDIR nccl-tests-mpi
RUN git fetch --all --tags
RUN make MPI=1 MPI_HOME=/usr/lib/x86_64-linux-gnu/openmpi CUDA_HOME=/usr/local/cuda NCCL_HOME=/third_party/nccl-netsupport/build NVCC_GENCODE="$CUDA12_GENCODE $CUDA12_PTX" -j 16

RUN cd /etc/ssh/ && sed --in-place='.bak' 's/#Port 22/Port 222/' sshd_config && \
    sed --in-place='.bak' 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' sshd_config
RUN ssh-keygen -t rsa -b 4096 -q -f /root/.ssh/id_rsa -N ""
RUN touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
RUN /run/sshd

WORKDIR /third_party/nccl-netsupport
RUN rm -f build/lib/libnccl*
WORKDIR /usr/lib/x86_64-linux-gnu/
RUN rm -f libnccl*

WORKDIR /workspace
ENTRYPOINT ["/bin/bash"]
