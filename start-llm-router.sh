#!/usr/bin/env bash
# Start llama.cpp in ROUTER mode: one OpenAI-compatible endpoint that hosts
# multiple models and exposes native model management (/models, /models/load,
# /models/sse) — the endpoints the pi-llama-cpp extension uses to browse, load,
# and switch models. Model definitions live in llama-router.ini.
#
# Binds 0.0.0.0 by default so it's reachable across the LAN. Override with:
#   LLAMA_ROUTER_HOST=127.0.0.1   restrict to loopback
#   LLAMA_ROUTER_PORT=9000        change port
#   LLAMA_ROUTER_MODELS_MAX=1     keep only one model resident at a time
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRESET="$DIR/llama-router.ini"
# Bind :: for a dual-stack listener (IPv4 + IPv6), so LAN clients reach it over
# either family (e.g. pi resolving <host>.local to an IPv6 link-local address).
HOST="${LLAMA_ROUTER_HOST:-::}"
PORT="${LLAMA_ROUTER_PORT:-8888}"
# Both models resident at once (MiniCPM is tiny); set to 1 to hot-swap instead.
MODELS_MAX="${LLAMA_ROUTER_MODELS_MAX:-2}"

LAN_IP=""
for i in $(ifconfig -l 2>/dev/null); do
  ip="$(ipconfig getifaddr "$i" 2>/dev/null || true)"
  [ -n "$ip" ] && { LAN_IP="$ip"; break; }
done
HOSTNAME_LOCAL="$(scutil --get LocalHostName 2>/dev/null || hostname)"

echo "[router] binding:     $HOST:$PORT   (models-max=$MODELS_MAX)"
echo "[router] local:       http://127.0.0.1:$PORT/v1"
[ -n "$LAN_IP" ] && echo "[router] LAN (IP):    http://$LAN_IP:$PORT/v1"
echo "[router] LAN (host):  http://$HOSTNAME_LOCAL.local:$PORT/v1"
echo "[router] models:      qwen3.8, qwen3.8-neo-coder, qwen3-next-80b, qwen3-coder-30b, deepseek-r1, minicpm5-2b   (preset: $PRESET)"

exec llama-server \
  --models-preset "$PRESET" \
  --models-max "$MODELS_MAX" \
  --host "$HOST" --port "$PORT"
