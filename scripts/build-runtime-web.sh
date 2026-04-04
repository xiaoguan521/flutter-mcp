#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCP_UI_SERVER_URL="${MCP_UI_SERVER_URL:-http://127.0.0.1:8787}"
MCP_UI_PAGE_SLUG="${MCP_UI_PAGE_SLUG:-}"
MCP_UI_PAGE_VERSION="${MCP_UI_PAGE_VERSION:-}"
MCP_UI_PAGE_URI="${MCP_UI_PAGE_URI:-}"

# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/env.macos.sh"

cd "${ROOT_DIR}/apps/flutter_mcp_runtime"
flutter pub get
flutter build web \
  --no-tree-shake-icons \
  --dart-define=MCP_UI_SERVER_URL="${MCP_UI_SERVER_URL}" \
  --dart-define=MCP_UI_PAGE_SLUG="${MCP_UI_PAGE_SLUG}" \
  --dart-define=MCP_UI_PAGE_VERSION="${MCP_UI_PAGE_VERSION}" \
  --dart-define=MCP_UI_PAGE_URI="${MCP_UI_PAGE_URI}" \
  "$@"
