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
