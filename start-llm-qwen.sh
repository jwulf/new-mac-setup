#!/bin/bash

llama-server -hf unsloth/Qwen3.6-35B-A3B-GGUF:UD-Q4_K_XL \
  --host 0.0.0.0 \
  --port 8888 \
  -ngl 99 \
  -c 131072 \
  -np 1 \
  --jinja \
  -ctk q8_0 \
  -ctv q8_0 \
  --temp 0.6 \
  --top-p 0.95 \
  --top-k 20 \
  --min-p 0.0 \
  -fa on\
  --presence-penalty 0.0 \
  --repeat-penalty 1.0 
