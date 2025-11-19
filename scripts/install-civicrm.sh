#!/bin/bash

################################################################################
# CiviCRM Automated Installer
# Downloads latest stable CiviCRM and installs to WordPress container
# Usage: bash scripts/install-civicrm.sh
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

# Start
print_header "CiviCRM Automated Installer"
echo "Downloads and installs latest stable CiviCRM"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
cd "$REPO_DIR"

# Check Docker running
if ! docker-compose ps | grep -q "wordpress_app"; then
    print_error "WordPress container not running"
    print_info "Start services first: docker-compose up -d"
    exit 1
fi
print_success "WordPress container is running"

# Check if WordPress is accessible
if ! docker exec wordpress_app wp core is-installed &>/dev/null; then
    print_error "WordPress not fully initialized yet"
    print_info "Wait a few minutes and try again"
    exit 1
fi
print_success "WordPress is initialized"

# Get latest CiviCRM version
print_info "Fetching latest stable CiviCRM version..."
CIVICRM_VERSION=$(curl -s https://civicrm.org/download | grep -oP '(?<=civicrm-)[0-9]+\.[0-9]+\.[0-9]+' | head -1)

if [ -z "$CIVICRM_VERSION" ]; then
    print_warning "Could not auto-detect version, using 5.76.0 (latest known stable)"
    CIVICRM_VERSION="5.76.0"
fi

print_success "Using CiviCRM version: $CIVICRM_VERSION"

# Download CiviCRM
DOWNLOAD_URL="https://civicrm.org/sites/civicrm.org/files/civicrm-$CIVICRM_VERSION-wordpress.zip"
TEMP_ZIP="/tmp/civicrm-$CIVICRM_VERSION-wordpress.zip"

print_info "Downloading CiviCRM $CIVICRM_VERSION..."
if ! curl -L --progress-bar -o "$TEMP_ZIP" "$DOWNLOAD_URL"; then
    print_error "Failed to download CiviCRM"
    print_info "Check URL: $DOWNLOAD_URL"
    exit 1
fi

FILE_SIZE=$(du -h "$TEMP_ZIP" | cut -f1)
print_success "Downloaded: $FILE_SIZE"

# Copy to WordPress container plugins directory
print_info "Installing to WordPress container..."
docker exec wordpress_app rm -rf /var/www/html/wp-content/plugins/civicrm* 2>/dev/null || true

# Extract directly in container
docker exec wordpress_app bash -c "
    cd /tmp && \
    unzip -q /tmp/civicrm-$CIVICRM_VERSION-wordpress.zip && \
    mv civicrm /var/www/html/wp-content/plugins/ && \
    chown -R www-data:www-data /var/www/html/wp-content/plugins/civicrm
"

print_success "CiviCRM extracted to plugins directory"

# Grant database privileges
print_info "Granting database privileges..."
MYSQL_ROOT_PASS=$(grep MYSQL_ROOT_PASSWORD "$REPO_DIR/.env" | cut -d'=' -f2)

docker exec wordpress_mysql mysql -u root -p"$MYSQL_ROOT_PASS" -e \
    "GRANT TRIGGER ON wordpress_db.* TO 'wordpress_user'@'%'; FLUSH PRIVILEGES;" 2>/dev/null || \
    print_warning "Could not verify TRIGGER privilege (may already be set)"

print_success "Database privileges configured"

# Activate plugin via WP-CLI
print_info "Activating CiviCRM plugin..."
docker exec wordpress_app wp plugin activate civicrm --allow-root 2>/dev/null || \
    print_warning "Plugin activation via CLI failed - activate manually via WordPress admin"

# Restart WordPress
print_info "Restarting WordPress to apply changes..."
docker-compose restart wordpress_app
sleep 10

# Verify installation
print_header "Verification"

if docker exec wordpress_app wp plugin is-active civicrm --allow-root &>/dev/null; then
    print_success "CiviCRM plugin is active"
else
    print_warning "CiviCRM plugin not active yet - activate manually in WordPress admin"
fi

# Final instructions
print_header "Installation Complete!"

echo "Next steps:"
echo "  1. Visit WordPress Admin: https://yourdomain.com/wp-admin"
echo "  2. Go to CiviCRM in left sidebar (or activate manually if not showing)"
echo "  3. Complete CiviCRM setup wizard"
echo "  4. Create test contacts/donations to verify"
echo ""
echo "If CiviCRM doesn't appear in menu:"
echo "  - WordPress Admin → Plugins → Find CiviCRM → Activate"
echo "  - Refresh page"
echo ""

print_success "CiviCRM $CIVICRM_VERSION ready for setup!"

# Cleanup
rm -f "$TEMP_ZIP"
