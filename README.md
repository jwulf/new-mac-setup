## Setting up a new Mac

0. Install [Karabiner and set up Halmak layout](https://github.com/jwulf/joshs-custom-keyboard-layout#karabiner-setup)
1. Install [nvm](https://github.com/nvm-sh/nvm/blob/master/README.md)
2. Install Node 24: `nvm install 24`
3. Install TypeScript: `npm i -g typescript`
4. Install brew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
5. Install [zed](https://zed.dev/)
6. Install Haskell via GHCUp: `curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh`
7. Install GitHub CLI: `brew install gh`
8. Install GitHub Copilot: `npm i -g @github/copilot`
9. Install Cocktail: `npm i -g @camunda8/cli@alpha`
10. Install Pi: `npm install -g --ignore-scripts @earendil-works/pi-coding-agent`
11. Install Pi LSP: `pi install npm:pi-lsp-extension`
12. Install Pi GitHub: `pi install npm:pi-gh-cli`
13. Install Pi llama.cpp: `pi install npm:pi-llama-cpp`
14. Install Pi Context-Mode: `npm install -g context-mode && pi install npm:context-mode`
15. Install Pi Memory: `pi install npm:@pi-unipi/memory`
16. Install Zed Biome: "Open zed: extensions and search for Biome"
17. Install Zed Haskell: "Open zed: extensions and search for Haskell"
18. Install llama.cpp: `brew install llama.cpp`
19. Get the Gemma 4 model (from [here](https://ai.plainenglish.io/i-built-a-gemma-4-ai-agent-it-kept-looping-until-i-fixed-this-1ef53f50158c)): `llama-server -hf unsloth/gemma-4-26B-A4B-it-GGUF:UD-Q4_K_M --port 1234 -ngl 99 -c 32768 -np 1 --jinja -ctk q8_0 -ctv q8_0`
20. Configure pi for llama.cpp — edit `~/.pi/agent/settings.json` add: `"llamaServerUrl": "http://127.0.0.1:1234"`
21. [Generate SSH Key for GitHub](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
22. Install OpenJDK: `brew install openjdk`
23. Install [GhostTTY](https://ghostty.org/download)
24. Install Orbstack: `brew install orbstack`
25. Install uv (Python): `curl -LsSf https://astral.sh/uv/install.sh | sh`
26. Install asdf: `brew install asdf`
27. Install asdf .NET plugin: `asdf plugin add dotnet`
28. Install .NET 8: `asdf install dotnet 8.0.421` 
29. Install .NET 9: `asdf install dotnet 9.0.314`
30: Install .NET 10: `asdf install dotnet latest`
31. Install Clojure: `brew install clojure/tools/clojure`
21. Install Zed Clojure: "Open zed: extensions and search for Clojure"
22. Install Little Coder: `npm i -g little-coder`
23. Set nano as git editor: `git config --global core.editor "nano"`
24. Set up git identity: `git config --global --edit`
25. Install bun: `npm i -g bun`
26. Install qmd for Pi memory search: `npm i -g @tobi/qmd`
28. Install MacMLX, and download Qwen model
29. Install omlx: `brew install omlx --with-grammar`
30. Model for omlx config in ~/.config/little-coder/models.json:

```json
{
  "providers": {
    "omlx": {
      "api": "openai-completions",
      "baseUrl": "http://127.0.0.1:8000/v1",
      "apiKey": "IGNORED",
      "models": [
        {
          "id": "Qwen3-32B-4bit",
          "name": "Qwen3.6-35B-A3B (local omlx, 150K)",
          "reasoning": true,
          "input": ["text"],
          "contextWindow": 150000,
          "maxTokens": 4096,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        }
      ]
    }
  }
}
```

## Local multi-model LLM (llama.cpp router)

Serve several local GGUF models behind one OpenAI-compatible endpoint using
llama.cpp's built-in **router mode**. This exposes llama.cpp's native model
management (`/models`, `/models/load`, `/models/sse`) that the `pi-llama-cpp`
extension uses to browse/load/switch models — plain `llama-swap` does **not**
implement those endpoints (pi gets HTTP 404), so use the router for pi.

```bash
./start-llm-router.sh          # binds :: (IPv4+IPv6) on :8888
```

- Models are defined in `llama-router.ini` (currently `qwen3.8` and
  `minicpm5-2b`); the `[*]` section holds shared defaults. Local models use
  `model = /path/to.gguf`, remote ones use `hf = user/repo:quant`.
- The router also auto-lists any other GGUFs in your Hugging Face cache.
- Env overrides: `LLAMA_ROUTER_PORT`, `LLAMA_ROUTER_HOST`,
  `LLAMA_ROUTER_MODELS_MAX` (default `2` = both resident; `1` = hot-swap).
- Clients pick the model via the OpenAI `model` field, e.g. `qwen3.8` or
  `minicpm5-2b`. pi: set `llamaServerUrl` to `http://<host>:8888`; little-coder:
  set `baseUrl` to `http://<host>:8888/v1`.
- LAN clients that resolve `<host>.local` to an IPv6 link-local address are
  covered by the dual-stack (`::`) bind; if a client still fails, use the IPv4
  literal (e.g. `http://192.168.0.141:8888`).

`start-llm-qwen-3.8.sh` remains a standalone single-model launcher with KV-cache
save/restore (takes an optional port arg); the router does not use it.
