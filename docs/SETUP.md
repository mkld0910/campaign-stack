# Detailed Setup Guide

## Prerequisites

- Ubuntu 22.04 or 24.04 LTS VPS
- 2+ CPU cores
- 4GB+ RAM
- 80GB+ SSD storage
- Domain name (DNS configured)

## Step-by-Step Installation

### 1. Provision VPS (5 minutes)

Choose provider: A2Hosting, DigitalOcean, Linode, etc.
- Select Ubuntu 22.04 or 24.04 LTS
- Note your VPS IP address

### 2. SSH Into VPS
```bash
ssh root@YOUR_VPS_IP
```

### 3. Clone Repository
```bash
cd /srv
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
```

### 4. Run Installer (15-20 minutes)
```bash
bash install-campaign-stack.sh
```

### 5. Complete WordPress Setup (10 minutes)

Visit `https://yourdomain.com`
- Set site title
- Create admin account
- Configure timezone

### 6. Install CiviCRM (20 minutes)

See docs/CIVICRM_SETUP.md

### 7. Configure Backups (10 minutes)

See docs/BACKUP.md

**Total Time:** 30-60 minutes

## Verification

After installation:
```bash
# Check all services running
docker-compose ps

# Test HTTPS
curl -I https://yourdomain.com

# Test WordPress admin
curl -I https://yourdomain.com/wp-admin
```

