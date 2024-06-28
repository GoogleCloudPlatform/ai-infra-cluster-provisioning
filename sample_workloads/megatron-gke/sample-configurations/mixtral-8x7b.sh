#!/bin/bash

export CUDA_DEVICE_MAX_CONNECTIONS=1

# Model Parallel argumnets
megatron_arguments=(
  --tensor-model-parallel-size 8
  --pipeline-model-parallel-size 1
  --sequence-parallel
  --use-distributed-optimizer 
  --ddp-bucket-size 100000000
)

# Model architecture arguments
megatron_arguments+=(
  --num-experts 8
  --expert-model-parallel-size 1
  --moe-router-load-balancing-type aux_loss
  --moe-router-topk 2
  --moe-aux-loss-coeff 1e-2
  --moe-grouped-gemm
  --use-mcore-models
  --disable-bias-linear
  --seq-length 4096
  --max-position-embeddings 32768
  --num-layers 32
  --hidden-size 4096
  --ffn-hidden-size 14336
  --num-attention-heads 32
  --init-method-std 0.01
  --attention-dropout 0.0
  --hidden-dropout 0.0
  --position-embedding-type rope
  --swiglu
  --untie-embeddings-and-output-weights
  --group-query-attention
  --num-query-groups 8
  --no-masked-softmax-fusion
  --no-position-embedding
  --normalization RMSNorm
  --use-flash-attn
  --tokenizer-type 'Llama2Tokenizer'
)

# General arguments
megatron_arguments+=(
  --bf16
  --micro-batch-size 3
  --global-batch-size 1152
  --log-interval 1
  --lr 1e-4
  --min-lr 6.0e-6
  --lr-warmup-iters 0
  --lr-decay-iters 320000
  --lr-decay-style cosine
  --weight-decay 0.1
  --train-iters 250
  --log-interval 1
  --eval-iters 0
  --eval-interval 1000
  --num-workers 4
  --split 949,50,1
  --weight-decay 0.1
  --adam-beta1 0.9
  --adam-beta2 0.95
  --clip-grad 1.0
  --profile
  --profile-step-start 40
  --profile-step-end 45
  --profile-ranks 0
)

