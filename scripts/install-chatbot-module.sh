#!/bin/bash

################################################################################
# Campaign Stack - AI Policy Chatbot Module Installer
# Version: 1.0 (Phase 1)
# Purpose: Install chatbot module for intelligent voter policy Q&A
# Usage: bash scripts/install-chatbot-module.sh
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

# Main Installation
print_header "AI Policy Chatbot Module Installer v1.0 (Phase 1)"
echo "This will install intelligent AI chatbot for voter policy questions"
echo "Features: Multi-backend AI routing, Wiki.js integration, CiviCRM logging"
echo "Estimated time: 10-15 minutes"
echo ""

# Check if running from correct directory
if [ ! -f "compose.yaml" ]; then
    print_error "Must run from campaign-stack directory"
    echo "   cd /srv/campaign-stack && bash scripts/install-chatbot-module.sh"
    exit 1
fi

# Check if base stack is running
if ! docker compose ps | grep -q "wordpress_app.*Up"; then
    print_error "Base Campaign Stack not running"
    echo "   Run: docker compose up -d"
    exit 1
fi

# Check if Wiki.js is running
if ! docker compose ps | grep -q "wiki.*Up"; then
    print_warning "Wiki.js not running - chatbot will have limited functionality"
    echo "   Wiki.js integration provides policy content for the chatbot"
    read -p "Continue without Wiki.js? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled"
        exit 1
    fi
fi

# Prerequisites Check
print_header "Step 1/9: Prerequisites Check"

# Check for compose-chatbot.yaml
if [ ! -f "compose-chatbot.yaml" ]; then
    print_error "compose-chatbot.yaml not found"
    print_info "Pull latest from repository: git pull origin master"
    exit 1
fi
print_success "compose-chatbot.yaml found"

# Check for chatbot module directory
if [ ! -d "chatbot-module" ]; then
    print_error "chatbot-module directory not found"
    print_info "Pull latest from repository: git pull origin master"
    exit 1
fi
print_success "Chatbot module directory found"

# Configuration
print_header "Step 2/9: Chatbot Module Configuration"

# Check if .env exists
if [ ! -f ".env" ]; then
    print_error ".env file not found"
    echo "   Have you run the main installer?"
    exit 1
fi

# Read domain configuration
DOMAIN=$(grep ^DOMAIN .env | cut -d '=' -f2 || echo "")
BACKEND_DOMAIN=$(grep ^BACKEND_DOMAIN .env | cut -d '=' -f2)

# Determine admin domain for credentials file
if [ -n "$BACKEND_DOMAIN" ]; then
    ADMIN_DOMAIN="$BACKEND_DOMAIN"
    print_info "Dual domain configuration detected: Admin on ${BACKEND_DOMAIN}"
else
    ADMIN_DOMAIN="$DOMAIN"
    print_info "Single domain configuration: All services on ${DOMAIN}"
fi

# Add chatbot configuration to .env if not present
if ! grep -q "CHATBOT_ENABLED" .env; then
    print_info "Adding chatbot configuration to .env..."

    CHATBOT_DB_PASS=$(openssl rand -base64 12)
    CHATBOT_DB_ROOT_PASS=$(openssl rand -base64 12)

    cat >> .env << EOF

# ============================================================================
# AI POLICY CHATBOT MODULE CONFIGURATION
# ============================================================================
# Chatbot Database
CHATBOT_DB_PASSWORD=${CHATBOT_DB_PASS}
CHATBOT_DB_ROOT_PASSWORD=${CHATBOT_DB_ROOT_PASS}

# Chatbot Features
CHATBOT_ENABLED=true
CHATBOT_DEFAULT_BACKEND=ollama

# Budget Controls (USD per month)
CHATBOT_MONTHLY_BUDGET=100
CHATBOT_ANTHROPIC_BUDGET=50
CHATBOT_OPENAI_BUDGET=30
CHATBOT_GOOGLE_BUDGET=20

# Routing Thresholds (tokens)
CHATBOT_SIMPLE_TOKENS=50
CHATBOT_COMPLEX_TOKENS=200

# Privacy Settings
CHATBOT_REQUIRE_CONSENT=true
CHATBOT_ANONYMIZE_DATA=true

