#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if version argument is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version argument is required${NC}"
    echo "Usage: ./release.sh <version> [pre|major|minor|patch]"
    echo ""
    echo "Examples:"
    echo "  ./release.sh 0.2.0        # Set specific version"
    echo "  ./release.sh minor        # Bump minor version (0.1.0 -> 0.2.0)"
    echo "  ./release.sh patch        # Bump patch version (0.1.0 -> 0.1.1)"
    echo "  ./release.sh major        # Bump major version (0.1.0 -> 1.0.0)"
    exit 1
 fi

VERSION_TYPE=$1

# Get current version
CURRENT_VERSION=$(cat VERSION 2>/dev/null || echo "0.0.0")

# Calculate new version
if [[ "$VERSION_TYPE" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Exact version provided
    NEW_VERSION="$VERSION_TYPE"
else
    # Bump type provided
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]}
    PATCH=${VERSION_PARTS[2]}

    case "$VERSION_TYPE" in
        major)
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            ;;
        minor)
            MINOR=$((MINOR + 1))
            PATCH=0
            ;;
        patch)
            PATCH=$((PATCH + 1))
            ;;
        *)
            echo -e "${RED}Error: Invalid version type '$VERSION_TYPE'${NC}"
            exit 1
            ;;
    esac

    NEW_VERSION="$MAJOR.$MINOR.$PATCH"
fi

echo -e "${GREEN}Releasing Nex $NEW_VERSION${NC}"
echo -e "${YELLOW}Current version: $CURRENT_VERSION${NC}"
echo -e "${YELLOW}New version: $NEW_VERSION${NC}"
echo ""

# Confirm release
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Release cancelled${NC}"
    exit 0
fi

# Update VERSION file
echo "$NEW_VERSION" > VERSION
echo -e "${GREEN}Updated VERSION file${NC}"

# Update CHANGELOG
echo ""
echo -e "${YELLOW}Please update CHANGELOG.md with release notes for $NEW_VERSION${NC}"
read -p "Press Enter to open CHANGELOG.md in your editor..."

# Open editor for CHANGELOG
if [ -n "$EDITOR" ]; then
    $EDITOR CHANGELOG.md
else
    # Fallback to common editors
    if command -v code &> /dev/null; then
        code CHANGELOG.md
    elif command -v vim &> /dev/null; then
        vim CHANGELOG.md
    else
        nano CHANGELOG.md
    fi
fi

# Build and publish framework
echo ""
echo -e "${GREEN}Building framework...${NC}"
cd framework
mix clean
mix hex.build

echo ""
echo -e "${YELLOW}Publishing framework to hex.pm...${NC}"
mix hex.publish

# Build and publish installer
echo ""
echo -e "${GREEN}Building installer...${NC}"
cd ../installer
mix clean
mix hex.build

echo ""
echo -e "${YELLOW}Publishing installer to hex.pm...${NC}"
mix hex.publish

# Create git tag
cd ..
echo ""
echo -e "${GREEN}Creating git tag v$NEW_VERSION...${NC}"
git add VERSION CHANGELOG.md
git commit -m "Release v$NEW_VERSION" || echo -e "${YELLOW}No changes to commit${NC}"
git tag "v$NEW_VERSION"
git push origin main
git push origin "v$NEW_VERSION"

echo ""
echo -e "${GREEN}Release v$NEW_VERSION completed successfully!${NC}"
echo ""
echo "Published packages:"
echo "  - nex:$NEW_VERSION (framework)"
echo "  - nex_new:$NEW_VERSION (installer)"
