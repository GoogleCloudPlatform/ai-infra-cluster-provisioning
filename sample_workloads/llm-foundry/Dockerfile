FROM mosaicml/llm-foundry:2.1.0_cu121_flash2-latest                                                                                                                                                                   
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

ADD scripts/llmfoundry_container_entrypoint.sh .
RUN chmod +x llmfoundry_container_entrypoint.sh
ENTRYPOINT ["/bin/bash", "/llm-foundry/scripts/llmfoundry_container_entrypoint.sh"]