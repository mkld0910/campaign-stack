#!/bin/bash
set -e

# Configuration
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/srv/backups/campaign_${BACKUP_DATE}"
LOG_FILE="/srv/backups/backup_${BACKUP_DATE}.log"

# Create directories
mkdir -p "$BACKUP_DIR"
mkdir -p /srv/backups

echo "========================================" | tee "$LOG_FILE"
echo "Starting CiviCRM Campaign Backup" | tee -a "$LOG_FILE"
echo "Backup Date: $BACKUP_DATE" | tee -a "$LOG_FILE"
echo "Backup Location: $BACKUP_DIR" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# 1. MySQL Database Backup
echo "[1/4] Backing up MySQL database..." | tee -a "$LOG_FILE"
docker compose exec -T mysql mysqldump \
  -u wordpress_user \
  -p"wordpress_changeme_after_deploy_456" \
  wordpress_db > "$BACKUP_DIR/wordpress_db.sql" 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    DB_SIZE=$(du -h "$BACKUP_DIR/wordpress_db.sql" | cut -f1)
    echo "✓ MySQL backup complete ($DB_SIZE)" | tee -a "$LOG_FILE"
else
    echo "✗ MySQL backup FAILED" | tee -a "$LOG_FILE"
    exit 1
fi

# 2. WordPress Files Backup
echo "[2/4] Backing up WordPress files..." | tee -a "$LOG_FILE"
docker cp wordpress_app:/var/www/html "$BACKUP_DIR/wordpress_html" 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    FILES_SIZE=$(du -sh "$BACKUP_DIR/wordpress_html" | cut -f1)
    echo "✓ WordPress files backup complete ($FILES_SIZE)" | tee -a "$LOG_FILE"
else
    echo "✗ WordPress files backup FAILED" | tee -a "$LOG_FILE"
    exit 1
fi

# 3. Configuration Backup
echo "[3/4] Backing up configuration..." | tee -a "$LOG_FILE"
cp .env "$BACKUP_DIR/.env" 2>> "$LOG_FILE"
cp compose.yaml "$BACKUP_DIR/compose.yaml" 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    echo "✓ Configuration backup complete" | tee -a "$LOG_FILE"
else
    echo "✗ Configuration backup FAILED" | tee -a "$LOG_FILE"
    exit 1
fi

# 4. Compress Backup
echo "[4/4] Compressing backup..." | tee -a "$LOG_FILE"
cd /srv/backups
tar -czf "campaign_${BACKUP_DATE}.tar.gz" "campaign_${BACKUP_DATE}" 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    COMPRESSED_SIZE=$(du -h "campaign_${BACKUP_DATE}.tar.gz" | cut -f1)
    echo "✓ Backup compressed ($COMPRESSED_SIZE)" | tee -a "$LOG_FILE"
    rm -rf "campaign_${BACKUP_DATE}"
    echo "✓ Temporary files cleaned up" | tee -a "$LOG_FILE"
else
    echo "✗ Compression FAILED" | tee -a "$LOG_FILE"
    exit 1
fi

# Summary
echo "========================================" | tee -a "$LOG_FILE"
echo "Backup Complete!" | tee -a "$LOG_FILE"
echo "Backup File: /srv/backups/campaign_${BACKUP_DATE}.tar.gz" | tee -a "$LOG_FILE"
echo "Log File: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# Record in manifest
echo "$BACKUP_DATE|campaign_${BACKUP_DATE}.tar.gz|$COMPRESSED_SIZE" >> /srv/backups/backup_manifest.txt

