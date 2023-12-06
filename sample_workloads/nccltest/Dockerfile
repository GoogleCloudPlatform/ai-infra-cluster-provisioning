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
# Install patched NCCL
RUN git clone https://github.com/NVIDIA/nccl.git nccl-netsupport && \
cd nccl-netsupport && \
git fetch --all --tags && \
git checkout -b github_nccl_2_18_5 05121c8191984aada7ed57dd8081bd987f73288f
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

# install a newer version of cmake, which could find cuda automatically
WORKDIR /third_party
RUN wget https://github.com/Kitware/CMake/releases/download/v3.26.4/cmake-3.26.4.tar.gz
RUN tar zxf cmake-3.26.4.tar.gz
WORKDIR /third_party/cmake-3.26.4
RUN ./bootstrap --parallel=16 && make -j 16 && make install

# build absl
WORKDIR /third_party
RUN git clone https://github.com/abseil/abseil-cpp.git
WORKDIR abseil-cpp
RUN git fetch --all --tags
RUN git checkout tags/20230125.3 -b build
WORKDIR build
RUN cmake -DCMAKE_CXX_STANDARD=17 -DCMAKE_POSITION_INDEPENDENT_CODE=ON -DABSL_USE_GOOGLETEST_HEAD=ON ..
RUN cmake --build . -j 8 --target all && cmake --install .

# build protobuf
WORKDIR /third_party
RUN git clone https://github.com/protocolbuffers/protobuf.git
WORKDIR protobuf
RUN git fetch --all --tags
RUN git checkout tags/v23.2 -b build
WORKDIR build
RUN cmake -DCMAKE_CXX_STANDARD=17 -DCMAKE_POSITION_INDEPENDENT_CODE=ON -Dprotobuf_BUILD_TESTS=OFF -Dprotobuf_ABSL_PROVIDER=package ..
RUN cmake --build . -j 8 --target all && cmake --install .

# copy all license files
WORKDIR /third_party/licenses
RUN cp ../nccl-netsupport/LICENSE.txt license_nccl.txt
RUN cp ../nccl-tests/LICENSE.txt license_nccl_tests.txt
RUN cp ../abseil-cpp/LICENSE license_absl.txt
RUN cp ../protobuf/LICENSE license_protobuf.txt

# Setup SSH to use port 222
RUN cd /etc/ssh/ && sed --in-place='.bak' 's/#Port 22/Port 222/' sshd_config && \
    sed --in-place='.bak' 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' sshd_config
RUN ssh-keygen -t rsa -b 4096 -q -f /root/.ssh/id_rsa -N ""
RUN touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys
RUN cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys

# remove NCCL source
WORKDIR /third_party/nccl-netsupport
RUN rm -rf src/ build/obj build/include .git

# build NCCL pipeline test source
WORKDIR /third_party/nccl-tests-pipeline
RUN rm -rf src/ build/obj build/include .git

# Install gcsfuse and python3.
RUN apt-get update \
  && apt-get install --yes \
      curl lsb-release cuda-nsight-systems-12-0 python3 python3-pip \
  && echo "deb https://packages.cloud.google.com/apt gcsfuse-$(lsb_release -c -s) main" \
    | tee /etc/apt/sources.list.d/gcsfuse.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
  && apt-get update \
  && apt-get install -y gcsfuse \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && mkdir /gcs

# Install required python3 packages.
RUN pip3 install humanize matplotlib numpy pandas

ADD scripts /workspace

WORKDIR /workspace
ENTRYPOINT ["/bin/bash", "/workspace/container_entry.sh"]