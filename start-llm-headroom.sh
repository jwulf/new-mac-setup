#!/usr/bin/env bash
# Start the Headroom compression proxy IN FRONT OF the llama.cpp router.
#
# Headroom (https://github.com/headroomlabs-ai/headroom) compresses the prompt
# tokens a client sends — tool outputs, logs, RAG chunks, files, conversation
# history — before they reach the model. On a local server tokens are free, but
# the Mac still pays for every prompt token during PREFILL, so fewer input
# tokens = less prompt-processing work and lower memory pressure.
#
# TOPOLOGY
#   client ──/v1/chat/completions──▶ Headroom (:8787) ──▶ llama.cpp router (:8888)
#
# The proxy only understands OpenAI-style /v1/* paths. It does NOT forward
# llama.cpp's NATIVE model-management endpoints (/models, /models/load,
# /models/sse) that the pi-llama-cpp extension needs to browse and switch
# models. So:
#
#   • Generic OpenAI-compatible clients  ->  point them at THIS proxy (:8787).
#   • pi / pi-llama-cpp model management  ->  keep it pointed straight at the
#     router (:8888). Do NOT route pi's model browsing through Headroom.
#
# Start the router first (start-llm-router.sh); this script does not manage it.
#
# Override with:
#   HEADROOM_HOST=127.0.0.1     restrict to loopback (default binds 0.0.0.0 for LAN)
#   HEADROOM_PORT=9787          change the proxy port
#   HEADROOM_UPSTREAM=host:port point at a router elsewhere (default 127.0.0.1:8888)
#   HEADROOM_NO_OPTIMIZE=1      passthrough mode (baseline run — no compression)
#   HEADROOM_BEACON=on          re-enable the anonymous usage beacon (off here)
set -euo pipefail

if ! command -v headroom >/dev/null 2>&1; then
  echo "[headroom] 'headroom' not found on PATH." >&2
  echo "[headroom] install it with:  uv tool install --python 3.13 \"headroom-ai[all]\"" >&2
  echo "[headroom]              or:  pip install \"headroom-ai[all]\"" >&2
  exit 127
fi

# Bind 0.0.0.0 by default so LAN clients can reach the proxy. Headroom binds
# loopback by default, unlike the router which binds :: — keep them consistent
# by exposing the proxy on the LAN too.
HOST="${HEADROOM_HOST:-0.0.0.0}"
PORT="${HEADROOM_PORT:-8787}"
UPSTREAM="${HEADROOM_UPSTREAM:-127.0.0.1:8888}"

LAN_IP=""
for i in $(ifconfig -l 2>/dev/null); do
  ip="$(ipconfig getifaddr "$i" 2>/dev/null || true)"
  [ -n "$ip" ] && { LAN_IP="$ip"; break; }
done
HOSTNAME_LOCAL="$(scutil --get LocalHostName 2>/dev/null || hostname)"

echo "[headroom] proxy:      $HOST:$PORT  ->  upstream router http://$UPSTREAM"
echo "[headroom] local:      http://127.0.0.1:$PORT/v1"
[ -n "$LAN_IP" ] && echo "[headroom] LAN (IP):   http://$LAN_IP:$PORT/v1"
echo "[headroom] LAN (host): http://$HOSTNAME_LOCAL.local:$PORT/v1"
echo "[headroom] clients:    export OPENAI_BASE_URL=<one of the above>  OPENAI_API_KEY=local"
echo "[headroom] NOTE:       pi model management must stay on the router (http://$UPSTREAM), not this proxy."

ARGS=(
  --host "$HOST"
  --port "$PORT"
  --openai-api-url "http://$UPSTREAM"
  --offline                       # no anonymous beacon / update checks
)

# Baseline vs optimized: HEADROOM_NO_OPTIMIZE=1 forwards traffic untouched so
# you can measure prefill savings against an optimized run in the dashboard.
if [ "${HEADROOM_NO_OPTIMIZE:-0}" = "1" ]; then
  echo "[headroom] mode:       PASSTHROUGH (--no-optimize) — baseline, no compression"
  ARGS+=(--no-optimize)
else
  echo "[headroom] mode:       optimizing (compressing prompt tokens)"
fi

# Opt back into the beacon only if explicitly requested.
if [ "${HEADROOM_BEACON:-off}" = "on" ]; then
  # Drop --offline so the beacon/update checks are allowed again.
  NEW_ARGS=()
  for a in "${ARGS[@]}"; do [ "$a" = "--offline" ] || NEW_ARGS+=("$a"); done
  ARGS=("${NEW_ARGS[@]}")
  echo "[headroom] beacon:     ENABLED (anonymous usage stats)"
fi

exec headroom proxy "${ARGS[@]}"
