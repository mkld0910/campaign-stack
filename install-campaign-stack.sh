#!/bin/bash

################################################################################
# Campaign Stack - One-Command Installer
# Version: 1.0
# Purpose: Deploy WordPress + CiviCRM + Traefik + Automated Backups
# Usage: bash install-campaign-stack.sh
################################################################################

set -e

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
print_header "Campaign Stack Installer v1.0"
echo "Deploy WordPress + CiviCRM + Traefik + Backups"
echo "Estimated time: 15-30 minutes"
echo ""

# Prerequisites Check & Installation
print_header "Step 1/6: Checking & Installing Prerequisites"

# Check and install Docker
if ! command -v docker &> /dev/null; then
    print_info "Docker not found. Installing Docker..."
    curl -sSL https://get.docker.com | sh
    print_success "Docker installed"
else
    print_success "Docker already installed"
fi

# Check and install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_info "Docker Compose not found. Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed"
else
    print_success "Docker Compose already installed"
fi

# Verify both work
if ! docker --version &> /dev/null; then
    print_error "Docker installation failed"
    exit 1
fi

if ! docker-compose --version &> /dev/null; then
    print_error "Docker Compose installation failed"
    exit 1
fi

# Optional: Uplink CLI for backups
if ! command -v uplink &> /dev/null; then
    print_warning "Uplink CLI not found. Backups to Storj will not work until installed."
    print_info "Install after deployment: See docs/BACKUP.md"
else
    print_success "Uplink CLI installed"
fi

# Gather User Input
print_header "Step 2/6: Configure Your Campaign"

read -p "Enter campaign domain (e.g., mycampaign.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    print_error "Domain cannot be empty"
    exit 1
fi

read -p "Enter contact email (for SSL certificates): " EMAIL
if [ -z "$EMAIL" ]; then
    print_error "Email cannot be empty"
    exit 1
fi

print_info "Generating secure passwords..."
MYSQL_ROOT_PASS=$(openssl rand -base64 12)
MYSQL_USER_PASS=$(openssl rand -base64 12)

print_success "Configuration complete"

# Create Environment File
print_header "Step 3/6: Setting Up Environment"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$SCRIPT_DIR/backups"
mkdir -p "$SCRIPT_DIR/wordpress_data"
mkdir -p "$SCRIPT_DIR/mysql_data"

# Create .env file
cat > "$SCRIPT_DIR/.env" << EOF_ENV
# Campaign Stack Configuration
DOMAIN=$DOMAIN
LETSENCRYPT_EMAIL=$EMAIL

# MySQL Configuration
MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASS
MYSQL_USER=wordpress_user
MYSQL_PASSWORD=$MYSQL_USER_PASS
MYSQL_DATABASE=wordpress_db

# Backup Configuration
STORJ_ACCESS_GRANT=
STORJ_BUCKET=campaign-backups-production
EOF_ENV

print_success ".env file created"

# Save credentials backup
cat > "$SCRIPT_DIR/CREDENTIALS_BACKUP.txt" << EOF_CREDS
=== CAMPAIGN STACK CREDENTIALS ===
Generated: $(date)
Domain: $DOMAIN
Email: $EMAIL

MySQL Root Password: $MYSQL_ROOT_PASS
MySQL User: wordpress_user
MySQL User Password: $MYSQL_USER_PASS

SAVE THIS FILE SECURELY:
1. Copy contents to password manager (Bitwarden, 1Password, etc.)
2. Delete this file from server: rm CREDENTIALS_BACKUP.txt
3. Never commit to git
EOF_CREDS

print_warning "Credentials saved to CREDENTIALS_BACKUP.txt"
print_warning "IMPORTANT: Save to password manager, then delete file"

# Deploy Services
print_header "Step 4/6: Deploying Services"

cd "$SCRIPT_DIR"

print_info "Pulling Docker images..."
docker-compose pull

print_info "Starting services..."
docker-compose up -d

print_info "Waiting for services to initialize..."
sleep 30

# Verify Deployment
print_header "Step 5/6: Verifying Deployment"

if docker-compose ps | grep -q "Up"; then
    print_success "Docker services running"
else
    print_error "Some services failed to start"
    docker-compose logs
    exit 1
fi

# Count running services
RUNNING=$(docker-compose ps | grep -c "Up" || true)
TOTAL=$(docker-compose config --services | wc -l)

if [ "$RUNNING" -ge "$TOTAL" ]; then
    print_success "WordPress container running"
    print_success "MySQL container running"
    print_success "All services verified running"
else
    print_warning "Some services may still be starting. Check with: docker-compose ps"
fi

# Final Instructions
print_header "Step 6/6: Setup Complete!"

echo "Your campaign infrastructure is now live!"
echo ""
echo -e "${GREEN}Access Points:${NC}"
echo "  Website: https://$DOMAIN"
echo "  WordPress Admin: https://$DOMAIN/wp-admin"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Wait 1-2 minutes for SSL certificate (Let's Encrypt)"
echo "  2. Visit https://$DOMAIN to complete WordPress setup"
echo "  3. Install CiviCRM plugin (see docs/CIVICRM_SETUP.md)"
echo "  4. Configure Storj backups (see docs/BACKUP.md)"
echo ""
echo -e "${YELLOW}Important:${NC}"
echo "  - Save credentials to password manager"
echo "  - Delete CREDENTIALS_BACKUP.txt from server"
echo "  - Never commit .env to git"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "  - Quick Start: README.md"
echo "  - Setup Guide: docs/SETUP.md"
echo "  - Troubleshooting: docs/TROUBLESHOOTING.md"
echo "  - Backups: docs/BACKUP.md"
echo ""

print_success "Deployment completed successfully!"
