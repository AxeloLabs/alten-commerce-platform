#!/usr/bin/env bash
# Renders doc/9-generated/bpmn/*.bpmn to doc/9-generated/diagrams/bpmn/*.png with bpmn-js.
# Uses the browser already installed on the workstation: nothing is downloaded at render time.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN="$(cd "$HERE/../../.." && pwd)/9-generated"
OUT="$GEN/diagrams/bpmn"

export PUPPETEER_SKIP_DOWNLOAD=1
browser="${PUPPETEER_EXECUTABLE_PATH:-$(command -v google-chrome || command -v chromium || command -v chromium-browser || true)}"
if [[ -z "$browser" ]]; then
  echo "bpmn: no Chrome or Chromium found; set PUPPETEER_EXECUTABLE_PATH" >&2
  exit 1
fi
export PUPPETEER_EXECUTABLE_PATH="$browser"

if [[ ! -x "$HERE/node_modules/.bin/bpmn-to-image" ]]; then
  (cd "$HERE" && pnpm install --frozen-lockfile)
fi

shopt -s nullglob
files=("$GEN"/bpmn/*.bpmn)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "bpmn: nothing to render"
  exit 0
fi
mkdir -p "$OUT"
jobs=()
for file in "${files[@]}"; do
  jobs+=("$file:$OUT/$(basename "${file%.bpmn}").png")
done
"$HERE/node_modules/.bin/bpmn-to-image" --no-title --no-footer --scale=2 "${jobs[@]}"
echo "bpmn: ${#files[@]} diagram(s) rendered to $OUT"
