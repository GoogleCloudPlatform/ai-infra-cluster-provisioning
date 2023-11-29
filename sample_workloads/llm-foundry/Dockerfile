FROM nvcr.io/nvidia/pytorch:23.09-py3
WORKDIR /
RUN git clone https://github.com/mosaicml/llm-foundry.git
WORKDIR llm-foundry
RUN pip install -e ".[gpu]"
WORKDIR /llm-foundry/scripts
RUN python data_prep/convert_dataset_hf.py \
  --dataset c4 --data_subset en \
  --out_root my-copy-c4 --splits train_small val_small \
  --concat_tokens 2048 --tokenizer EleutherAI/gpt-neox-20b --eos_text '<|endoftext|>'

RUN apt-get update && apt-get install numactl -y

RUN pip install nvidia-pyindex && pip install nvidia-dlprof-pytorch-nvtx nvidia-dlprof

RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | \
  tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
  && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
  apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - \
  && apt-get update -y && apt-get install google-cloud-cli -y

ADD scripts/llmfoundry_container_entrypoint.sh .
ADD scripts/train.py train/train.py
ADD yamls/ train/yamls/

RUN chmod +x llmfoundry_container_entrypoint.sh
ENTRYPOINT ["/bin/bash", "/llm-foundry/scripts/llmfoundry_container_entrypoint.sh"]
