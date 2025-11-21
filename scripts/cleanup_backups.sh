#!/bin/bash

KEEP_COUNT=7
BACKUP_DIR="/srv/backups"

echo "Cleaning up old backups (keeping last $KEEP_COUNT)..."

BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/campaign_*.tar.gz 2>/dev/null | wc -l)

if [ $BACKUP_COUNT -le $KEEP_COUNT ]; then
    echo "Only $BACKUP_COUNT backups exist. Keeping all."
    exit 0
fi

DELETE_COUNT=$((BACKUP_COUNT - KEEP_COUNT))
echo "Found $BACKUP_COUNT backups. Deleting oldest $DELETE_COUNT..."

ls -1t "$BACKUP_DIR"/campaign_*.tar.gz | tail -n $DELETE_COUNT | while read backup; do
    echo "Deleting: $(basename $backup)"
    rm -f "$backup"
done

echo "Cleanup complete"
echo ""
echo "Remaining backups:"
ls -lh "$BACKUP_DIR"/campaign_*.tar.gz

