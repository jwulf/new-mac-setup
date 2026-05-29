#!/bin/bash

llama-server -hf unsloth/gemma-4-26B-A4B-it-GGUF:UD-Q4_K_M --port 8888 -ngl 99 -c 32768 -np 1 --jinja -ctk q8_0 -ctv q8_0
