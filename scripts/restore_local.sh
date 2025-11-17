#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 campaign_20251114_225216.tar.gz"
    exit 1
fi

BACKUP_FILE="/srv/backups/$1"
RESTORE_DIR="/srv/backups/restore_temp"
LOG_FILE="/srv/backups/restore_$(date +%Y%m%d_%H%M%S).log"

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERROR: Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "========================================" | tee "$LOG_FILE"
echo "Starting CiviCRM Campaign Restore" | tee -a "$LOG_FILE"
echo "Backup File: $BACKUP_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

echo "[1/4] Extracting backup..." | tee -a "$LOG_FILE"
mkdir -p "$RESTORE_DIR"
tar -xzf "$BACKUP_FILE" -C "$RESTORE_DIR" 2>> "$LOG_FILE"
echo "✓ Backup extracted" | tee -a "$LOG_FILE"

BACKUP_EXTRACTED=$(ls -d "$RESTORE_DIR"/campaign_* 2>/dev/null | head -1)

echo "[2/4] Restoring MySQL database..." | tee -a "$LOG_FILE"
docker compose stop wordpress 2>> "$LOG_FILE"
sleep 5

docker compose exec -T mysql mysql \
  -u wordpress_user \
  -p"wordpress_changeme_after_deploy_456" \
  wordpress_db < "$BACKUP_EXTRACTED/wordpress_db.sql" 2>> "$LOG_FILE"

echo "✓ Database restored" | tee -a "$LOG_FILE"

echo "[3/4] Restoring WordPress files..." | tee -a "$LOG_FILE"
docker exec wordpress rm -rf /var/www/html/* 2>> "$LOG_FILE" || true
docker cp "$BACKUP_EXTRACTED/wordpress_html/." wordpress_app:/var/www/html 2>> "$LOG_FILE"
echo "✓ WordPress files restored" | tee -a "$LOG_FILE"

echo "[4/4] Restarting containers..." | tee -a "$LOG_FILE"
docker compose start wordpress 2>> "$LOG_FILE"
sleep 15
echo "✓ Containers restarted successfully" | tee -a "$LOG_FILE"

rm -rf "$RESTORE_DIR"

echo "========================================" | tee -a "$LOG_FILE"
echo "Restore Complete!" | tee -a "$LOG_FILE"
echo "Log File: $LOG_FILE" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo ""
echo "Verify restore: Visit http://cwv.it.com/civicrm"

