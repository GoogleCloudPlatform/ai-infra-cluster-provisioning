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
# Install NCCL
RUN git clone https://github.com/NVIDIA/nccl.git nccl-netsupport && \
cd nccl-netsupport && \
git fetch --all --tags && \
git checkout -b github_nccl_2_19_3 8c6c5951854a57ba90c4424fa040497f6defac46
WORKDIR nccl-netsupport
RUN make NVCC_GENCODE="$CUDA12_GENCODE $CUDA12_PTX" -j 16

WORKDIR /third_party
RUN git clone https://github.com/NVIDIA/nccl-tests.git
WORKDIR nccl-tests
RUN git fetch --all --tags
RUN make CUDA_HOME=/usr/local/cuda NCCL_HOME=/third_party/nccl-netsupport/build NVCC_GENCODE="$CUDA12_GENCODE $CUDA12_PTX" -j 16

WORKDIR /third_party
RUN git clone https://github.com/NVIDIA/nccl-tests.git nccl-tests-mpi
WORKDIR nccl-tests-mpi
RUN git fetch --all --tags
RUN make MPI=1 MPI_HOME=/usr/lib/x86_64-linux-gnu/openmpi CUDA_HOME=/usr/local/cuda NCCL_HOME=/third_party/nccl-netsupport/build NVCC_GENCODE="$CUDA12_GENCODE $CUDA12_PTX" -j 16

# copy all license files
WORKDIR /third_party/licenses
RUN cp ../nccl-netsupport/LICENSE.txt license_nccl.txt
RUN cp ../nccl-tests/LICENSE.txt license_nccl_tests.txt

# Setup SSH to use port 222
RUN cd /etc/ssh/ && sed --in-place='.bak' 's/#Port 22/Port 222/' sshd_config && \
    sed --in-place='.bak' 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' sshd_config
RUN ssh-keygen -t rsa -b 4096 -q -f /root/.ssh/id_rsa -N ""
RUN touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

# Install gcsfuse and python3.
RUN apt-get update \
  && apt-get install --yes \
      curl lsb-release cuda-nsight-systems-12-0 \
  && echo "deb https://packages.cloud.google.com/apt gcsfuse-$(lsb_release -c -s) main" \
    | tee /etc/apt/sources.list.d/gcsfuse.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
  && apt-get update \
  && apt-get install -y gcsfuse \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && mkdir /gcs

ADD root_scripts /scripts
RUN chmod +rx /scripts/gen_hostfiles.sh /scripts/init_ssh.sh /scripts/tune_net.sh

ADD scripts /workspace
RUN chmod +rx /workspace/container_entry.sh /workspace/mpi_entry.sh /workspace/run_nccl_benchmark.sh 

WORKDIR /workspace
ENTRYPOINT ["/bin/bash", "/workspace/container_entry.sh"]
