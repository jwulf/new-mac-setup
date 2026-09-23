#!/usr/bin/env bash
# Serve Qwen3.8-Flash-Next (Qwen4-preview arch) on Apple Silicon via DwarfStar
# (antirez/ds4) — a small native Metal engine, NOT llama.cpp. It is therefore a
# SEPARATE server from llama-router.sh (which is GGUF/llama.cpp only): this model
# uses the `qwen4exp` graph that upstream llama.cpp does not implement.
#
# Q2 pack: 41.73 GiB resident weights + a 95 GiB BF16 n-gram table that stays on
# disk and is read per-token, so keep it on a fast local SSD. Fits a 64 GB Mac
# with a small context; --mtp adds the model's built-in MTP speculative head
# (the ~50-70 t/s fast path).
#
# Memory note: on 64 GB, stop other large resident models first (e.g. the
# llama-router / start-llm-qwen scripts) — 41.73 GiB + context + page cache
# leaves little headroom.
#
# Overrides:
#   DS4_DIR=~/workspace/ds4     location of the built ds4 checkout
#   QFN_PORT=8100               HTTP port (OpenAI-compatible)
#   QFN_HOST=127.0.0.1          bind address (use :: / 0.0.0.0 for LAN)
#   QFN_CTX=8192                context tokens
#   QFN_MTP=1                   1=enable --mtp speculative decoding, 0=off
set -euo pipefail

DS4_DIR="${DS4_DIR:-$HOME/workspace/ds4}"
MODEL="$DS4_DIR/gguf/Qwen3.8-Flash-Next-Q2.gguf"
PORT="${QFN_PORT:-8100}"
HOST="${QFN_HOST:-0.0.0.0}"
CTX="${QFN_CTX:-65535}"
MTP="${QFN_MTP:-1}"

if [ ! -x "$DS4_DIR/ds4-server" ]; then
  echo "[qfn] ds4-server not built at $DS4_DIR — run 'make' in the ds4 checkout." >&2
  exit 1
fi
if [ ! -f "$MODEL" ]; then
  echo "[qfn] model not found: $MODEL" >&2
  echo "[qfn] download it (147 GB) with:  (cd \"$DS4_DIR\" && ./download_model.sh qwen38-q2)" >&2
  exit 1
fi

MTP_ARGS=()
[ "$MTP" = "1" ] && MTP_ARGS=(--mtp)

echo "[qfn] engine:  DwarfStar (antirez/ds4), Metal"
echo "[qfn] model:   $MODEL"
echo "[qfn] serving: http://$HOST:$PORT/v1   (ctx=$CTX, mtp=$MTP)"
echo "[qfn] models:  qwen3.8-flash-next (thinking), qwen3.8-flash-next-chat (no-think), -reasoner"
echo "[qfn] NOTE: 'qwen3.8-flash-next' defaults to HIGH-effort thinking. If your"
echo "[qfn]       harness caps output tokens, the <think> trace eats the whole"
echo "[qfn]       budget and returns no answer ('Output token limit reached')."
echo "[qfn]       Use model id 'qwen3.8-flash-next-chat' for a coding harness, or"
echo "[qfn]       raise the client's max output tokens to ~16k-32k for thinking."

cd "$DS4_DIR"
exec ./ds4-server \
  -m "$MODEL" \
  --ctx "$CTX" \
  --prefill-chunk 1024 \
  "${MTP_ARGS[@]}" \
  --host "$HOST" --port "$PORT"
