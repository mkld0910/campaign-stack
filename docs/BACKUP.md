# Backup Configuration Guide

## Quick Start

Your infrastructure automatically backs up daily at 2 AM to Storj cloud.

**No action needed!** But verify it works:
```bash
# Check backup logs
tail -f /var/log/campaign-backup.log

# List backups in Storj
uplink ls --access my-campaign-backup sj://campaign-backups-production/
```

## Full Setup Instructions

See the main documentation for complete Storj backup setup.

## Restore Procedure

If your VPS fails, restore your backup:
```bash
./restore_from_storj.sh campaign_YYYYMMDD_HHMMSS
```

Estimated time: 15-30 minutes

## Backup Verification

**Test weekly that backups work:**
```bash
# Check last backup timestamp
ls -lah /srv/campaign-stack/backups/ | head -5

# Check Storj has recent backups
uplink ls --access my-campaign-backup sj://campaign-backups-production/ | tail -5
```

