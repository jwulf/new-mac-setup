# Local LLM Coding

llama.cpp gives the best performance with the lowest overhead.

[Qwen 3.6](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-MTP-GGUF) is a good model. Starting it with a 128k context window (`-c 131072`) on a 64GB Mac is useable.

For coding agent, little-coder is the best. It is an opinionated setup for Pi coding agent optimized for coding with small models locally.

## Alternatives evaluated 

**Models**: Gemma 4
**LLM server**: LMStudio, Ollama
**Coding agent**: Copilot, OOTB Pi, OpenCode
