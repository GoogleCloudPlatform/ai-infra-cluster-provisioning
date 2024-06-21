#!/bin/bash

export CUDA_DEVICE_MAX_CONNECTIONS=1

# Model Parallel argumnets
megatron_arguments=(
  --tensor-model-parallel-size 1
  --pipeline-model-parallel-size 1
)

# Model architecture arguments
megatron_arguments+=(
  --use-mcore-models
  --seq-length 4096
  --num-layers 32
  --hidden-size 4096
  --ffn-hidden-size 11008
  --num-attention-heads 32
  --swiglu
  --untie-embeddings-and-output-weights 
  --no-position-embedding
  --use-rotary-position-embeddings
  --max-position-embeddings 4096
  --normalization 'RMSNorm'
  --tokenizer-type 'Llama2Tokenizer' 
)

# General arguments
megatron_arguments+=(
  --micro-batch-size 2
  --global-batch-size 2048
  --fp16
  --use-flash-attn
  --ddp-bucket-size 1000000000
  --use-distributed-optimizer
  --no-masked-softmax-fusion
  --attention-softmax-in-fp32
  --overlap-grad-reduce
  --overlap-param-gather
  --train-iters 2000
  --log-interval 1
  --eval-iters 0
  --eval-interval 1000
  --num-workers 4
  --split 949,50,1
  --weight-decay 0.1 
  --adam-beta1 0.9 
  --adam-beta2 0.95 
  --init-method-std 0.006 
  --clip-grad 1.0 
  --lr 6.0e-5 
  --lr-decay-style cosine 
  --min-lr 6.0e-6
  --lr-warmup-iters 0
  --lr-decay-iters 430000 
  --profile
  --profile-step-start 40
  --profile-step-end 45
  --profile-ranks 0
)

