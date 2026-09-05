#!/usr/bin/env bash
# One-click Nightelf launcher for macOS.
# Finder: double-click 「启动 Nightelf.command」
# Terminal: ./script/launch_macos.sh [--rebuild]
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Nightelf"
DEBUG_APP="$ROOT_DIR/build/macos/Build/Products/Debug/${APP_NAME}.app"
RELEASE_APP="$ROOT_DIR/build/macos/Build/Products/Release/${APP_NAME}.app"
REBUILD=0

if [[ "${1:-}" == "--rebuild" || "${1:-}" == "rebuild" ]]; then
  REBUILD=1
fi

load_user_path() {
  # Finder-launched scripts do not load ~/.zshrc.
  set +u
  [[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile" >/dev/null 2>&1 || true
  [[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc" >/dev/null 2>&1 || true
  [[ -f "$HOME/.bash_profile" ]] && source "$HOME/.bash_profile" >/dev/null 2>&1 || true
  set -u
  export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/flutter/bin:$HOME/development/flutter/bin:$HOME/fvm/default/bin:$PATH"
}

find_flutter() {
  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return
  fi
  local candidate
  for candidate in \
    "$HOME/flutter/bin/flutter" \
    "$HOME/development/flutter/bin/flutter" \
    "$HOME/fvm/default/bin/flutter" \
    "/opt/homebrew/bin/flutter"; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return
    fi
  done
  return 1
}

pause_if_finder() {
  if [[ -z "${TERM_PROGRAM:-}" && -t 0 ]]; then
    printf '\n按回车关闭窗口…'
    read -r _
  elif [[ "${TERM_PROGRAM:-}" == "Apple_Terminal" ]]; then
    printf '\n按回车关闭窗口…'
    read -r _
  fi
}

fail() {
  echo "错误：$1" >&2
  pause_if_finder
  exit 1
}

load_user_path
cd "$ROOT_DIR"

APP_BUNDLE=""
if [[ "$REBUILD" -eq 0 ]]; then
  if [[ -d "$RELEASE_APP" ]]; then
    APP_BUNDLE="$RELEASE_APP"
  elif [[ -d "$DEBUG_APP" ]]; then
    APP_BUNDLE="$DEBUG_APP"
  fi
fi

if [[ -n "$APP_BUNDLE" ]]; then
  echo "正在打开：$APP_BUNDLE"
  /usr/bin/open "$APP_BUNDLE"
  exit 0
fi

FLUTTER_BIN="$(find_flutter)" || fail "未找到 Flutter。请先安装 Flutter，并确保终端里可以运行 flutter。"

echo "使用 Flutter：$FLUTTER_BIN"
echo "首次或重新构建需要一两分钟…"
"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" build macos --debug

if [[ ! -d "$DEBUG_APP" ]]; then
  fail "构建完成但未找到 $DEBUG_APP"
fi

echo "正在打开：$DEBUG_APP"
/usr/bin/open "$DEBUG_APP"
