# Copyright Lightning AI. Licensed under the Apache License 2.0, see LICENSE file.

"""Full definition of a GPT NeoX Language Model, all of it in this single file.

Based on the nanoGPT implementation: https://github.com/karpathy/nanoGPT and
https://github.com/EleutherAI/gpt-neox/tree/main/megatron/model.
"""

import math
from typing import Any, Optional, Tuple

import torch
import torch.nn as nn
from typing_extensions import Self

from lit_gpt.config import Config
from lit_gpt.model import Block, GPT


class GPTFSDP(GPT):
    def __init__(self, config: Config) -> None:
        super().__init__(config)
        print ("##### Using gpt_fsdp #####")
        # Overload the transformer
        self.transformer = nn.ModuleDict(
            dict(
                wte=nn.Embedding(config.padded_vocab_size, config.n_embd),
                h=self.construct_blocks(config),
                ln_f=config.norm_class(config.n_embd, eps=config.norm_eps),
            )
        )
    
    def construct_blocks(self, config):
        config.num_blocks_to_combine = int(config.num_blocks_to_combine)
        # Don't use multiBlocks
        if config.num_blocks_to_combine <= 1:
            return nn.ModuleList(Block(config) for _ in range(config.n_layer))

        # using multiblocks
        num_multi_blocks = config.n_layer // config.num_blocks_to_combine
        num_last_blocks = config.n_layer - num_multi_blocks * config.num_blocks_to_combine
        
        print (f"##### num_multi_blocks: {num_multi_blocks},  num_blocks: {num_last_blocks} #####")

        h = nn.ModuleList(MultiBlock(config, config.num_blocks_to_combine) for _ in range(num_multi_blocks))
        if num_last_blocks > 0:
            h.append(MultiBlock(config, num_last_blocks))
        return h

class MultiBlock(nn.Module):
    def __init__(self, config, num_blocks_to_combine):
        super().__init__()
        self.blocks = nn.ModuleList(Block(config) for _ in range(num_blocks_to_combine))
   
    def forward(
        self,
        x,
        rope,
        max_seq_length,
        mask = None,
        input_pos = None,
        kv_cache = None,
    ):
        for block in self.blocks:
            x, _ = block(x, rope, max_seq_length)
        return x, kv_cache
