#!/bin/bash
set -e

echo "📦 Publishing Nex packages to Hex.pm"
echo ""

# Get version
VERSION=$(cat VERSION | tr -d '\n')
echo "Version: $VERSION"
echo ""

# Publish framework
echo "📤 Publishing nex_core v$VERSION..."
cd framework
HEX_HOME=~/.hex mix hex.publish --yes --replace
cd ..
echo "✅ nex_core published"
echo ""

# Publish installer
echo "📤 Publishing nex_new v$VERSION..."
cd installer
HEX_HOME=~/.hex mix hex.publish --yes --replace
cd ..
echo "✅ nex_new published"
echo ""

echo "🎉 All packages published successfully!"
echo ""
echo "Published packages:"
echo "  - nex_core v$VERSION: https://hex.pm/packages/nex_core/$VERSION"
echo "  - nex_new v$VERSION: https://hex.pm/packages/nex_new/$VERSION"
