#!/usr/bin/env bash
# Start Qwen3.8-Flash-Next 125B UltraLite (37 GiB GGUF) on this Mac.
#
# IMPORTANT: This model uses 0xKitkat's custom "padded PLE" tensor layout and can
# ONLY be loaded by the PATCHED, PINNED Unsloth llama.cpp build in
# ~/workspace/qwen38-flash-next/llama.cpp (branch qwen4exp/qwen3.8-flash-next @
# 250b61446 + patches/qwen4exp-under40.patch). The Homebrew `llama-server` will
# NOT load it. See build-manifest.txt in the model dir.
#
# The upstream author validated this CPU-only; Metal works here (~16 tok/s) and
# is used by default (-ngl 999). For pure CPU, run: BACKEND=cpu ./start-...sh
#
# OUTPUT-QUALITY CAVEAT: this is an experimental 1.8-bits-per-weight compression.
# The model card only claims it "generated a deterministic first token and exited
# with code 0" — NOT coherent chat. In practice the degraded output layer emits
# its end-of-generation token (id 248046) prematurely, so replies are often empty
# or partly garbled. Mitigations baked in below:
#   --reasoning-budget 0   skip the (very unstable) <think> block and answer directly
#   --logit-bias 248046-5  suppress the premature end-of-generation token
#   tightened sampling      (min-p 0.05, top-p 0.9) to cut low-probability junk
# These make it usable for short factual prompts but it remains unreliable. Do NOT
# add repeat/presence/DRY penalties: at this quant they push it into pure gibberish.
set -euo pipefail

# ── config ────────────────────────────────────────────────────────────────────
MODEL_DIR="$HOME/workspace/qwen38-flash-next"
BIN_DIR="$MODEL_DIR/llama.cpp/build/bin"
SERVER="$BIN_DIR/llama-server"
# llama.cpp auto-loads all shards given the first one:
MODEL="$MODEL_DIR/Qwen3.8-Flash-Next-125B-UltraLite-37GiB-00001-of-00003.gguf"

BACKEND="${BACKEND:-metal}"     # metal | cpu
PORT="${PORT:-8890}"
CTX="${CTX:-8192}"              # 37 GiB weights + KV must fit in 64 GiB unified mem

if [ ! -x "$SERVER" ]; then
  echo "ERROR: patched llama-server not found at $SERVER" >&2
  echo "Build it: see README in $MODEL_DIR" >&2
  exit 1
fi
if [ ! -f "$MODEL" ]; then
  echo "ERROR: model shard not found: $MODEL" >&2
  exit 1
fi

# GPU offload layers: 999 = all on Metal, 0 = pure CPU
if [ "$BACKEND" = "cpu" ]; then NGL=0; else NGL=999; fi

# On Metal, allow the GPU to wire enough unified memory for the 37 GiB weights.
# macOS default caps GPU-wired memory at ~0.75x RAM (~48 GiB on 64 GiB); bump it
# so weights + KV cache have headroom. (No-op / harmless if already high enough.)
if [ "$BACKEND" != "cpu" ]; then
  sudo sysctl -w iogpu.wired_limit_mb=57344 >/dev/null 2>&1 || \
    echo "[note] could not raise iogpu.wired_limit_mb (needs sudo); default limit applies."
fi

echo "[start] backend=$BACKEND  ngl=$NGL  ctx=$CTX  port=$PORT"
echo "[start] model=$MODEL"

exec "$SERVER" \
  -m "$MODEL" \
  --host 0.0.0.0 --port "$PORT" \
  -ngl "$NGL" \
  -c "$CTX" \
  -np 1 \
  --jinja \
  --reasoning-budget 0 \
  --logit-bias 248046-5 \
  --temp 0.6 --top-p 0.9 --top-k 20 --min-p 0.05
