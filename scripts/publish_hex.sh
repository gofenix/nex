#!/bin/bash
set -e

echo "📦 Publishing Nex packages to Hex.pm"
echo ""

# Get version from root VERSION file
VERSION=$(cat VERSION | tr -d '\n')
echo "Target version: $VERSION"
echo ""

# Step 1: Sync all version numbers
echo "🔄 Syncing version numbers..."
echo "$VERSION" > framework/VERSION
echo "$VERSION" > installer/VERSION
sed -i '' "s/version: \"[0-9.]*\"/version: \"$VERSION\"/" framework/mix.exs
sed -i '' "s/version: \"[0-9.]*\"/version: \"$VERSION\"/" installer/mix.exs
echo "✅ Version numbers synced"
echo ""

# Step 2: Publish framework
echo "📤 Publishing nex_core v$VERSION..."
cd framework
HEX_HOME=~/.hex mix hex.publish --yes --replace
cd ..
echo "✅ nex_core published"
echo ""

# Step 3: Publish installer
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
