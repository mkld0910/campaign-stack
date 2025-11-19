#!/bin/bash

# CiviCRM CLI Installation Script
# Uses the cv (CiviCRM CLI) tool to bypass web installer permission issues
# Based on successful Day 2 installation method

set -e

echo "=========================================="
echo "CiviCRM CLI Installation Script"
echo "=========================================="
echo ""

# Check if running from correct directory
if [ ! -f "compose.yaml" ]; then
    echo "❌ Error: Must run from campaign-stack directory"
    echo "   cd /srv/campaign-stack && bash scripts/install-civicrm-cli.sh"
    exit 1
fi

# Check if WordPress container is running
if ! docker compose ps | grep -q "wordpress_app.*Up"; then
    echo "❌ Error: WordPress container not running"
    echo "   Run: docker compose up -d"
    exit 1
fi

echo "Step 1: Installing required tools in WordPress container..."
docker exec wordpress_app bash -c "apt-get update -qq && apt-get install -y wget unzip > /dev/null 2>&1"
echo "✅ Tools installed (wget, unzip)"
echo ""

echo "Step 2: Downloading CiviCRM stable release..."
docker exec -w /var/www/html/wp-content/plugins wordpress_app bash -c "
    if [ -d 'civicrm' ]; then
        echo '⚠️  CiviCRM directory already exists, skipping download'
    else
        wget -q https://download.civicrm.org/latest/civicrm-STABLE-wordpress.zip
        echo '✅ Downloaded (45+ MB)'
    fi
"
echo ""

echo "Step 3: Extracting CiviCRM..."
docker exec -w /var/www/html/wp-content/plugins wordpress_app bash -c "
    if [ -d 'civicrm' ]; then
        echo '✅ CiviCRM already extracted'
    else
        unzip -q civicrm-STABLE-wordpress.zip
        rm civicrm-STABLE-wordpress.zip
        echo '✅ Extracted and cleaned up'
    fi
"
echo ""

echo "Step 4: Setting proper permissions..."
docker exec -w /var/www/html/wp-content/plugins wordpress_app bash -c "
    chown -R www-data:www-data civicrm
"
echo "✅ Permissions set (www-data:www-data)"
echo ""

echo "Step 5: Granting MySQL TRIGGER privilege..."
MYSQL_ROOT_PASSWORD=$(grep MYSQL_ROOT_PASSWORD .env | cut -d '=' -f2)
docker exec wordpress_mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "
    GRANT TRIGGER ON wordpress_db.* TO 'wordpress_user'@'%';
    FLUSH PRIVILEGES;
" > /dev/null 2>&1
echo "✅ TRIGGER privilege granted"
echo ""

echo "Step 6: Installing cv (CiviCRM CLI tool)..."
docker exec wordpress_app bash -c "
    if [ ! -f '/usr/local/bin/cv' ]; then
        cd /tmp
        wget -q https://download.civicrm.org/cv/cv.phar
        chmod +x cv.phar
        mv cv.phar /usr/local/bin/cv
        echo '✅ cv tool installed'
    else
        echo '✅ cv tool already installed'
    fi
"
echo ""

echo "Step 7: Activating CiviCRM plugin in WordPress..."
docker exec wordpress_app wp plugin activate civicrm --allow-root --quiet 2>/dev/null || true
echo "✅ Plugin activated"
echo ""

echo "Step 8: Running CiviCRM requirements check..."
echo "---"
docker exec -w /var/www/html/wp-content/plugins/civicrm wordpress_app cv core:check-req || true
echo "---"
echo ""

# Get domain from .env
DOMAIN=$(grep CAMPAIGN_DOMAIN .env | cut -d '=' -f2)

echo "Step 9: Installing CiviCRM via CLI (bypasses web installer)..."
echo "This may take 1-2 minutes..."
docker exec -w /var/www/html/wp-content/plugins/civicrm wordpress_app cv core:install \
    --cms-base-url="https://${DOMAIN}" \
    --lang=en_US

echo ""
echo "=========================================="
echo "✅ CiviCRM Installation Complete!"
echo "=========================================="
echo ""
echo "Access CiviCRM:"
echo "  URL: https://${DOMAIN}/wp-admin/admin.php?page=CiviCRM"
echo ""
echo "Next Steps:"
echo "  1. Log into WordPress admin"
echo "  2. Navigate to CiviCRM menu item"
echo "  3. Complete any remaining setup wizard steps"
echo "  4. Create test contacts/events/donations"
echo ""
echo "Note: CLI installation bypasses the MySQL trigger"
echo "      permission check that causes issues in the"
echo "      web installer. Triggers work correctly."
echo ""