# Wiki.js Cache
WIKIJS_CACHE_TTL_HOURS=24
EOF

    print_success "Chatbot configuration added to .env"

    # Save credentials
    cat >> CREDENTIALS_BACKUP.txt << EOF

=== AI POLICY CHATBOT MODULE CREDENTIALS ===
Chatbot API:
  URL: https://chatbot-api.${ADMIN_DOMAIN}
  (Internal - used by WordPress plugin)

Wiki.js Connector:
  URL: https://wikijs-connector.${ADMIN_DOMAIN}
  (Internal - fetches policy content)

Database Passwords:
  Chatbot DB: ${CHATBOT_DB_PASS}
  Chatbot Root DB: ${CHATBOT_DB_ROOT_PASS}

SAVE THESE CREDENTIALS SECURELY!
EOF

    print_warning "Credentials saved to CREDENTIALS_BACKUP.txt"
else
    print_info "Chatbot configuration already exists in .env"
fi

# Wiki.js API Key Configuration
print_header "Step 3/9: Wiki.js Integration Setup"

if grep -q "WIKIJS_API_KEY" .env && [ -n "$(grep ^WIKIJS_API_KEY .env | cut -d '=' -f2)" ]; then
    print_success "Wiki.js API key already configured"
else
    print_info "Wiki.js API key configuration"
    echo ""
    echo "To enable Wiki.js policy content integration:"
    echo "1. Log into Wiki.js admin: https://wiki.${DOMAIN}/a"
    echo "2. Navigate to: Administration → API Access"
    echo "3. Create new API key with 'Read Pages' permission"
    echo "4. Copy the API key"
    echo ""
    read -p "Do you have a Wiki.js API key? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        read -p "Enter Wiki.js API key: " WIKIJS_KEY
        echo "WIKIJS_API_KEY=${WIKIJS_KEY}" >> .env
        print_success "Wiki.js API key configured"
    else
        echo "WIKIJS_API_KEY=" >> .env
        print_warning "Skipping Wiki.js integration - chatbot will have limited policy content"
        print_info "You can add the API key later by editing .env"
    fi
fi

# AI Provider Check
print_header "Step 4/9: AI Provider Configuration"

# Check if AI provider is installed
if docker compose ps | grep -q "ai_provider.*Up"; then
    print_success "AI provider (Ollama) is running"
    print_info "Chatbot will use local Ollama models by default (free)"
else
    print_warning "AI provider (Ollama) not installed"
    echo ""
    echo "The chatbot can use multiple AI backends:"
    echo "  - Ollama (local, free) - Recommended for Phase 1"
    echo "  - Anthropic Claude (cloud, paid)"
    echo "  - OpenAI GPT (cloud, paid)"
    echo "  - Google Gemini (cloud, paid)"
    echo ""
    read -p "Install Ollama local AI provider now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Installing AI provider..."
        if [ -f "scripts/install-ai-provider.sh" ]; then
            bash scripts/install-ai-provider.sh
        else
            print_warning "AI provider installer not found"
            print_info "You can install it later with: bash scripts/install-ai-provider.sh"
        fi
    else
        print_warning "Continuing without local AI - ensure cloud API keys are configured"
    fi
fi

# Build Docker Images
print_header "Step 5/9: Building Chatbot Services"

print_info "Building AI router service..."
if docker compose -f compose.yaml -f compose-chatbot.yaml build ai_router; then
    print_success "AI router service built"
else
    print_error "Failed to build AI router service"
    exit 1
fi

print_info "Building Wiki.js connector service..."
if docker compose -f compose.yaml -f compose-chatbot.yaml build wikijs_connector; then
    print_success "Wiki.js connector service built"
else
    print_error "Failed to build Wiki.js connector service"
    exit 1
fi

# Deploy Chatbot Services
print_header "Step 6/9: Deploying Chatbot Services"

print_info "Pulling Docker images (this may take a few minutes)..."
docker compose -f compose.yaml -f compose-chatbot.yaml pull

print_info "Starting chatbot services..."
docker compose -f compose.yaml -f compose-chatbot.yaml up -d

print_info "Waiting for services to initialize..."
sleep 30

# Verify Deployment
print_header "Step 7/9: Verifying Chatbot Deployment"

