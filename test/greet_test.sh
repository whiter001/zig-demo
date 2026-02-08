#!/usr/bin/env bash
set -euo pipefail

# Robust test: avoid FIFO race conditions by writing framed requests to a temp file
# and piping it into the server; capture response and assert it contains expected greeting.

OUTDIR="$(pwd)/test-temp-$$"
mkdir -p "$OUTDIR"
REQ_FILE="$OUTDIR/req.bin"
RESP_FILE="$OUTDIR/resp.bin"

payload1='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}'
payload2='{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"tool":"greet","input":{"name":"Alice"}}}'

printf 'Content-Length: %d\r\n\r\n%sContent-Length: %d\r\n\r\n%s' "$(printf '%s' "$payload1" | wc -c)" "$payload1" "$(printf '%s' "$payload2" | wc -c)" "$payload2" > "$REQ_FILE"

# Start server reading from request file and writing to response file
cat "$REQ_FILE" | ./zig-out/bin/zig-demo-mcp > "$RESP_FILE" &
SERVER_PID=$!

# Ensure cleanup
cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  rm -rf "$OUTDIR"
}
trap cleanup EXIT

# Wait for server to exit or timeout (up to ~5s)
for i in {1..50}; do
  if ps -p "$SERVER_PID" >/dev/null 2>&1; then
    sleep 0.1
  else
    break
  fi
done

# If still running, try gentle termination
if ps -p "$SERVER_PID" >/dev/null 2>&1; then
  kill "$SERVER_PID" || true
  sleep 0.2
fi

# Inspect response for the greet result
if grep -q "Hello, Alice" "$RESP_FILE"; then
  echo "greet test passed"
  exit 0
else
  echo "greet test failed; response was:" >&2
  sed -n '1,200p' "$RESP_FILE" >&2 || true
  exit 1
fi
