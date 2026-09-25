#!/usr/bin/env bash
# Launch a visible Chromium with a dedicated profile and a CDP debug port.
# Usage: launch.sh <profile-name> [url] [port]
set -euo pipefail
NAME="${1:?profile name, e.g. linkedin}"
URL="${2:-about:blank}"
PORT="${3:-9222}"
PROFILE="$HOME/.local/share/chromium-$NAME"
mkdir -p "$PROFILE"
if curl -s "http://127.0.0.1:$PORT/json/version" >/dev/null 2>&1; then
  echo "A browser already listens on :$PORT — reuse it (or pass another port)."; exit 0
fi
nohup chromium --user-data-dir="$PROFILE" --remote-debugging-port="$PORT" \
  --no-first-run --no-default-browser-check "$URL" >/tmp/chromium-$NAME.log 2>&1 &
for _ in $(seq 1 20); do
  sleep 0.5
  if curl -s "http://127.0.0.1:$PORT/json/version" >/dev/null 2>&1; then
    echo "Chromium up on :$PORT, profile $PROFILE"; exit 0
  fi
done
echo "Chromium did not expose :$PORT — see /tmp/chromium-$NAME.log"; exit 1
