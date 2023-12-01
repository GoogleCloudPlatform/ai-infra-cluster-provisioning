FROM nvcr.io/nvidia/pytorch:23.09-py3
WORKDIR /
RUN git clone https://github.com/mosaicml/llm-foundry.git
WORKDIR llm-foundry
RUN pip install -e ".[gpu]"
WORKDIR /llm-foundry/scripts

RUN apt-get update && apt-get install numactl -y

RUN pip install nvidia-pyindex && pip install nvidia-dlprof-pytorch-nvtx nvidia-dlprof nvtx

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | \
  tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - \
  && apt-get update -y && apt-get install google-cloud-cli -y

# Added for parity
RUN pip install -U --index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/Triton-Nightly/pypi/simple/ triton-nightly==2.1.0.dev20230726014945
RUN pip install --no-dependencies git+https://github.com/stanford-futuredata/stk.git@v0.5
# Add patches sub-dir
# End parity

ADD scripts/llmfoundry_container_entrypoint.sh .
ADD scripts/train.py train/train.py
ADD scripts/tune_network_tcpx.sh .
ADD scripts/monitor_collectives.py train/monitor_collectives.py
ADD yamls/ train/yamls/
ADD patches/ patches/

RUN chmod +x llmfoundry_container_entrypoint.sh
RUN chmod +x tune_network_tcpx.sh
ENTRYPOINT ["/bin/bash", "/llm-foundry/scripts/llmfoundry_container_entrypoint.sh"]
