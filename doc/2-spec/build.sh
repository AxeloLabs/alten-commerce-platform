#!/usr/bin/env bash
# Builds the specification PDFs.
#
#   doc/2-spec/build.sh              build every document
#   doc/2-spec/build.sh 01-          build the documents whose path contains "01-"
#   doc/2-spec/build.sh --check      run the identifier checks only
#
# Sources : doc/2-spec/NN-folder/NN-MM-title.adoc
# Output  : doc/9-generated/pdf/NN-folder/NN-MM-title.pdf   (derived, safe to delete)
#
# Rendering is fully local: Asciidoctor PDF, PlantUML and Graphviz run in a pinned
# container image, BPMN is rendered by bpmn-js in a local headless browser.
set -euo pipefail

IMAGE="docker.io/asciidoctor/docker-asciidoctor:1.108.1"
SPEC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOC="$(dirname "$SPEC")"
GEN="$DOC/9-generated"
ENGINE="${CONTAINER_ENGINE:-podman}"

step() { printf '\n== %s\n' "$*"; }

step "Identifier registry and checks"
python3 "$SPEC/_tools/ids.py"
[[ "${1:-}" == "--check" ]] && exit 0

step "BPMN diagrams"
python3 "$SPEC/_tools/bpmn_gen.py"
"$SPEC/_tools/bpmn/render.sh"

step "PDF documents"
filter="${1:-}"
mapfile -t sources < <(cd "$DOC" && find 2-spec -path '2-spec/[0-9][0-9]-*/[0-9][0-9]-[0-9][0-9]-*.adoc' | sort | grep -F -- "$filter")
if [[ ${#sources[@]} -eq 0 ]]; then
  echo "no document matches '$filter'" >&2
  exit 1
fi
if [[ -z "$filter" ]]; then
  # Full build: render every diagram afresh, so that a renamed or removed diagram leaves nothing behind.
  rm -rf "$GEN/diagram-cache"
  rm -f "$GEN"/diagrams/*.svg
fi
mkdir -p "$GEN/pdf" "$GEN/diagrams" "$GEN/diagram-cache"
"$ENGINE" run --rm --security-opt label=disable \
  -v "$DOC":/documents -w /documents "$IMAGE" \
  asciidoctor-pdf -r asciidoctor-diagram \
    --failure-level WARN \
    -R 2-spec -D 9-generated/pdf \
    "${sources[@]}"

step "Diagram check"
# PlantUML draws its warnings and errors inside the image instead of failing: look for them.
if grep -l -i -E 'deprecated|Syntax(&#160;| )Error|Cannot(&#160;| )(include|open)' "$GEN"/diagrams/*.svg 2>/dev/null; then
  echo "the diagrams listed above contain a PlantUML warning or error" >&2
  exit 1
fi
echo "diagrams: no PlantUML warning or error"

step "Document check"
# A version attribute quoted inside a listing block is not substituted unless the block asks for it.
if command -v pdftotext >/dev/null; then
  leftovers=0
  for source in "${sources[@]}"; do
    pdf="$GEN/pdf/${source#2-spec/}"; pdf="${pdf%.adoc}.pdf"
    if pdftotext "$pdf" - | grep -n -E '\{v-[a-z0-9-]+\}'; then
      echo "  ^ unresolved version attribute in $pdf" >&2
      leftovers=1
    fi
  done
  [[ $leftovers -eq 0 ]] || exit 1
  echo "documents: no unresolved version attribute"
else
  echo "documents: pdftotext not found, check skipped"
fi

step "Done"
printf '%s document(s) in %s\n' "${#sources[@]}" "$GEN/pdf"
