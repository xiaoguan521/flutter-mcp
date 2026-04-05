#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCP_UI_SERVER_URL="${MCP_UI_SERVER_URL:-http://127.0.0.1:8787}"
MCP_UI_APP_SLUG="${MCP_UI_APP_SLUG:-}"
MCP_UI_APP_VERSION="${MCP_UI_APP_VERSION:-}"
MCP_UI_APP_URI="${MCP_UI_APP_URI:-}"
MCP_UI_APP_ROUTE="${MCP_UI_APP_ROUTE:-}"
MCP_UI_PAGE_SLUG="${MCP_UI_PAGE_SLUG:-}"
MCP_UI_PAGE_VERSION="${MCP_UI_PAGE_VERSION:-}"
MCP_UI_PAGE_URI="${MCP_UI_PAGE_URI:-}"
RUNTIME_WEB_HOSTNAME="${RUNTIME_WEB_HOSTNAME:-0.0.0.0}"
RUNTIME_WEB_PORT="${RUNTIME_WEB_PORT:-18080}"

# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/env.macos.sh"

cd "${ROOT_DIR}/apps/flutter_mcp_runtime"
flutter pub get
flutter run -d web-server \
  --web-hostname="${RUNTIME_WEB_HOSTNAME}" \
  --web-port="${RUNTIME_WEB_PORT}" \
  --dart-define=MCP_UI_SERVER_URL="${MCP_UI_SERVER_URL}" \
  --dart-define=MCP_UI_APP_SLUG="${MCP_UI_APP_SLUG}" \
  --dart-define=MCP_UI_APP_VERSION="${MCP_UI_APP_VERSION}" \
  --dart-define=MCP_UI_APP_URI="${MCP_UI_APP_URI}" \
  --dart-define=MCP_UI_APP_ROUTE="${MCP_UI_APP_ROUTE}" \
  --dart-define=MCP_UI_PAGE_SLUG="${MCP_UI_PAGE_SLUG}" \
  --dart-define=MCP_UI_PAGE_VERSION="${MCP_UI_PAGE_VERSION}" \
  --dart-define=MCP_UI_PAGE_URI="${MCP_UI_PAGE_URI}" \
  "$@"
