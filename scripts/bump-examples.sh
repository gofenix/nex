#!/bin/bash
# bump-examples.sh - batch-update example dependencies for release verification

set -e

if [ -z "$1" ]; then
  echo "Usage: ./bump-examples.sh <version>"
  echo "Example: ./bump-examples.sh 0.4.1"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=$1
echo "=== Bumping examples to version $VERSION ==="

mapfile -t EXAMPLES < <(elixir "$ROOT_DIR/scripts/examples_catalog.exs" verify)

for slug in "${EXAMPLES[@]}"; do
  example="$ROOT_DIR/examples/$slug"
  name="$(basename "$example")"
  echo "Updating $name..."

  sed -i.bak "s/{:nex_core, path: \"\.\.\/\.\.\/framework\"}/{:nex_core, \"~> $VERSION\"}/g" "$example/mix.exs"
  rm "$example/mix.exs.bak"

  if [ -f "$example/README.md" ]; then
    sed -i.bak "s/Nex 0\.[0-9]*/Nex $VERSION/g" "$example/README.md"
    rm "$example/README.md.bak" 2>/dev/null || true
  fi
done

echo "=== Examples updated to $VERSION ==="
echo "Next steps:"
echo "1. Review changes: git diff"
echo "2. Test: ./scripts/verify-examples.sh $VERSION"
echo "3. Commit: git add examples/ && git commit -m 'chore: bump examples to $VERSION'"
