#!/bin/bash
set -e
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/srv/campaign-stack/backups/campaign_${BACKUP_DATE}"
mkdir -p $BACKUP_DIR
echo "=== Starting backup at $(date) ===" | tee -a /var/log/campaign-backup.log
echo "Backing up MySQL database..." | tee -a /var/log/campaign-backup.log
docker exec wordpress_mysql mysqldump -u root -proot_changeme_after_deploy_123 wordpress_db > $BACKUP_DIR/mysql_dump.sql
echo "Backing up WordPress files..." | tee -a /var/log/campaign-backup.log
docker cp wordpress_app:/var/www/html $BACKUP_DIR/wordpress_files
echo "Compressing backup..." | tee -a /var/log/campaign-backup.log
tar czf $BACKUP_DIR.tar.gz -C /srv/campaign-stack/backups campaign_${BACKUP_DATE}
rm -rf $BACKUP_DIR
echo "Uploading to Storj..." | tee -a /var/log/campaign-backup.log
uplink cp --access my-campaign-backup $BACKUP_DIR.tar.gz sj://campaign-backups-production/
echo "✓ Backup complete at $(date)" | tee -a /var/log/campaign-backup.log
