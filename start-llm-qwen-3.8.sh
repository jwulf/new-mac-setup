#!/usr/bin/env bash
# Start Qwen3.8 on llama-server with KV-cache save-on-exit / restore-on-start.
#
# The server's KV cache is wiped on every (re)start, forcing a full cold prefill
# of the whole conversation before the next token — which can blow past a client's
# stream-idle timeout and wedge an in-progress agent session. This wrapper saves
# slot 0's KV cache when you stop it (Ctrl-C) and OPTIONALLY restores it on the
# next start, so resuming a session skips the cold prefill.
set -euo pipefail
set -m   # each background job gets its own process group, so a terminal Ctrl-C
         # hits THIS wrapper (→ save first) and not llama-server directly.

# ── config ───────────────────────────────────────────────────────────────────
#MODEL="$HOME/.cache/huggingface/hub/models--unsloth--Qwen3.8-27B-GGUF/snapshots/f1bfb127c64f7072bdd2cad55f258b9c8b2910fe/Qwen3.8-27B-UD-Q5_K_XL.gguf"
MODEL="$HOME/models/Qwen3.8-27B-UD-Q4_K_XL.gguf"
SLOT_DIR="$HOME/.cache/llama-slots"
SLOT_FILE="qwen38-slot0.bin"          # saved under $SLOT_DIR (name only, no path)
HOST_LOCAL="127.0.0.1"
PORT="${1:-8888}"                     # standalone default; llama-swap passes a port arg
BASE="http://$HOST_LOCAL:$PORT"
mkdir -p "$SLOT_DIR"

# ── launch the server (backgrounded so we can call its endpoints on exit) ──────
llama-server -m "$MODEL" \
  --spec-type draft-dflash \
  --spec-draft-n-max 3 \
  --cache-type-k q8_0 \
  --cache-type-v q8_0 \
  --flash-attn on \
  --context-shift --keep 4 \
  --slot-save-path "$SLOT_DIR" \
  --chat-template-kwargs '{"reasoning_effort": "medium"}' \
  --host 0.0.0.0 --port "$PORT" \
  -ngl 999 \
  -c 32768 \
  -np 1 \
  --jinja \
  --temp 0.7 --top-p 0.80 --top-k 20 --min-p 0.0 \
  --presence-penalty 1.5 --repeat-penalty 1.0 &
SERVER_PID=$!

# ── save-on-exit: persist slot 0 BEFORE stopping the server ────────────────────
save_slot() {
  # Only meaningful while the server is still alive to answer the endpoint.
  if kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "[wrapper] saving slot 0 KV cache -> $SLOT_DIR/$SLOT_FILE ..."
    if curl -fsS -m 180 "$BASE/slots/0?action=save" \
         -H 'Content-Type: application/json' \
         -d "{\"filename\":\"$SLOT_FILE\"}" >/dev/null 2>&1; then
      echo "[wrapper] slot saved."
    else
      echo "[wrapper] slot save failed (slot busy, empty, or server down) — leaving previous save intact."
    fi
  fi
}

shutdown() {
  trap - INT TERM        # avoid re-entrancy
  echo
  save_slot
  echo "[wrapper] stopping llama-server (pgid $SERVER_PID) ..."
  kill -TERM -"$SERVER_PID" 2>/dev/null || kill -TERM "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
  exit 0
}
trap shutdown INT TERM

# ── wait for the server to become healthy ──────────────────────────────────────
printf "[wrapper] waiting for server health"
until curl -fsS -m 2 "$BASE/health" 2>/dev/null | grep -q '"ok"'; do
  printf "."
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo; echo "[wrapper] server exited during startup — aborting."; exit 1
  fi
  sleep 2
done
echo " ok"

# ── restore-on-start: ASK first ────────────────────────────────────────────────
if [ -f "$SLOT_DIR/$SLOT_FILE" ]; then
  saved_when="$(date -r "$SLOT_DIR/$SLOT_FILE" '+%Y-%m-%d %H:%M' 2>/dev/null || echo unknown)"
  if [ -t 0 ]; then
    printf "[wrapper] Restore previous KV cache (%s, saved %s)? [y/N] " "$SLOT_FILE" "$saved_when"
    read -r ans || ans="n"
  elif [ "${LLAMA_SLOT_AUTORESTORE:-0}" = "1" ]; then
    ans="y"
    echo "[wrapper] non-interactive shell — auto-restoring (LLAMA_SLOT_AUTORESTORE=1)."
  else
    ans="n"
    echo "[wrapper] non-interactive shell — skipping restore (saved cache left in place)."
  fi
  case "$ans" in
    [yY]*)
      echo "[wrapper] restoring slot 0 from $SLOT_FILE ..."
      if curl -fsS -m 300 "$BASE/slots/0?action=restore" \
           -H 'Content-Type: application/json' \
           -d "{\"filename\":\"$SLOT_FILE\"}" >/dev/null 2>&1; then
        echo "[wrapper] restore OK — resuming a matching session skips the cold prefill."
        echo "[wrapper] note: an UNRELATED session just re-prefills past the shared prefix (no bleed)."
      else
        echo "[wrapper] restore FAILED — likely a model/params/build mismatch. Continuing with a cold cache."
      fi
      ;;
    *) echo "[wrapper] skipping restore (cold cache)." ;;
  esac
else
  echo "[wrapper] no saved cache at $SLOT_DIR/$SLOT_FILE yet — nothing to restore."
fi

echo "[wrapper] server ready on $BASE (Ctrl-C to save-and-stop)."
wait "$SERVER_PID"
