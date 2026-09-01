#!/usr/bin/env bash

set -euo pipefail

readonly project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly bindings_file="${OMARCHY_BINDINGS_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/hypr/bindings.lua}"
readonly bin_dir="${OMARCHY_BIN_DIR:-$HOME/.local/bin}"
readonly helper_file="$bin_dir/omarchy-close-window"
readonly hyprctl_bin="${HYPRCTL_BIN:-hyprctl}"
readonly marker_start="-- omarchy-chrome-close-confirmation:start"
readonly marker_end="-- omarchy-chrome-close-confirmation:end"

for command in jq zenity "$hyprctl_bin"; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$command" >&2
    exit 1
  fi
done

mkdir -p -- "$(dirname -- "$bindings_file")" "$bin_dir"

bindings_existed=false
if [[ -f "$bindings_file" ]]; then
  bindings_existed=true
else
  : >"$bindings_file"
fi

start_count="$(grep -Fc -- "$marker_start" "$bindings_file" || true)"
end_count="$(grep -Fc -- "$marker_end" "$bindings_file" || true)"
if [[ "$start_count" -ne "$end_count" || "$start_count" -gt 1 ]]; then
  printf 'Refusing to edit malformed managed block in %s\n' "$bindings_file" >&2
  exit 1
fi

readonly timestamp="$(date +%Y%m%d%H%M%S%N)"
readonly backup_file="${bindings_file}.bak.${timestamp}"
cp -- "$bindings_file" "$backup_file"

temp_file="$(mktemp --tmpdir="$(dirname -- "$bindings_file")" '.bindings.lua.XXXXXX')"
trap 'rm -f -- "$temp_file"' EXIT

awk -v start="$marker_start" -v end="$marker_end" '
  $0 == start { managed = 1; next }
  $0 == end { managed = 0; next }
  !managed { print }
' "$bindings_file" >"$temp_file"

cat >>"$temp_file" <<EOF

$marker_start
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window", "omarchy-close-window")
$marker_end
EOF

chmod --reference="$bindings_file" "$temp_file"
mv -- "$temp_file" "$bindings_file"

"$hyprctl_bin" reload >/dev/null
config_errors="$("$hyprctl_bin" configerrors)"
if [[ -n "$config_errors" ]]; then
  if [[ "$bindings_existed" == true ]]; then
    cp -- "$backup_file" "$bindings_file"
  else
    rm -f -- "$bindings_file"
  fi
  "$hyprctl_bin" reload >/dev/null
  printf 'Hyprland rejected the binding; restored %s\n%s\n' "$backup_file" "$config_errors" >&2
  exit 1
fi

install -m 0755 -- "$project_dir/bin/omarchy-close-window" "$helper_file"

printf 'Installed Chrome close confirmation.\n'
printf 'Binding: SUPER + W\n'
printf 'Backup: %s\n' "$backup_file"
