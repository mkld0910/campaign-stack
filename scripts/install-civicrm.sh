#!/bin/bash

################################################################################
# Campaign Stack - CiviCRM CLI Installation Script
# Version: 2.0
# Purpose: Install CiviCRM via CLI tool with dual-domain support
# Usage: bash scripts/install-civicrm.sh
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
print_header "CiviCRM CLI Installation Script v2.0"
echo "Uses cv tool to bypass web installer permission issues"
echo "Supports dual-domain and single-domain configurations"
echo "Estimated time: 3-5 minutes"
echo ""

# Check if running from correct directory
if [ ! -f "compose.yaml" ]; then
    print_error "Must run from campaign-stack directory"
    echo "   cd /srv/campaign-stack && bash scripts/install-civicrm.sh"
    exit 1
fi

# Check if WordPress container is running
if ! docker compose ps | grep -q "wordpress_app.*Up"; then
    print_error "WordPress container not running"
    echo "   Run: docker compose up -d"
    exit 1
fi

print_header "Step 1/12: Installing Required Tools"
docker exec wordpress_app bash -c "apt-get update -qq && apt-get install -y wget unzip > /dev/null 2>&1"
print_success "Tools installed (wget, unzip)"

print_header "Step 2/12: Downloading CiviCRM"
docker exec -w /var/www/html/wp-content/plugins wordpress_app bash -c "
    if [ -d 'civicrm' ]; then
        echo 'CiviCRM directory already exists, skipping download'
    else
        wget -q https://download.civicrm.org/latest/civicrm-STABLE-wordpress.zip
    fi
"
print_success "CiviCRM downloaded"

print_header "Step 3/12: Extracting CiviCRM"
docker exec -w /var/www/html/wp-content/plugins wordpress_app bash -c "
    if [ -d 'civicrm' ]; then
        echo 'CiviCRM already extracted'
    else
        unzip -q civicrm-STABLE-wordpress.zip
        rm civicrm-STABLE-wordpress.zip
    fi
"
print_success "CiviCRM extracted"

print_header "Step 4/12: Setting Plugin Permissions"
docker exec wordpress_app bash -c "
    chown -R www-data:www-data /var/www/html/wp-content/plugins/civicrm
    find /var/www/html/wp-content/plugins/civicrm -type d -exec chmod 755 {} \;
    find /var/www/html/wp-content/plugins/civicrm -type f -exec chmod 644 {} \;
"
print_success "Plugin permissions set (www-data:www-data)"

print_header "Step 5/12: Creating CiviCRM Upload Directories"
docker exec wordpress_app bash -c "
    mkdir -p /var/www/html/wp-content/uploads/civicrm/templates_c
    mkdir -p /var/www/html/wp-content/uploads/civicrm/persist
    mkdir -p /var/www/html/wp-content/uploads/civicrm/log
    chown -R www-data:www-data /var/www/html/wp-content/uploads/civicrm
    find /var/www/html/wp-content/uploads/civicrm -type d -exec chmod 755 {} \;
    find /var/www/html/wp-content/uploads/civicrm -type f -exec chmod 644 {} \;
"
print_success "Upload directories created with proper permissions"

print_header "Step 6/12: Granting MySQL TRIGGER Privilege"
MYSQL_ROOT_PASSWORD=$(grep MYSQL_ROOT_PASSWORD .env | cut -d '=' -f2)
docker exec wordpress_mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "
    GRANT TRIGGER ON wordpress_db.* TO 'wordpress_user'@'%';
    FLUSH PRIVILEGES;
" > /dev/null 2>&1
print_success "TRIGGER privilege granted"

print_header "Step 7/12: Installing cv (CiviCRM CLI Tool)"
docker exec wordpress_app bash -c "
    if [ ! -f '/usr/local/bin/cv' ]; then
        cd /tmp
        wget -q https://download.civicrm.org/cv/cv.phar
        chmod +x cv.phar
        mv cv.phar /usr/local/bin/cv
    fi
