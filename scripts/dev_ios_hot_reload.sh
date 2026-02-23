#!/usr/bin/env bash
set -euo pipefail

target_name="${1:-}"

if command -v fvm >/dev/null 2>&1 && [[ -f ".fvmrc" ]]; then
  flutter_cmd=(fvm flutter)
else
  flutter_cmd=(flutter)
fi

devices_output="$("${flutter_cmd[@]}" devices)"

if [[ -n "${target_name}" ]]; then
  selected_line="$(printf '%s\n' "${devices_output}" | grep -F "${target_name}" | grep "(simulator)" | grep "• ios" | head -n1 || true)"
else
  selected_line="$(printf '%s\n' "${devices_output}" | grep "(simulator)" | grep "• ios" | head -n1 || true)"
fi

if [[ -z "${selected_line}" ]]; then
  echo "No iOS simulator device found."
  echo
  echo "Available devices:"
  printf '%s\n' "${devices_output}"
  exit 1
fi

device_id="$(printf '%s\n' "${selected_line}" | awk -F '•' '{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2); print $2}')"
device_name="$(printf '%s\n' "${selected_line}" | awk -F '•' '{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$1); print $1}')"

echo "Starting app on: ${device_name}"
echo "Hot reload keys once running:"
echo "  r  -> hot reload"
echo "  R  -> hot restart"
echo

"${flutter_cmd[@]}" run -d "${device_id}"

