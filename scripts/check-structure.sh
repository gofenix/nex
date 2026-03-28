#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "Structure check failed: $1" >&2
  exit 1
}

for path in ".sisyphus" "showcase" "e2e" "examples/agent_demo"; do
  if [ -e "$ROOT_DIR/$path" ]; then
    fail "forbidden path exists: $path"
  fi
done

if find "$ROOT_DIR/nex_base" -maxdepth 1 -type d -name 'nex_base-*' | grep -q .; then
  fail "archived nex_base package snapshot still exists"
fi

if find "$ROOT_DIR/examples" \
  \( -path '*/deps/*' -o -path '*/_build/*' -o -path '*/tmp/*' \) -prune -o \
  -type f \( -name 'AGENTS.md' -o -name 'WORKFLOW.md' -o -name '.cursorrules' \) -print \
  | grep -q .; then
  fail "examples/ still contains internal-only agent or editor metadata"
fi

ROOT_DIR="$ROOT_DIR" elixir /dev/stdin <<'EOF'
root = System.fetch_env!("ROOT_DIR")
catalog = Path.join(root, "examples/catalog.exs") |> Code.eval_file() |> elem(0)

slugs =
  catalog
  |> Enum.map(& &1.slug)
  |> MapSet.new()

Enum.each(catalog, fn entry ->
  example_path = Path.join([root, "examples", entry.slug])

  unless File.dir?(example_path) do
    IO.puts(:stderr, "Structure check failed: missing example directory #{entry.slug}")
    System.halt(1)
  end
end)

files_to_scan =
  [Path.join(root, "README.md")]
  |> Kernel.++(Path.wildcard(Path.join(root, "website/**/*")))
  |> Kernel.++(Path.wildcard(Path.join(root, ".github/workflows/*")))
  |> Kernel.++(Path.wildcard(Path.join(root, "scripts/*")))
  |> Enum.filter(&File.regular?/1)
  |> Enum.reject(&String.ends_with?(&1, "scripts/check-structure.sh"))

allowed_non_examples = MapSet.new(["catalog", "test_support"])
pattern = ~r/examples\/([a-zA-Z0-9_]+)/

Enum.each(files_to_scan, fn file ->
  Regex.scan(pattern, File.read!(file), capture: :all_but_first)
  |> List.flatten()
  |> Enum.each(fn slug ->
    unless MapSet.member?(slugs, slug) or MapSet.member?(allowed_non_examples, slug) do
      IO.puts(:stderr, "Structure check failed: #{file} references unknown example #{slug}")
      System.halt(1)
    end
  end)
end)
EOF

echo "Structure check passed."
