#!/usr/bin/env bash
set -euo pipefail

plugin_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

omarchy plugin validate "$plugin_dir"

if command -v qmllint >/dev/null 2>&1; then
  qml_files=(
    "$plugin_dir/TimerState.qml"
    "$plugin_dir/Tracker.qml"
    "$plugin_dir/BarWidget.qml"
    "$plugin_dir/Panel.qml"
    "$plugin_dir/TimeField.qml"
    "$plugin_dir/CompactField.qml"
  )
  while IFS= read -r -d '' f; do qml_files+=("$f"); done < <(find "$plugin_dir/components" "$plugin_dir/pages" -type f -name '*.qml' -print0 2>/dev/null)
  qmllint -I "${OMARCHY_PATH:-/usr/share/omarchy}/shell" "${qml_files[@]}"
fi
