#!/bin/bash

# NexBase Demo Setup Script

set -e

echo "🚀 NexBase Demo Setup"
echo "====================="

# Navigate to project directory
cd "$(dirname "$0")"

# Check if .env exists, if not copy from .env.example
if [ ! -f .env ]; then
    echo "📄 Creating .env from .env.example..."
    cp .env.example .env
    echo "⚠️  Please edit .env and set your DATABASE_URL"
    echo "   Default: postgresql://postgres:password@localhost:5432/nex_base_demo"
    exit 0
fi

# Install dependencies
echo "📦 Installing dependencies..."
mix deps.get

echo ""
echo "✅ Setup complete!"
echo ""
echo "To start the demo server:"
echo "  mix nex.dev"
echo ""
echo "Then open http://localhost:4000 in your browser"
echo ""
echo "Note: The tasks table will be created automatically on first run."
