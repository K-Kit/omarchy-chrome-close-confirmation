#!/usr/bin/env bash

set -euo pipefail

readonly project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
sandbox="$(mktemp -d)"
trap 'rm -rf -- "$sandbox"' EXIT

readonly bindings_file="$sandbox/config/hypr/bindings.lua"
readonly bin_dir="$sandbox/bin"

mkdir -p -- "$(dirname -- "$bindings_file")"
printf '%s\n' '-- Existing user binding' >"$bindings_file"

export OMARCHY_BINDINGS_FILE="$bindings_file"
export OMARCHY_BIN_DIR="$bin_dir"
export HYPRCTL_BIN=true

"$project_dir/install.sh" >/dev/null
"$project_dir/install.sh" >/dev/null

test -x "$bin_dir/omarchy-close-window"
test "$(grep -Fc -- '-- omarchy-chrome-close-confirmation:start' "$bindings_file")" -eq 1
grep -Fq -- '-- Existing user binding' "$bindings_file"
test "$(find "$(dirname -- "$bindings_file")" -maxdepth 1 -name 'bindings.lua.bak.*' | wc -l)" -eq 2

"$project_dir/uninstall.sh" >/dev/null

! grep -Fq -- '-- omarchy-chrome-close-confirmation:start' "$bindings_file"
grep -Fq -- '-- Existing user binding' "$bindings_file"
test ! -e "$bin_dir/omarchy-close-window"

hyprctl() {
  if [[ "$1" == activewindow ]]; then
    printf '%s\n' "$TEST_WINDOW"
  else
    printf 'dispatch:%s\n' "$*"
  fi
}

zenity() {
  return "$ZENITY_RESULT"
}

export -f hyprctl zenity

TEST_WINDOW='{"class":"Google-chrome","address":"0xabc","title":"Test Chrome"}'
ZENITY_RESULT=1
export TEST_WINDOW ZENITY_RESULT
test -z "$(bash "$project_dir/bin/omarchy-close-window")"

ZENITY_RESULT=0
export ZENITY_RESULT
test "$(bash "$project_dir/bin/omarchy-close-window")" = \
  'dispatch:dispatch hl.dsp.window.close()'

TEST_WINDOW='{"class":"com.mitchellh.ghostty","address":"0xdef","title":"Terminal"}'
export TEST_WINDOW
test "$(bash "$project_dir/bin/omarchy-close-window")" = \
  'dispatch:dispatch hl.dsp.window.close()'

printf 'All tests passed.\n'
