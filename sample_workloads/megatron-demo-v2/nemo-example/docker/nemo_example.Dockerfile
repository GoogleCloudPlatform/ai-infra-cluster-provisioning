FROM nvcr.io/ea-bignlp/nemofw-training:23.05-py3

WORKDIR /workspace
RUN wget https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-vocab.json &&\
    wget https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt

