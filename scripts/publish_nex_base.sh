#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get version from nex_base/mix.exs
VERSION=$(grep 'version:' nex_base/mix.exs | head -1 | sed 's/.*"\(.*\)".*/\1/')

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}   NexBase Release${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""
echo "Target version: ${YELLOW}$VERSION${NC}"
echo ""

PASSED=0
FAILED=0

check_step() {
    local step_name="$1"
    local check_command="$2"

    if eval "$check_command"; then
        echo -e "${GREEN}✓${NC} $step_name"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $step_name"
        ((FAILED++))
        return 1
    fi
}

echo -e "${BLUE}Pre-release checks...${NC}"
echo ""

# Check 1: nex_base directory exists
check_step "nex_base directory exists" "[ -d nex_base ]"

# Check 2: mix.exs has description
check_step "mix.exs has description" "grep -q 'description:' nex_base/mix.exs"

# Check 3: mix.exs has package config
check_step "mix.exs has package config" "grep -q 'package()' nex_base/mix.exs"

# Check 4: README.md exists
check_step "README.md exists" "[ -f nex_base/README.md ]"

# Check 5: LICENSE exists
check_step "LICENSE exists" "[ -f nex_base/LICENSE ]"

# Check 6: No stale tar files
check_step "No stale tar files" "! ls nex_base/nex_base-*.tar 2>/dev/null | grep -q ."

# Check 7: Compiles cleanly
echo -n "  Compiling... "
if (cd nex_base && mix compile --warnings-as-errors 2>/dev/null); then
    echo -e "\r${GREEN}✓${NC} Compiles without warnings"
    ((PASSED++))
else
    echo -e "\r${RED}✗${NC} Compiles without warnings"
    ((FAILED++))
fi

# Check 8: No uncommitted changes in nex_base/
if [ -n "$(git status --porcelain nex_base/)" ]; then
    echo -e "${RED}✗${NC} No uncommitted changes in nex_base/"
    ((FAILED++))
    git status --short nex_base/
else
    echo -e "${GREEN}✓${NC} No uncommitted changes in nex_base/"
    ((PASSED++))
fi

echo ""
echo -e "${BLUE}Checks: ${GREEN}$PASSED passed${NC} / ${RED}$FAILED failed${NC}"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ Release checks failed! Please fix the errors above.${NC}"
    echo ""
    echo "Required before publishing:"
    echo "  1. Ensure nex_base compiles cleanly"
    echo "  2. Commit all changes"
    echo "  3. Remove any stale .tar files"
    exit 1
fi

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}   Publishing nex_base v$VERSION${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Build and preview
echo "📦 Building package..."
cd nex_base
mix hex.build
echo ""

# Show package contents
echo "📋 Package contents:"
mix hex.build --unpack 2>/dev/null || true
echo ""

# Confirm
read -p "Publish nex_base v$VERSION to hex.pm? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Publish
echo ""
echo "📤 Publishing nex_base v$VERSION..."
HEX_HOME=~/.hex mix hex.publish --yes
cd ..

# Cleanup generated tar files
echo ""
echo "🧹 Cleaning up generated files..."
rm -f nex_base/nex_base-$VERSION.tar
rm -rf nex_base/nex_base-$VERSION

echo ""
echo -e "${GREEN}🎉 nex_base v$VERSION published successfully!${NC}"
echo ""
echo "  Package: https://hex.pm/packages/nex_base/$VERSION"
echo "  Docs:    https://hexdocs.pm/nex_base/$VERSION"
