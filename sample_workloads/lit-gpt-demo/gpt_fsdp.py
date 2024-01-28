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
        super().__init__()
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
        # Don't use multiBlocks
        if config.num_blocks_to_combine <= 1:
            return nn.ModuleList(Block(config) for _ in range(config.n_layer))

        # using multiblocks
        num_multi_blocks = config.n_layer // config.num_blocks_to_combine
        num_blocks = config.n_layer - num_multi_blocks * config.num_blocks_to_combine
        
        print (f"##### num_multi_blocks: {num_multi_blocks},  num_blocks: {num_blocks} #####")

        h = nn.ModuleList(MultiBlock(config) for _ in range(num_multi_blocks))
        h.extend(Block(config) for _ in range(num_blocks))
        return h

class MultiBlock(nn.Module):
    def __init__(self, config):
        super().__init__()
        self.num_blocks_to_combine = config.num_blocks_to_combine
        self.blocks = [nn.ModuleList(Block(config) for _ in range(self.num_blocks_to_combine))]
    
    def forward(
        self,
        x: torch.Tensor,
        cos: torch.Tensor,
        sin: torch.Tensor,
        mask: Optional[torch.Tensor] = None,
        input_pos: Optional[torch.Tensor] = None,
    ):
        for block in self.blocks:
            x = block(x, cos, sin, mask, input_pos)
        return x
