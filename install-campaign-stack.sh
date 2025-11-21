#!/bin/bash

################################################################################
# Campaign Stack - One-Command Installer (Provider-Agnostic)
# Version: 2.2 (Multi-AI Provider Support)
# Purpose: Deploy WordPress + CiviCRM + Traefik + Choice of AI Provider
# Usage: bash scripts/install-campaign-stack.sh
# 
# This script will:
# - Check for/install Docker and Docker Compose
# - Prompt for domain and email configuration
# - Generate secure database passwords
# - Let user choose preferred AI provider (optional)
# - Deploy all services
# - Verify everything is running
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

# Main Installation
print_header "Campaign Stack Installer v2.2"
echo "Deploy WordPress + CiviCRM + Traefik with choice of AI Provider"
echo "Estimated time: 20-30 minutes (+ 5 min if installing AI CLI)"
echo ""

# Prerequisites Check & Installation
print_header "Step 1/7: Checking & Installing Prerequisites"

# Check and install Docker
if ! command -v docker &> /dev/null; then
    print_info "Docker not found. Installing Docker..."
    curl -sSL https://get.docker.com | sh
    print_success "Docker installed"
else
    print_success "Docker already installed: $(docker --version)"
fi

# Check and install Docker Compose (v2)
if ! docker compose version &> /dev/null; then
    print_warning "Docker Compose V2 not found. Attempting install..."

    # Get latest version
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)

    # Install Docker Compose V2 plugin
    mkdir -p ~/.docker/cli-plugins/
    curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
        -o ~/.docker/cli-plugins/docker-compose
    chmod +x ~/.docker/cli-plugins/docker-compose

    print_success "Docker Compose V2 installed"
else
    print_success "Docker Compose already installed: $(docker compose version)"
fi

# Verify both work
if ! docker --version &> /dev/null; then
    print_error "Docker not working. Try: sudo systemctl restart docker"
    exit 1
fi

if ! docker ps &> /dev/null; then
    print_warning "Docker access issue. Adding current user to docker group..."
    sudo usermod -aG docker $USER
    print_info "Please run: newgrp docker"
    print_info "Then re-run this installer"
    exit 1
fi

# Gather User Input
print_header "Step 2/7: Configure Your Campaign"

echo "Configure how your site will be accessed:"
echo ""
echo "Option 1: Single Domain (default)"
echo "  Same domain for public site + admin"
echo "  Example: markcampaign.com"
echo ""
echo "Option 2: Dual Domain (advanced)"
echo "  Separate public site + admin backend"
echo "  Example: Public=markcampaign.com, Admin=cwv.it.com"
echo ""

read -p "Use dual domain setup? (y/n, default=n): " -n 1 -r
echo
DUAL_DOMAIN=false
if [[ $REPLY =~ ^[Yy]$ ]]; then
    DUAL_DOMAIN=true
fi

if [ "$DUAL_DOMAIN" = true ]; then
    read -p "Enter PUBLIC domain (what visitors see): " PUBLIC_DOMAIN
    while [ -z "$PUBLIC_DOMAIN" ]; do
        print_error "Domain cannot be empty"
        read -p "Enter PUBLIC domain: " PUBLIC_DOMAIN
    done
    
    read -p "Enter BACKEND domain (admin interface): " BACKEND_DOMAIN
    while [ -z "$BACKEND_DOMAIN" ]; do
        print_error "Domain cannot be empty"
        read -p "Enter BACKEND domain: " BACKEND_DOMAIN
    done
    
    DOMAIN=$PUBLIC_DOMAIN
    print_success "Dual domain configured:"
    echo "  Public:  $PUBLIC_DOMAIN"
    echo "  Backend: $BACKEND_DOMAIN"
else
    read -p "Enter domain name (e.g., markcampaign.com): " DOMAIN
    while [ -z "$DOMAIN" ]; do
        print_error "Domain cannot be empty"
        read -p "Enter domain name: " DOMAIN
    done
    
    PUBLIC_DOMAIN=$DOMAIN
    BACKEND_DOMAIN=$DOMAIN
    print_success "Single domain configured: $DOMAIN"
fi

echo ""

read -p "Enter contact email (for SSL certificates): " EMAIL
if [ -z "$EMAIL" ]; then
    print_error "Email cannot be empty"
    exit 1
