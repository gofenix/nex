#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-$(cat "$ROOT_DIR/VERSION")}"
MODE="${2:-path}"
CATALOG_SCRIPT="$ROOT_DIR/scripts/examples_catalog.exs"

usage() {
  cat <<EOF
Usage: ./scripts/verify-examples.sh [version] [path|hex|auto]

Modes:
  path  Verify examples against the local framework checkout. This is the default.
  hex   Rewrite each example to use nex_core ~> <version> from Hex, then compile it.
  auto  Use the requested Hex version when it exists on hex.pm; otherwise fall back to path mode.
EOF
}

hex_version_available() {
  curl -fsSL https://hex.pm/api/packages/nex_core | grep -q "\"version\":\"$VERSION\""
}

resolve_mode() {
  case "$MODE" in
    path|hex)
      echo "$MODE"
      ;;
    auto)
      if hex_version_available; then
        echo "hex"
      else
        echo "path"
      fi
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown mode: $MODE" >&2
      usage >&2
      exit 1
      ;;
  esac
}

restore_example() {
  local example_dir="$1"

  if [ -f "$example_dir/mix.exs.bak" ]; then
    mv "$example_dir/mix.exs.bak" "$example_dir/mix.exs"
  fi

  if [ -f "$example_dir/mix.lock.bak" ]; then
    mv "$example_dir/mix.lock.bak" "$example_dir/mix.lock"
  fi
}

verify_example() {
  local example_dir="$1"
  local name

  name="$(basename "$example_dir")"
  printf "Testing %s... " "$name"

  pushd "$example_dir" >/dev/null

  if [ "$RESOLVED_MODE" = "hex" ]; then
    cp mix.exs mix.exs.bak

    if [ -f mix.lock ]; then
      cp mix.lock mix.lock.bak
    fi

    sed -i.bak2 "s|{:nex_core, path: \"../../framework\"}|{:nex_core, \"~> $VERSION\"}|" mix.exs
    rm -f mix.exs.bak2
  fi

  if mix deps.get >/dev/null 2>&1 && mix compile >/dev/null 2>&1; then
    echo "OK"
  else
    echo "FAILED"
    popd >/dev/null
    return 1
  fi

  if [ "$RESOLVED_MODE" = "hex" ]; then
    restore_example "$example_dir"
    mix deps.get >/dev/null 2>&1 || true
  fi

  popd >/dev/null
}

RESOLVED_MODE="$(resolve_mode)"

if [ "$MODE" = "auto" ] && [ "$RESOLVED_MODE" = "path" ]; then
  echo "nex_core $VERSION is not available on Hex yet; falling back to local path verification."
fi

EXAMPLES=()

while IFS= read -r slug; do
  EXAMPLES+=("$slug")
done < <(elixir "$CATALOG_SCRIPT" verify)

echo "=== Verifying examples compatibility with nex_core $VERSION ($RESOLVED_MODE mode) ==="

for slug in "${EXAMPLES[@]}"; do
  example="$ROOT_DIR/examples/$slug"

  if ! verify_example "$example"; then
    restore_example "$example"
    exit 1
  fi
done

echo "=== All examples verified successfully ==="
