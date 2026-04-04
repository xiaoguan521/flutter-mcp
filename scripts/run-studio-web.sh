#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MCP_UI_SERVER_URL="${MCP_UI_SERVER_URL:-http://127.0.0.1:8787}"

# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/env.macos.sh"

cd "${ROOT_DIR}/apps/flutter_mcp_studio"
flutter pub get
flutter run -d chrome --dart-define=MCP_UI_SERVER_URL="${MCP_UI_SERVER_URL}" "$@"
