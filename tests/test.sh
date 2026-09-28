#!/usr/bin/env bash

set -euo pipefail

readonly project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
sandbox="$(mktemp -d)"
trap 'rm -rf -- "$sandbox"' EXIT

readonly bindings_file="$sandbox/config/hypr/bindings.lua"
readonly bin_dir="$sandbox/bin"

omarchy plugin validate "$project_dir" >/dev/null

mkdir -p -- "$(dirname -- "$bindings_file")"
printf '%s\n' '-- Existing user binding' >"$bindings_file"

plugin_shell() {
  if [[ "$2" == call && "$4" == ping ]]; then
    printf 'ready\n'
    return 0
  fi
  return 1
}
export -f plugin_shell

export OMARCHY_BINDINGS_FILE="$bindings_file"
export OMARCHY_BIN_DIR="$bin_dir"
export HYPRCTL_BIN=true
export OMARCHY_SHELL_BIN=false

if "$project_dir/install.sh" >/dev/null 2>&1; then
  printf 'Installer accepted an unavailable overlay plugin.\n' >&2
  exit 1
fi
grep -Fq -- '-- Existing user binding' "$bindings_file"
! grep -Fq -- '-- omarchy-chrome-close-confirmation:start' "$bindings_file"

export OMARCHY_SHELL_BIN=plugin_shell

"$project_dir/install.sh" >/dev/null
"$project_dir/install.sh" >/dev/null

test -x "$bin_dir/omarchy-close-window"
test "$(grep -Fc -- '-- omarchy-chrome-close-confirmation:start' "$bindings_file")" -eq 1
grep -Fq -- '-- Existing user binding' "$bindings_file"
test "$(find "$(dirname -- "$bindings_file")" -maxdepth 1 -name 'bindings.lua.bak.*' | wc -l)" -eq 2

plugin_remove() {
  printf '%s\n' "$*" >"$PLUGIN_REMOVE_CALL_FILE"
}
export -f plugin_remove
export PLUGIN_REMOVE_CALL_FILE="$sandbox/plugin-remove-call"
export OMARCHY_PLUGIN_REMOVE_BIN=plugin_remove

"$project_dir/uninstall.sh" >/dev/null

! grep -Fq -- '-- omarchy-chrome-close-confirmation:start' "$bindings_file"
grep -Fq -- '-- Existing user binding' "$bindings_file"
test ! -e "$bin_dir/omarchy-close-window"
test "$(cat "$PLUGIN_REMOVE_CALL_FILE")" = \
  'k-kit.chrome-close-confirmation --yes'

hyprctl() {
  if [[ "$1" == activewindow ]]; then
    printf '%s\n' "$TEST_WINDOW"
  else
    printf 'dispatch:%s\n' "$*"
  fi
}

zenity() {
  printf 'called\n' >>"$ZENITY_CALLS_FILE"
  return "$ZENITY_RESULT"
}

omarchy-shell() {
  if [[ "$2" == call && "$4" == ping ]]; then
    printf '%s\n' "$SHELL_PING_RESULT"
    return 0
  fi

  if [[ "$2" == summon ]]; then
    payload="${4:-}"
    printf '%s\n' "$payload" >"$TEST_PAYLOAD_FILE"
    response_fifo="$(jq -r '.responseFifo // ""' <<<"$payload")"
    printf '%s\n' "$PLUGIN_RESPONSE" >"$response_fifo"
    printf '%s\n' "$SHELL_SUMMON_RESULT"
    return 0
  fi

  return 1
}

export -f hyprctl zenity omarchy-shell

export OMARCHY_SHELL_BIN=omarchy-shell
export TEST_PAYLOAD_FILE="$sandbox/plugin-payload.json"
export ZENITY_CALLS_FILE="$sandbox/zenity-calls"

TEST_WINDOW='{"class":"Google-chrome","address":"0xabc","title":"Test Chrome"}'
SHELL_PING_RESULT=ready
SHELL_SUMMON_RESULT=ok
PLUGIN_RESPONSE=keep-open
ZENITY_RESULT=1
export TEST_WINDOW SHELL_PING_RESULT SHELL_SUMMON_RESULT PLUGIN_RESPONSE ZENITY_RESULT
test -z "$(bash "$project_dir/bin/omarchy-close-window")"
test ! -e "$ZENITY_CALLS_FILE"
jq -e '
  .windowTitle == "Test Chrome"
  and (.responseFifo | type == "string" and length > 0)
' "$TEST_PAYLOAD_FILE" >/dev/null

PLUGIN_RESPONSE=close
export PLUGIN_RESPONSE
test "$(bash "$project_dir/bin/omarchy-close-window")" = \
  'dispatch:dispatch hl.dsp.window.close()'
test ! -e "$ZENITY_CALLS_FILE"

TEST_WINDOW='{"class":"Chromium","address":"0xabc","title":"Test Chromium"}'
PLUGIN_RESPONSE=keep-open
export TEST_WINDOW PLUGIN_RESPONSE
test -z "$(bash "$project_dir/bin/omarchy-close-window")"
test ! -e "$ZENITY_CALLS_FILE"

SHELL_PING_RESULT=unknown
ZENITY_RESULT=1
export SHELL_PING_RESULT ZENITY_RESULT
test -z "$(bash "$project_dir/bin/omarchy-close-window")"
test "$(wc -l <"$ZENITY_CALLS_FILE")" -eq 1

ZENITY_RESULT=0
export ZENITY_RESULT
test "$(bash "$project_dir/bin/omarchy-close-window")" = \
  'dispatch:dispatch hl.dsp.window.close()'
test "$(wc -l <"$ZENITY_CALLS_FILE")" -eq 2

TEST_WINDOW='{"class":"com.mitchellh.ghostty","address":"0xdef","title":"Terminal"}'
export TEST_WINDOW
test "$(bash "$project_dir/bin/omarchy-close-window")" = \
  'dispatch:dispatch hl.dsp.window.close()'
test "$(wc -l <"$ZENITY_CALLS_FILE")" -eq 2

for web_app_class in chrome-app.zoom.us__-Default chrome-mail.google.com__-Default; do
  TEST_WINDOW="{\"class\":\"$web_app_class\",\"address\":\"0xdef\",\"title\":\"Web App\"}"
  export TEST_WINDOW
  test "$(bash "$project_dir/bin/omarchy-close-window")" = \
    'dispatch:dispatch hl.dsp.window.close()'
  test "$(wc -l <"$ZENITY_CALLS_FILE")" -eq 2
done

TEST_WINDOW='{"class":"Google-chrome","address":"","title":"No Window"}'
export TEST_WINDOW
test -z "$(bash "$project_dir/bin/omarchy-close-window")"
test "$(wc -l <"$ZENITY_CALLS_FILE")" -eq 2

printf 'All tests passed.\n'
