#!/usr/bin/env bash

set -euo pipefail

# If not running under bash (e.g. invoked via sh -c "..."), re-exec under bash reading stdin.
if [ -z "${BASH_VERSION-}" ]; then
  if command -v bash >/dev/null 2>&1; then
    exec bash -s -- "$@"
  else
    echo "bash is required to run this installer." >&2
    exit 1
  fi
fi

REPO_HEAD="https://raw.githubusercontent.com/aaukhatov/macbook-setup/main"
UTILS_PATH="$REPO_HEAD/utils.sh"
DEST_DIR="${HOME}/.tmp/macbook-setup"
DEST_FILE="$DEST_DIR/utils.sh"

mkdir -p "$DEST_DIR"
curl -fsSL "$UTILS_PATH" -o "$DEST_FILE" || { echo "Failed to download utils.sh"; exit 1; }

# Make file readable and keep permissions sane
chmod 644 "$DEST_FILE"

# Source it now so download_github_repo is available in this session
# (use a subshell-safe source)
# shellcheck disable=SC1090
source "$DEST_FILE"

download_github_repo aaukhatov macbook-setup .
