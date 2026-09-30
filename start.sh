#!/usr/bin/env bash
# Bootstrap the local venv (if needed) and start the UniFi MCP server.
# Usage:
#   ./start.sh           # uses MCP_SERVER_TRANSPORT from .env (stdio by default)
#   ./start.sh http      # streamable HTTP on 127.0.0.1:3000 for Inspector / gateways
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Missing .env. Copy .env.example and set UNIFI_API_KEY plus UNIFI_LOCAL_HOST."
  exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "uv is required. Install it with: brew install uv"
  exit 1
fi

if [[ ! -x .venv/bin/unifi-mcp-server ]]; then
  echo "Creating .venv and installing the project..."
  uv venv
  uv pip install -e .
fi

mode="${1:-}"
if [[ "$mode" == "http" ]]; then
  export MCP_SERVER_TRANSPORT=streamable_http
  export MCP_SERVER_HOST="${MCP_SERVER_HOST:-127.0.0.1}"
  export MCP_SERVER_PORT="${MCP_SERVER_PORT:-3000}"
  if [[ -z "${MCP_AUTH_TOKEN:-}" ]]; then
    MCP_AUTH_TOKEN="$(openssl rand -hex 32)"
    export MCP_AUTH_TOKEN
    echo "Generated MCP_AUTH_TOKEN for this run."
    echo "Clients send: Authorization: Bearer $MCP_AUTH_TOKEN"
    echo "URL: http://${MCP_SERVER_HOST}:${MCP_SERVER_PORT}/mcp"
  fi
else
  echo "Starting in stdio mode (what Cursor uses)."
  echo "If you want a local HTTP endpoint instead, run: ./start.sh http"
fi

exec .venv/bin/unifi-mcp-server
