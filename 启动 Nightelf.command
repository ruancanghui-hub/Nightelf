#!/usr/bin/env bash
# Double-click this file in Finder to start Nightelf on macOS.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
exec bash "$ROOT/script/launch_macos.sh" "$@"