if docker compose -f compose.yaml -f compose-chatbot.yaml ps | grep -q "chatbot_db.*Up"; then
    print_success "Chatbot database running"
else
    print_warning "Chatbot database may still be starting"
fi

if docker compose -f compose.yaml -f compose-chatbot.yaml ps | grep -q "ai_router.*Up"; then
    print_success "AI router service running"
else
    print_warning "AI router may still be starting"
fi

if docker compose -f compose.yaml -f compose-chatbot.yaml ps | grep -q "wikijs_connector.*Up"; then
    print_success "Wiki.js connector running"
else
    print_warning "Wiki.js connector may still be starting"
fi

# Install Kognetiks WordPress Plugin
print_header "Step 8/9: WordPress Plugin Installation"

print_info "Installing Kognetiks Chatbot plugin for WordPress..."

# Download Kognetiks plugin
PLUGIN_URL="https://downloads.wordpress.org/plugin/chatbot.latest-stable.zip"
PLUGIN_DIR="/var/www/html/wp-content/plugins"

docker exec wordpress_app bash -c "
cd /var/www/html/wp-content/plugins && \
wget -q ${PLUGIN_URL} -O chatbot.zip && \
unzip -q chatbot.zip && \
rm chatbot.zip && \
chown -R www-data:www-data chatbot
" 2>/dev/null || true

if docker exec wordpress_app test -d "$PLUGIN_DIR/chatbot"; then
    print_success "Kognetiks Chatbot plugin downloaded"
    print_warning "Activation required: Log into WordPress admin to activate the plugin"
else
    print_warning "Plugin installation failed - manual installation required"
    print_info "Download from: https://wordpress.org/plugins/chatbot/"
fi

# Final Instructions
print_header "Step 9/9: Installation Complete!"

echo -e "${GREEN}AI Policy Chatbot Module is now installed!${NC}"
echo ""
echo -e "${GREEN}Access Points:${NC}"
echo "  Chatbot (Frontend): https://${DOMAIN} (embedded in WordPress)"
echo "  AI Router API: https://chatbot-api.${ADMIN_DOMAIN}"
echo "  Wiki.js Connector: https://wikijs-connector.${ADMIN_DOMAIN}"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Log into WordPress admin: https://${DOMAIN}/wp-admin"
echo "  2. Navigate to: Plugins → Installed Plugins"
echo "  3. Activate 'Chatbot' plugin"
echo "  4. Configure chatbot settings:"
echo "     - API Endpoint: https://chatbot-api.${ADMIN_DOMAIN}/api/chat"
echo "     - Enable privacy consent"
echo "     - Customize appearance"
echo "  5. Structure policy content in Wiki.js:"
echo "     - Tag pages with 'policy-priority'"
echo "     - Use headings: '## Simple Explanation', '## Detailed Explanation'"
echo "  6. Sync Wiki.js content: curl -X POST https://wikijs-connector.${ADMIN_DOMAIN}/api/sync"
echo "  7. Test the chatbot on your website"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "  Setup Guide: chatbot-module/docs/README.md"
echo "  Kognetiks Configuration: chatbot-module/docs/KOGNETIKS.md"
echo "  Wiki.js Integration: chatbot-module/docs/WIKIJS_INTEGRATION.md"
echo "  CiviCRM Integration: chatbot-module/docs/CIVICRM_INTEGRATION.md"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "  ✓ Save CREDENTIALS_BACKUP.txt to password manager"
echo "  ✓ Delete file after saving: rm CREDENTIALS_BACKUP.txt"
echo "  ✓ Configure Wiki.js API key if not done already"
echo "  ✓ Set up cloud AI provider API keys for advanced features"
echo "  ✓ Review privacy settings and consent workflow"
echo ""
echo -e "${BLUE}Budget Management:${NC}"
echo "  Default monthly budget: \$100"
echo "  - Ollama (local): Free"
echo "  - OpenAI: \$30/month"
echo "  - Anthropic: \$50/month"
echo "  - Google: \$20/month"
echo "  Monitor costs: https://chatbot-api.${ADMIN_DOMAIN}/api/analytics/costs"
echo ""

print_success "Chatbot Module installation completed successfully!"