fi
print_success "Email configured: $EMAIL"

print_info "Generating secure passwords..."
MYSQL_ROOT_PASS=$(openssl rand -base64 12)
MYSQL_USER_PASS=$(openssl rand -base64 12)
print_success "Secure passwords generated"

# AI Provider Selection (Provider-Agnostic)
print_header "Step 3/7: Choose Your AI Provider (Optional)"

echo "Select your preferred AI provider for terminal coding:"
echo ""
echo "1. Anthropic Claude (Default)"
echo "   - Most capable, good for complex tasks"
echo "   - Cost: ~$3-15 per 1M tokens"
echo ""
echo "2. OpenAI ChatGPT"
echo "   - Powerful, widely used"
echo "   - Cost: ~$0.50-60 per 1M tokens"
echo ""
echo "3. Google Gemini"
echo "   - Cost-effective, efficient"
echo "   - Cost: ~$0.25-0.50 per 1M tokens (CHEAPEST)"
echo ""
echo "4. Local Ollama (Free & Offline)"
echo "   - Run models locally, NO API key needed"
echo "   - Cost: FREE, works offline"
echo "   - Models: Mistral, Llama 2, Neural Chat"
echo ""
echo "5. Skip AI provider"
echo "   - Don't install any AI CLI tool"
echo "   - Can add later anytime"
echo ""

read -p "Choose provider (1-5, default=5): " -n 1 PROVIDER_CHOICE
echo
PROVIDER_CHOICE=${PROVIDER_CHOICE:-5}

PRIMARY_AI_PROVIDER=""
ANTHROPIC_API_KEY=""
OPENAI_API_KEY=""
GOOGLE_API_KEY=""
OLLAMA_BASE_URL=""
INSTALL_AI_PROVIDER=false

case $PROVIDER_CHOICE in
  1)
    PRIMARY_AI_PROVIDER="anthropic"
    INSTALL_AI_PROVIDER=true
    echo ""
    echo "Anthropic Claude selected"
    echo "Get your API key from: https://console.anthropic.com/api-keys"
    echo ""
    read -s -p "Enter Anthropic API key (sk-ant-...): " ANTHROPIC_API_KEY
    echo ""
    if [[ ! $ANTHROPIC_API_KEY =~ ^sk-ant- ]]; then
        print_warning "Anthropic API keys typically start with 'sk-ant-'. Verify in console."
    fi
    print_success "Anthropic configured"
    ;;
  2)
    PRIMARY_AI_PROVIDER="openai"
    INSTALL_AI_PROVIDER=true
    echo ""
    echo "OpenAI ChatGPT selected"
    echo "Get your API key from: https://platform.openai.com/api-keys"
    echo ""
    read -s -p "Enter OpenAI API key (sk-...): " OPENAI_API_KEY
    echo ""
    if [[ ! $OPENAI_API_KEY =~ ^sk- ]]; then
        print_warning "API key should start with 'sk-'. Verify in console."
    fi
    print_success "OpenAI configured"
    ;;
  3)
    PRIMARY_AI_PROVIDER="google"
    INSTALL_AI_PROVIDER=true
    echo ""
    echo "Google Gemini selected"
    echo "Get your API key from: https://ai.google.dev/tutorials/setup"
    echo ""
    read -s -p "Enter Google API key: " GOOGLE_API_KEY
    echo ""
    print_success "Google Gemini configured"
    ;;
  4)
    PRIMARY_AI_PROVIDER="ollama"
    INSTALL_AI_PROVIDER=true
    echo ""
    echo "Local Ollama selected (FREE)"
    print_info "Ollama will download and run models locally"
    print_info "First run may take a few minutes to download model"
    OLLAMA_BASE_URL="http://localhost:11434"
    print_success "Ollama configured (local only)"
    ;;
  5)
    print_info "Skipping AI provider installation"
    INSTALL_AI_PROVIDER=false
    ;;
  *)
    print_warning "Invalid choice, skipping AI provider"
    INSTALL_AI_PROVIDER=false
    ;;
esac

# Create Environment File
print_header "Step 4/7: Setting Up Environment"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

mkdir -p "$REPO_DIR/backups"
mkdir -p "$REPO_DIR/wordpress_data"
mkdir -p "$REPO_DIR/mysql_data"
mkdir -p "$REPO_DIR/scripts"

