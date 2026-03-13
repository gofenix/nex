#!/bin/bash
# bump-examples.sh - 发布时批量更新示例项目的版本号
# 运行方式: ./scripts/bump-examples.sh 0.4.1

set -e

if [ -z "$1" ]; then
  echo "Usage: ./bump-examples.sh <version>"
  echo "Example: ./bump-examples.sh 0.4.1"
  exit 1
fi

VERSION=$1
echo "=== Bumping examples to version $VERSION ==="

for example in examples/*/; do
  if [ -f "$example/mix.exs" ]; then
    name=$(basename "$example")
    echo "Updating $name..."
    
    # 更新版本号
    sed -i.bak "s/{:nex_core, path: \"\.\.\/\.\.\/framework\"}/{:nex_core, \"~> $VERSION\"}/g" "$example/mix.exs"
    rm "$example/mix.exs.bak"
    
    # 更新 README 中的版本引用
    if [ -f "$example/README.md" ]; then
      sed -i.bak "s/Nex 0\.[0-9]*/Nex $VERSION/g" "$example/README.md"
      rm "$example/README.md.bak" 2>/dev/null || true
    fi
  fi
done

echo "=== Examples updated to $VERSION ==="
echo "Next steps:"
echo "1. Review changes: git diff"
echo "2. Test: ./scripts/verify-examples.sh $VERSION"
echo "3. Commit: git add examples/ && git commit -m 'chore: bump examples to $VERSION'"
