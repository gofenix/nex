#!/bin/bash
set -e

echo "🔨 Building installer archive..."
cd installer

# Clean old archives
rm -f nex_new-*.ez

# Build new archive
mix archive.build

# Get the version from VERSION file
VERSION=$(cat VERSION | tr -d '\n')

echo ""
echo "📦 Installing dev installer (force overwrite)..."
mix archive.install ./nex_new-${VERSION}.ez --force

cd ..
echo ""
echo "✅ Dev installer v${VERSION} installed successfully!"
echo ""
echo "You can now use: mix nex.new <app_name>"