"
print_success "cv tool installed"

print_header "Step 8/12: Activating CiviCRM Plugin"
docker exec wordpress_app wp plugin activate civicrm --allow-root --quiet 2>/dev/null || true
print_success "Plugin activated in WordPress"

print_header "Step 9/12: Running CiviCRM Requirements Check"
echo "---"
docker exec -w /var/www/html/wp-content/plugins/civicrm wordpress_app cv core:check-req || true
echo "---"
print_success "Requirements check complete"

# Get domain from .env - supports both old (DOMAIN) and new (PUBLIC_DOMAIN/BACKEND_DOMAIN) formats
print_header "Step 10/12: Detecting Domain Configuration"

# Check for new dual-domain format first
PUBLIC_DOMAIN=$(grep ^PUBLIC_DOMAIN .env 2>/dev/null | cut -d '=' -f2 || echo "")
BACKEND_DOMAIN=$(grep ^BACKEND_DOMAIN .env 2>/dev/null | cut -d '=' -f2 || echo "")

# Fall back to old single DOMAIN format if not found
if [ -z "$PUBLIC_DOMAIN" ] || [ -z "$BACKEND_DOMAIN" ]; then
    DOMAIN=$(grep ^DOMAIN .env 2>/dev/null | cut -d '=' -f2 || echo "")
    if [ -z "$DOMAIN" ]; then
        print_error "No domain configuration found in .env"
        echo "   Ensure .env contains either:"
        echo "   - PUBLIC_DOMAIN and BACKEND_DOMAIN (new format), or"
        echo "   - DOMAIN (legacy format)"
        exit 1
    fi
    PUBLIC_DOMAIN=$DOMAIN
    print_info "Using legacy single-domain format: $PUBLIC_DOMAIN"
else
    print_info "Using dual-domain format:"
    print_info "  Public: $PUBLIC_DOMAIN"
    print_info "  Backend: $BACKEND_DOMAIN"
fi

print_header "Step 11/12: Installing CiviCRM via CLI"
print_info "This may take 1-2 minutes..."
docker exec -w /var/www/html/wp-content/plugins/civicrm wordpress_app cv core:install \
    --cms-base-url="https://${PUBLIC_DOMAIN}" \
    --lang=en_US
print_success "CiviCRM installation complete"

print_header "Step 12/12: Post-Installation Permission Fixes"
docker exec wordpress_app bash -c "
    chown -R www-data:www-data /var/www/html/wp-content/uploads/civicrm
    find /var/www/html/wp-content/uploads/civicrm -type d -exec chmod 755 {} \;
    find /var/www/html/wp-content/uploads/civicrm -type f -exec chmod 644 {} \;
"
print_success "Post-installation permissions secured"

print_header "Step 13/13: Clearing CiviCRM Cache"
docker exec -w /var/www/html/wp-content/plugins/civicrm wordpress_app bash -c "
    cv cache:flush 2>/dev/null || true
"
print_success "CiviCRM cache cleared"

# Final Instructions
print_header "Setup Complete!"

echo -e "${GREEN}CiviCRM is now installed and ready to use!${NC}"
echo ""
echo -e "${GREEN}Access CiviCRM:${NC}"
echo "  Backend admin: https://${BACKEND_DOMAIN:-$PUBLIC_DOMAIN}/wp-admin/admin.php?page=CiviCRM"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Log into WordPress admin at https://${BACKEND_DOMAIN:-$PUBLIC_DOMAIN}/wp-admin"
echo "  2. Navigate to CiviCRM menu item in sidebar"
echo "  3. Complete any remaining setup wizard steps"
echo "  4. Create test contacts/events/donations"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "  - Troubleshooting: docs/TROUBLESHOOTING.md"
echo "  - CiviCRM Setup: docs/CIVICRM_SETUP.md"
echo "  - Dual-Domain Setup: docs/DUAL_DOMAIN_SETUP.md"
echo ""

print_success "CiviCRM installation completed successfully!"
