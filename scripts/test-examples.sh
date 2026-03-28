#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

EXAMPLES=()

while IFS= read -r slug; do
  EXAMPLES+=("$slug")
done < <(elixir "$ROOT_DIR/scripts/examples_catalog.exs" test)

if [ "${#EXAMPLES[@]}" -eq 0 ]; then
  echo "No testable examples were found in examples/catalog.exs."
  exit 1
fi

echo "=== Running example-owned tests ==="

for slug in "${EXAMPLES[@]}"; do
  echo ""
  echo "=== Testing $slug ==="
  (
    cd "$ROOT_DIR/examples/$slug"
    mix deps.get
    mix test
  )
done

echo ""
echo "=== All example tests passed ==="
