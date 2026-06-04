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

# Start the agentmemory engine in the background (idempotent — skip if
# already responding on port 3111)
if curl -sf http://localhost:3111/ -o /dev/null 2>/dev/null; then
  echo "[session-start] Engine already running at http://localhost:3111"
else
  echo "[session-start] Starting agentmemory engine..."
  export PATH="$HOME/.local/bin:$PATH"
  nohup node "$CLAUDE_PROJECT_DIR/dist/cli.mjs" --no-engine=false \
    > /tmp/agentmemory.log 2>&1 &
  # Wait up to 20s for the engine to be ready
  for i in $(seq 1 40); do
    if curl -sf http://localhost:3111/ -o /dev/null 2>/dev/null; then
      echo "[session-start] Engine ready at http://localhost:3111"
      break
    fi
    sleep 0.5
  done
fi

echo "[session-start] Done."
