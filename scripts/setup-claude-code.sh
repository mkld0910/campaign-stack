#!/bin/bash

################################################################################
# Campaign Stack - Claude Code Setup Helper
# Version: 1.0
# Purpose: Enable or reconfigure Claude Code CLI after initial deployment
# Usage: bash scripts/setup-claude-code.sh
#
# This script allows you to:
# - Enable Claude Code if not installed during initial setup
# - Reconfigure API key if it changed
# - Test Claude Code authentication
# - Setup CLI aliases
################################################################################

set -e

# Platform Detection
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo "Error: This script must run on Linux (Ubuntu/Debian/RHEL/CentOS)"
    echo "Please run this on your VPS or use WSL on Windows"
    exit 1
fi

# Colors for output
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

# Get repo directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

cd "$REPO_DIR"

# Check if .env exists
if [ ! -f .env ]; then
    print_error ".env file not found"
    print_info "Have you run the main installer? (scripts/install-campaign-stack.sh)"
    exit 1
fi

print_header "Claude Code CLI Setup Helper"

# Check current status
CLAUDE_ENABLED=$(grep "ENABLE_CLAUDE_CODE=" .env | cut -d '=' -f2 | tr -d ' ')

if [ "$CLAUDE_ENABLED" = "true" ]; then
    print_success "Claude Code is already enabled"
    
    read -p "Do you want to reconfigure? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Checking Claude Code status..."
        
        if command -v claude &> /dev/null; then
            print_success "Claude Code CLI is installed"
            CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
            print_info "Version: $CLAUDE_VERSION"
        else
            print_warning "Claude Code CLI not found, even though enabled in .env"
            print_info "Try installing manually: npm install -g @anthropic-ai/claude-code"
        fi
        
        print_info "To use Claude Code:"
        echo "  1. SSH to your VPS: ssh root@YOUR_VPS_IP"
        echo "  2. Start session: claude"
        echo "  3. Get help: /help"
        exit 0
    fi
fi

# Enable or reconfigure Claude Code
print_header "Claude Code Configuration"

echo "Enter your Anthropic API key:"
echo "  1. Visit: https://console.anthropic.com"
echo "  2. Go to: API keys"
echo "  3. Click: 'Create new secret key'"
echo "  4. Copy the key (starts with 'sk-')"
echo ""

read -s -p "Enter Claude API Key (hidden input): " CLAUDE_API_KEY
echo ""

if [ -z "$CLAUDE_API_KEY" ]; then
    print_error "API key cannot be empty"
    exit 1
fi

# Validate key format
if [[ ! $CLAUDE_API_KEY =~ ^sk-ant- ]]; then
    print_warning "Anthropic API keys typically start with 'sk-ant-'. Verify in Anthropic console."
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update .env file
print_info "Updating .env file..."

# Remove old values if they exist (portable sed)
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' '/^ENABLE_CLAUDE_CODE=/d' .env
    sed -i '' '/^CLAUDE_API_KEY=/d' .env
    sed -i '' '/^CLAUDE_MODEL=/d' .env
else
    sed -i '/^ENABLE_CLAUDE_CODE=/d' .env
    sed -i '/^CLAUDE_API_KEY=/d' .env
    sed -i '/^CLAUDE_MODEL=/d' .env
fi

# Add new values
cat >> .env << EOF

# Claude Code CLI Configuration (Updated: $(date))
ENABLE_CLAUDE_CODE=true
CLAUDE_API_KEY=${CLAUDE_API_KEY}
CLAUDE_MODEL=claude-sonnet-4-20250514
EOF

print_success ".env file updated"

# Check for Node.js
print_info "Checking Node.js installation..."

if ! command -v node &> /dev/null; then
    print_warning "Node.js not found. Installing Node.js and npm..."

    # Detect package manager
    if command -v apt-get &> /dev/null; then
        apt-get update -qq > /dev/null 2>&1
        apt-get install -y -qq nodejs npm > /dev/null 2>&1
    elif command -v yum &> /dev/null; then
        yum install -y nodejs npm > /dev/null 2>&1
    elif command -v dnf &> /dev/null; then
        dnf install -y nodejs npm > /dev/null 2>&1
    else
        print_error "Unsupported package manager. Install Node.js manually."
        exit 1
    fi

    print_success "Node.js installed: $(node --version)"
else
    print_success "Node.js already installed: $(node --version)"
fi

# Install Claude Code
print_info "Installing Claude Code CLI..."

if npm install -g @anthropic-ai/claude-code > /dev/null 2>&1; then
    print_success "Claude Code installed/updated"
    
    if command -v claude &> /dev/null; then
        print_success "Claude Code is ready to use"
    else
        print_error "Claude Code not found in PATH after installation"
        print_info "Try: npm list -g @anthropic-ai/claude-code"
        exit 1
    fi
else
    print_error "Failed to install Claude Code"
    print_info "Try manual install: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# Test authentication
print_header "Testing Authentication"

print_info "Testing Claude Code with stored API key..."

if export ANTHROPIC_API_KEY=$CLAUDE_API_KEY && claude --version &> /dev/null; then
    print_success "Claude Code authentication successful"
else
    print_warning "Authentication test inconclusive"
    print_info "You can test fully once connected to VPS: 'claude login'"
fi

# Setup helper (optional)
print_header "Optional: Setup Helper Alias"

echo "Would you like to create a helper script for easier access?"
echo "(Creates: claude-vps-login that auto-loads your API key)"
echo ""

read -p "Create helper? (y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    cat > "$REPO_DIR/scripts/claude-vps-login" << 'EOF_HELPER'
#!/bin/bash
# Claude VPS Login Helper
# Auto-loads API key from .env and starts Claude Code session

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ ! -f "$REPO_DIR/.env" ]; then
    echo "Error: .env file not found"
    exit 1
fi

# Load API key from .env
export ANTHROPIC_API_KEY=$(grep "CLAUDE_API_KEY=" "$REPO_DIR/.env" | cut -d '=' -f2 | tr -d ' ')

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: CLAUDE_API_KEY not set in .env"
    exit 1
fi

echo "Claude Code - VPS Management"
echo "API Key loaded from .env"
echo ""
echo "Commands:"
echo "  /help       - Show available commands"
echo "  /status     - Check token usage"
echo "  /model      - Switch AI model"
echo "  /logout     - Logout and exit"
echo ""

# Start Claude Code session
exec claude "$@"
EOF_HELPER
    
    chmod +x "$REPO_DIR/scripts/claude-vps-login"
    print_success "Helper script created: scripts/claude-vps-login"
    print_info "Usage: bash scripts/claude-vps-login"
else
    print_info "Skipped helper creation"
fi

# Final instructions
print_header "Setup Complete!"

echo -e "${GREEN}Claude Code is now configured!${NC}"
echo ""
echo "To use Claude Code:"
echo "  1. SSH to your VPS:"
echo "     ssh root@YOUR_VPS_IP"
echo ""
echo "  2. Start a coding session:"
echo "     claude"
echo ""
echo "  3. Get help:"
echo "     /help"
echo ""
echo "Example commands:"
echo "  /status              # Check token usage"
echo "  /model               # See available models"
echo "  /clear               # Clear conversation"
echo "  /logout              # Exit and logout"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "  See docs/12-CLAUDE-CODE.md for detailed guide"
echo "  https://docs.claude.com/en/docs/claude-code/"
echo ""

print_success "Claude Code setup complete!"
