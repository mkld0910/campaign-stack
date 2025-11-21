#!/bin/bash

################################################################################
# Campaign Stack - Branch Migration Script
# Migrates from single master branch to proper git flow structure
# Usage: bash scripts/migrate-to-branches.sh
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Main
print_header "Campaign Stack - Branch Migration"

echo "This script will reorganize your git branches:"
echo ""
echo "  master  → Stable, production-ready (v2.3.0)"
echo "  beta    → Latest features for testing (v2.4.0-beta.1)"
echo "  develop → Active development"
echo ""
print_warning "This will revert untested ACBC and Chatbot modules from master"
print_info "Modules will remain available on beta branch"
echo ""
read -p "Continue with migration? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "Migration cancelled"
    exit 0
fi

# Check we're in the right directory
if [ ! -f "compose.yaml" ]; then
    print_error "Must run from campaign-stack directory"
    exit 1
fi

# Check we're on master
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "master" ]; then
    print_error "Must be on master branch"
    echo "   Run: git checkout master"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    print_error "You have uncommitted changes"
    echo "   Commit or stash your changes first"
    exit 1
fi

# Step 1: Tag current master as beta
print_header "Step 1/7: Tagging current master as v2.4.0-beta.1"

if git tag | grep -q "v2.4.0-beta.1"; then
    print_warning "Tag v2.4.0-beta.1 already exists, skipping"
else
    git tag -a v2.4.0-beta.1 -m "Beta release: ACBC and Chatbot modules (untested)"
    git push origin v2.4.0-beta.1
    print_success "Tagged current state as v2.4.0-beta.1"
fi

# Step 2: Create beta branch
print_header "Step 2/7: Creating beta branch"

if git branch | grep -q "beta"; then
    print_warning "Beta branch already exists"
    read -p "Recreate it from current master? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git branch -D beta
        git checkout -b beta
        git push -f origin beta
        git checkout master
        print_success "Beta branch recreated"
    else
        print_info "Keeping existing beta branch"
    fi
else
    git checkout -b beta
    git push origin beta
    git checkout master
    print_success "Created beta branch with all features"
fi

# Step 3: Create develop branch
print_header "Step 3/7: Creating develop branch"

if git branch | grep -q "develop"; then
    print_warning "Develop branch already exists, skipping"
else
    git checkout -b develop
    git push origin develop
    git checkout master
    print_success "Created develop branch"
fi

# Step 4: Revert untested features from master
print_header "Step 4/7: Reverting untested modules from master"

print_info "This will create a revert commit removing ACBC and Chatbot modules"
print_info "Modules will still exist on beta and develop branches"
echo ""
read -p "Proceed with revert? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Reverting commits..."

    # Revert in reverse order (newest first)
    git revert --no-commit 5714b25  # Chatbot module
    git revert --no-commit 4f559df  # ACBC dual domain fix
    git revert --no-commit 3b9b6b1  # ACBC README update
    git revert --no-commit cd08487  # ACBC module

    # Commit the reverts
    git commit -m "Revert untested modules from master

Move ACBC and Chatbot modules to beta branch for testing.
Master remains at v2.3.0 with only tested features.

Untested features available on beta branch for early adopters.

See BRANCHING_STRATEGY.md for branch usage guidelines.

Reverted commits:
- 5714b25 Add AI Policy Chatbot Module (Phase 1)
- 4f559df Fix ACBC module to support dual domain configurations
- 3b9b6b1 Update README with ACBC module information
- cd08487 Add ACBC Voter Intelligence Module

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"

    git push origin master
    print_success "Reverted untested modules from master"
else
    print_warning "Skipping revert - master will keep untested features"
fi

# Step 5: Tag stable master
print_header "Step 5/7: Tagging stable master as v2.3.0"

if git tag | grep -q "v2.3.0"; then
    print_warning "Tag v2.3.0 already exists, skipping"
else
    git tag -a v2.3.0 -m "Stable release v2.3.0

Includes:
- Core stack (WordPress, CiviCRM, Traefik, MySQL, Wiki.js)
- Web-based GUI installer
- Automated backups to Storj
- Dual domain support
- API key validation for AI providers
- Repository reorganization
- Branch migration guides"

    git push origin v2.3.0
    print_success "Tagged master as v2.3.0"
fi

# Step 6: Create GitHub Release
print_header "Step 6/7: GitHub Release"

print_info "Create GitHub releases for both versions:"
echo ""
echo "1. Go to: https://github.com/mkld0910/campaign-stack/releases/new"
echo ""
echo "2. Create release for v2.3.0 (stable):"
echo "   Tag: v2.3.0"
echo "   Title: Campaign Stack v2.3.0 (Stable)"
echo "   Description: See CHANGELOG.md"
echo ""
echo "3. Create pre-release for v2.4.0-beta.1:"
echo "   Tag: v2.4.0-beta.1"
echo "   Title: Campaign Stack v2.4.0-beta.1 (Beta)"
echo "   ✅ Check 'This is a pre-release'"
echo "   Description: Beta release with ACBC and Chatbot modules"
echo ""
read -p "Press Enter when GitHub releases are created..."

# Step 7: Verify
print_header "Step 7/7: Verification"

print_info "Checking branch structure..."
echo ""
echo "Branches:"
git branch -a
echo ""
echo "Tags:"
git tag
echo ""

print_success "Branch migration complete!"
echo ""
echo -e "${GREEN}Branch Structure:${NC}"
echo "  🟢 master  - Stable (v2.3.0) - Production ready"
echo "  🟡 beta    - Beta (v2.4.0-beta.1) - Testing"
echo "  🔵 develop - Development - Active work"
echo ""
echo -e "${BLUE}Installation Instructions:${NC}"
echo ""
echo "Production (stable):"
echo "  git clone https://github.com/mkld0910/campaign-stack.git"
echo "  cd campaign-stack"
echo "  bash scripts/install-campaign-stack.sh"
echo ""
echo "Beta testing (new features):"
echo "  git clone https://github.com/mkld0910/campaign-stack.git"
echo "  cd campaign-stack"
echo "  git checkout beta"
echo "  bash scripts/install-campaign-stack.sh"
echo "  bash scripts/install-acbc-module.sh"
echo "  bash scripts/install-chatbot-module.sh"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "  1. Update README.md to document branch structure"
echo "  2. Set up branch protection on GitHub"
echo "  3. Announce beta testing period to community"
echo "  4. Collect feedback on ACBC and Chatbot modules"
echo ""
print_success "Migration completed successfully!"
