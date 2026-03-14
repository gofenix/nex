#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get version from root VERSION file
VERSION=$(cat VERSION | tr -d '\n')

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}   Nex Framework Release${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""
echo "Target version: ${YELLOW}$VERSION${NC}"
echo ""

PASSED=0
FAILED=0

# Function to check a step
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

# Check 1: Root VERSION file exists
check_step "Root VERSION file exists" "[ -f VERSION ]"

# Check 2: CHANGELOG.md has been updated for this version
check_step "CHANGELOG.md contains version $VERSION" "grep -Eq \"## \\[Nex $VERSION\\]|## \\[$VERSION\\]\" CHANGELOG.md"

# Check 3: CHANGELOG.md has release date
check_step "CHANGELOG.md has release date for $VERSION" "grep -A1 -E \"## \\[Nex $VERSION\\]|## \\[$VERSION\\]\" CHANGELOG.md | grep -q \"[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\""

# Check 4: Framework changelog updated
check_step "Framework CHANGELOG.md updated" "[ -f framework/CHANGELOG.md ] && grep -q \"$VERSION\" framework/CHANGELOG.md"

# Check 5: Installer changelog updated
check_step "Installer CHANGELOG.md updated" "[ -f installer/CHANGELOG.md ] && grep -q \"$VERSION\" installer/CHANGELOG.md"

check_step "nex_env version synced" "grep -q \"version: \\\"$VERSION\\\"\" nex_env/mix.exs"

check_step "nex_base version synced" "grep -q \"version: \\\"$VERSION\\\"\" nex_base/mix.exs"

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
check_step "On main branch" "[ \"$CURRENT_BRANCH\" = \"main\" ]"

if [ -n "$(git status --porcelain)" ]; then
    echo -e "${RED}✗${NC} No uncommitted changes"
    ((FAILED++))
    git status --short
else
    echo -e "${GREEN}✓${NC} No uncommitted changes"
    ((PASSED++))
fi

echo ""
echo -e "${BLUE}Checks: ${GREEN}$PASSED passed${NC} / ${RED}$FAILED failed${NC}"
echo ""

if [ $FAILED -gt 0 ]; then
    echo -e "${RED}❌ Release checks failed! Please fix the errors above.${NC}"
    echo ""
    echo "Required before publishing:"
    echo "  1. Update CHANGELOG.md with version and date"
    echo "  2. Update installer/CHANGELOG.md and framework/CHANGELOG.md"
    echo "  3. Commit all changes"
    echo "  4. Ensure you're on main branch"
    exit 1
fi

check_step "Installer template derives version from app metadata" "grep -q 'Application.spec(:nex_new, :vsn)' installer/lib/mix/tasks/nex.new.ex"

echo ""
echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}   Starting Release Process${NC}"
echo -e "${BLUE}===========================================${NC}"
echo ""

# Step 1: Sync all version numbers
echo "🔄 Syncing version numbers..."
echo "$VERSION" > framework/VERSION
echo "$VERSION" > installer/VERSION
echo "$VERSION" > nex_env/VERSION
echo "$VERSION" > nex_base/VERSION
sed -i '' "s/version: \"[0-9.]*\"/version: \"$VERSION\"/" framework/mix.exs
sed -i '' "s/version: \"[0-9.]*\"/version: \"$VERSION\"/" installer/mix.exs
sed -i '' "s/version: \"[0-9.]*\"/version: \"$VERSION\"/" nex_env/mix.exs
sed -i '' "s/version: \"[0-9.]*\"/version: \"$VERSION\"/" nex_base/mix.exs
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

echo "📤 Publishing nex_env v$VERSION..."
cd nex_env
HEX_HOME=~/.hex mix hex.publish --yes --replace
cd ..
echo "✅ nex_env published"
echo ""

echo "📤 Publishing nex_base v$VERSION..."
cd nex_base
HEX_HOME=~/.hex mix hex.publish --yes --replace
cd ..
echo "✅ nex_base published"
echo ""

echo -e "${GREEN}🎉 All packages published successfully!${NC}"
echo ""
echo "Published packages:"
echo "  - nex_core v$VERSION: https://hex.pm/packages/nex_core/$VERSION"
echo "  - nex_new v$VERSION: https://hex.pm/packages/nex_new/$VERSION"
echo "  - nex_env v$VERSION: https://hex.pm/packages/nex_env/$VERSION"
echo "  - nex_base v$VERSION: https://hex.pm/packages/nex_base/$VERSION"