# Create .env file with provider-agnostic AI configuration
cat > "$REPO_DIR/.env" << EOF_ENV
# Campaign Stack Configuration
# Generated: $(date)

# Domain Configuration
PUBLIC_DOMAIN=${PUBLIC_DOMAIN}
BACKEND_DOMAIN=${BACKEND_DOMAIN}
DOMAIN=${DOMAIN}

# SSL/TLS Configuration
LETSENCRYPT_EMAIL=${EMAIL}

# MySQL Configuration
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASS}
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=${MYSQL_USER_PASS}
MYSQL_DATABASE=wordpress_db

# ============================================================================
# AI PROVIDER CONFIGURATION (Provider-Agnostic)
# ============================================================================
# Primary AI provider: anthropic, openai, google, ollama, or none
PRIMARY_AI_PROVIDER=${PRIMARY_AI_PROVIDER}

# Anthropic Claude API
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}

# OpenAI ChatGPT API
OPENAI_API_KEY=${OPENAI_API_KEY}

# Google Gemini API
GOOGLE_API_KEY=${GOOGLE_API_KEY}

# Local Ollama (no key needed)
OLLAMA_BASE_URL=${OLLAMA_BASE_URL}

# Backup Configuration
STORJ_ACCESS_GRANT=
STORJ_BUCKET=campaign-backups-production

# Environment
ENVIRONMENT=production
DEBUG=false
EOF_ENV

print_success ".env file created"

# Save credentials backup
cat > "$REPO_DIR/CREDENTIALS_BACKUP.txt" << EOF_CREDS
=== CAMPAIGN STACK CREDENTIALS ===
Generated: $(date)

Domain Configuration:
  Public Domain: ${PUBLIC_DOMAIN}
  Backend Domain: ${BACKEND_DOMAIN}
  Dual Domain Mode: ${DUAL_DOMAIN}

Email: ${EMAIL}

MySQL Credentials:
  Root Password: ${MYSQL_ROOT_PASS}
  Database User: wordpress_user
  User Password: ${MYSQL_USER_PASS}
  Database Name: wordpress_db

AI Provider Configuration:
  Primary Provider: ${PRIMARY_AI_PROVIDER}
  (API keys stored in .env)

IMPORTANT - SAVE THIS SECURELY:
1. Copy ALL credentials to your password manager (Bitwarden, 1Password, etc.)
2. Delete this file from the server: rm CREDENTIALS_BACKUP.txt
3. Never commit .env to git or share publicly
4. Store in secure location for recovery

Credentials will be loaded from .env for future use.
EOF_CREDS

print_warning "Credentials saved to CREDENTIALS_BACKUP.txt"
print_warning "IMPORTANT: Save these to password manager, then delete file"

# Deploy Services
print_header "Step 5/7: Deploying Docker Services"

cd "$REPO_DIR"

print_info "Pulling Docker images (this may take a few minutes)..."

# Pull images based on whether AI provider is enabled
if [ "$INSTALL_AI_PROVIDER" = true ]; then
    print_info "AI provider enabled - pulling AI container image..."
    docker compose --profile ai pull
else
    # Pull core services only (ai_provider has profiles so it's excluded automatically)
    print_info "Pulling core services (excluding AI provider)..."
    docker compose pull
fi

print_info "Starting services..."

# Start services with or without AI container based on user choice
if [ "$INSTALL_AI_PROVIDER" = true ]; then
    print_header "Step 6/7: Deploying AI Provider Container"
    print_info "Starting all services including containerized AI..."
    docker compose --profile ai up -d

    print_success "AI provider container deployed"
    print_info "Provider: $PRIMARY_AI_PROVIDER"
    print_info "Access AI container: docker exec -it ai_provider /bin/bash"
    print_info "AI has access to VPS files via Docker volumes"
else
    docker compose up -d
fi

print_info "Waiting for services to initialize..."
sleep 30

# Set verification step based on whether AI was enabled
if [ "$INSTALL_AI_PROVIDER" = true ]; then
    VERIFICATION_STEP=7
else
    VERIFICATION_STEP=6
fi

# Verify Deployment
print_header "Step $VERIFICATION_STEP/$((VERIFICATION_STEP)): Verifying Deployment"

