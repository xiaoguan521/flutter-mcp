#!/usr/bin/env bash

set -euo pipefail

BREW_BIN="${BREW_BIN:-$(command -v brew || true)}"

if [[ -z "${BREW_BIN}" ]]; then
  echo "Homebrew is required on macOS. Install it first: https://brew.sh/" >&2
  exit 1
fi

BREW_PREFIX="$("${BREW_BIN}" --prefix)"
OPENJDK_17_HOME="${BREW_PREFIX}/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"

if [[ -d "${OPENJDK_17_HOME}" ]]; then
  export JAVA_HOME="${JAVA_HOME:-${OPENJDK_17_HOME}}"
  export PATH="${BREW_PREFIX}/opt/openjdk@17/bin:${PATH}"
fi

if command -v flutter >/dev/null 2>&1; then
  :
elif [[ -x "${BREW_PREFIX}/bin/flutter" ]]; then
  export PATH="${BREW_PREFIX}/bin:${PATH}"
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is not available in PATH. Install it with: brew install --cask flutter" >&2
  exit 1
fi

