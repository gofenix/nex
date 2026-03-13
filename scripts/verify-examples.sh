#!/bin/bash
# verify-examples.sh - 验证示例项目与框架版本的兼容性
# 运行方式: ./scripts/verify-examples.sh [version]

set -e

VERSION=${1:-"0.4.0"}
FRAMEWORK_PATH="$(pwd)/framework"

echo "=== Verifying examples compatibility with nex_core $VERSION ==="

for example in examples/*/; do
  if [ -f "$example/mix.exs" ]; then
    name=$(basename "$example")
    echo -n "Testing $name... "
    
    cd "$example"
    
    # 临时修改为版本号依赖
    sed -i.bak "s|{:nex_core, path: \"../../framework\"}|{:nex_core, \"~> $VERSION\"}|" mix.exs
    
    # 测试编译
    if mix deps.get > /dev/null 2>&1 && mix compile > /dev/null 2>&1; then
      echo "✅ OK"
    else
      echo "❌ FAILED"
      exit 1
    fi
    
    # 恢复本地路径
    mv mix.exs.bak mix.exs
    mix deps.get > /dev/null 2>&1
    
    cd - > /dev/null
  fi
done

echo "=== All examples verified successfully ==="