if docker compose ps | grep -q "Up"; then
    print_success "Docker services running"
else
    print_error "Some services failed to start"
    print_info "Run: docker compose logs"
    docker compose logs
    exit 1
fi

# Count running services
RUNNING=$(docker compose ps | grep -c "Up" || true)
TOTAL=$(docker compose config --services | wc -l)

if [ "$RUNNING" -ge "$TOTAL" ]; then
    print_success "Traefik proxy running"
    print_success "WordPress container running"
    print_success "MySQL database running"
    print_success "All services verified"
else
    print_warning "Some services still starting. Check status: docker compose ps"
fi

# Final Instructions
print_header "Setup Complete!"

echo "Your campaign infrastructure is now live!"
echo ""
echo -e "${GREEN}Access Points:${NC}"
if [ "$DUAL_DOMAIN" = true ]; then
    echo "  Public Site: https://${PUBLIC_DOMAIN}"
    echo "  WordPress Admin: https://${BACKEND_DOMAIN}/wp-admin"
else
    echo "  Website: https://${DOMAIN}"
    echo "  WordPress Admin: https://${DOMAIN}/wp-admin"
fi
echo "  Portainer (containers): http://${HOSTNAME}:9000 (or your VPS IP:9000)"

if [ "$INSTALL_AI_PROVIDER" = true ]; then
    echo "  AI Provider: $PRIMARY_AI_PROVIDER (Ready to use)"
fi

echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "  1. ✓ Infrastructure deployed"
echo "  2. → Wait 1-2 minutes for SSL certificate (Let's Encrypt)"
echo "  3. → Visit your site to verify it's working"
echo "  4. → Run CiviCRM installer: bash scripts/install-civicrm.sh"
echo "  5. → Complete WordPress setup (see CONFIGURATION.md)"
echo "  6. → Configure email (see docs/03-CONFIGURATION.md)"
echo "  7. → Setup backups (see docs/09-BACKUP.md)"

if [ "$INSTALL_AI_PROVIDER" = true ]; then
    echo ""
    echo -e "${GREEN}AI Provider Container Deployed:${NC}"
    echo "  Provider: $PRIMARY_AI_PROVIDER"
    echo "  Container: ai_provider"
    echo ""
    echo "  Access AI container:"
    echo "    docker exec -it ai_provider /bin/bash"
    echo ""
    echo "  The AI container has access to:"
    echo "    - /app/docs (for AI-generated documentation)"
    echo "    - /app/workspace/wordpress (your WordPress files)"
    echo "    - .env file with API keys"
    echo ""
    echo "  Available commands inside container:"
    case $PRIMARY_AI_PROVIDER in
      anthropic)
        echo "    claude         - Start Anthropic Claude Code session"
        ;;
      openai)
        echo "    chatgpt        - Start OpenAI ChatGPT session"
        ;;
      google)
        echo "    google-ai      - Start Google Gemini session"
        ;;
      ollama)
        echo "    ollama run mistral - Start local Mistral model"
        ;;
    esac
fi

echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "  ✓ Save CREDENTIALS_BACKUP.txt contents to password manager NOW"
echo "  ✓ Then delete file: rm CREDENTIALS_BACKUP.txt"
echo "  ✓ Never commit .env to git"
if [ "$DUAL_DOMAIN" = true ]; then
    echo "  ✓ Whitelist both domains in security plugins"
fi
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "  Quick Start:        docs/01-QUICKSTART.md"
echo "  Installation:       docs/02-INSTALLATION.md"
echo "  Configuration:      docs/03-CONFIGURATION.md"
echo "  Troubleshooting:    docs/04-TROUBLESHOOTING.md"
echo "  Architecture:       docs/06-ARCHITECTURE.md"
echo "  Operations:         docs/08-OPERATIONS.md"
echo "  AI Providers:       docs/13-AI-PROVIDERS.md"
echo ""

print_success "Deployment completed successfully!"
echo ""
print_info "SSL certificate generation can take 2-5 minutes..."
print_info "Your site will be available once certificate is ready"

if [ "$INSTALL_AI_PROVIDER" = true ]; then
    echo ""
    print_info "AI Provider container is running and ready"
    print_info "Container has access to VPS files for making changes"
    echo "To access: docker exec -it ai_provider /bin/bash"
fi
