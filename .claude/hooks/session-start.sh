#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Install npm dependencies
echo "[session-start] Installing npm dependencies..."
npm install

# Download iii engine binary if not present (pinned to v0.11.2 — last
# version compatible with agentmemory's iii-exec worker model)
III_VERSION="0.11.2"
III_BIN="$HOME/.local/bin/iii"
if [ ! -f "$III_BIN" ]; then
  echo "[session-start] Downloading iii engine v${III_VERSION}..."
  mkdir -p "$HOME/.local/bin"
  curl -fsSL \
    "https://github.com/iii-hq/iii/releases/download/iii/v${III_VERSION}/iii-x86_64-unknown-linux-gnu.tar.gz" \
    | tar -xz -C "$HOME/.local/bin"
  chmod +x "$III_BIN"
  echo "[session-start] iii engine installed at $III_BIN"
else
  echo "[session-start] iii engine already present at $III_BIN"
fi

# Persist PATH so all session commands find iii
echo "export PATH=\"$HOME/.local/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"

# Build the project (produces dist/ needed by node dist/cli.mjs)
echo "[session-start] Building project..."
npm run build

echo "[session-start] Done. Start the engine with: node dist/cli.mjs"
