## Setting up a new Mac

0. Install [Karabiner and set up Halmak layout](https://github.com/jwulf/joshs-custom-keyboard-layout#karabiner-setup)
1. Install [nvm](https://github.com/nvm-sh/nvm/blob/master/README.md)
2. Install TypeScript: `npm i -g typescript`
3. Install brew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
4. Install [zed](https://zed.dev/)
5. Install Haskell via GHCUp: `curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh`
6. Install GitHub CLI: `brew install gh`
7. Install GitHub Copilot: `npm i -g @github/copilot`
8. Install Cocktail: `npm i -g @camunda8/cli@alpha`
9. Install Pi: `npm install -g --ignore-scripts @earendil-works/pi-coding-agent`
10. Install Pi LSP: `pi install npm:pi-lsp-extension`
11. Install Pi llama.cpp: `pi install npm:pi-llama-cpp`
12. Install Zed Biome: "Open zed: extensions and search for Biome"
13. Install Zed Haskell: "Open zed: extensions and search for Haskell"
14. Install llama.cpp: `brew install llama.cpp`
15. Get the Gemma 4 model (from [here](https://ai.plainenglish.io/i-built-a-gemma-4-ai-agent-it-kept-looping-until-i-fixed-this-1ef53f50158c)): `llama-server -hf unsloth/gemma-4-26B-A4B-it-GGUF:UD-Q4_K_M --port 1234 -ngl 99 -c 32768 -np 1 --jinja -ctk q8_0 -ctv q8_0`
16. Configure pi for llama.cpp — edit `~/.pi/agent/settings.json` add: `"llamaServerUrl": "http://127.0.0.1:1234"`
17. [Generate SSH Key for GitHub](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)
