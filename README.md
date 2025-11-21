# Campaign Stack

> Deploy a complete political campaign infrastructure on your own VPS in 30 minutes.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Quick Start
```bash
cd /srv
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
bash scripts/install-campaign-stack.sh
```

Answer a few questions, infrastructure is live in 15-30 minutes.

**Prefer a GUI?** See [web-installer/README.md](./web-installer/README.md) for the graphical installer.

## What's Included

- **WordPress** - Campaign website, blog, volunteer forms
- **CiviCRM** - Donor/volunteer/event management
- **Traefik** - Automatic HTTPS (Let's Encrypt), reverse proxy
- **MySQL** - Database
- **Automated Backups** - Daily to Storj cloud ($0/month)

## Cost

- **Hosting:** $25-40/month (VPS)
- **Software:** $0 (all open source)
- **Backups:** $0 (Storj free tier)
- **Total:** ~$30-40/month

## Requirements

- VPS with Ubuntu 22.04 or 24.04 LTS
- 2+ CPU cores, 4GB+ RAM, 80GB+ SSD
- Domain name pointing to VPS IP

## Installation

### 1. Provision VPS

Any provider: A2Hosting, DigitalOcean, Linode
- OS: Ubuntu 22.04 or 24.04 LTS
- CPU: 2+ cores
- RAM: 4GB minimum
- Storage: 80GB SSD
- Cost: $25-40/month

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

### 4. Run Installer
```bash
bash scripts/install-campaign-stack.sh
```

### 5. Complete WordPress Setup

Visit `https://yourdomain.com` and complete initial setup.

### 6. Install CiviCRM

See [docs/CIVICRM_SETUP.md](./docs/CIVICRM_SETUP.md)

### 7. Configure Backups

See [docs/BACKUP.md](./docs/BACKUP.md)

## Documentation

| Guide | Purpose |
|-------|---------|
| [README.md](./README.md) | Quick start |
| [docs/SETUP.md](./docs/SETUP.md) | Detailed walkthrough |
| [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) | Common errors & fixes |
| [docs/BACKUP.md](./docs/BACKUP.md) | Backup configuration |
| [docs/CIVICRM_SETUP.md](./docs/CIVICRM_SETUP.md) | CiviCRM installation |
| [web-installer/README.md](./web-installer/README.md) | GUI installer guide |
| [docs/architecture/](./docs/architecture/) | Architecture & design docs |
| [CREDITS.md](./CREDITS.md) | Full acknowledgments |

## Troubleshooting

### Can't access website?
- Wait 1-2 minutes for SSL certificate
- Check DNS: `nslookup yourdomain.com`
- View logs: `docker-compose logs`

See [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md) for detailed help.

## For Other Candidates

### Fork This Repo

1. Click "Fork" on GitHub
2. Clone your fork
3. Deploy!

Send your fork URL to your team - they can deploy in 30 minutes.

## FAQ

**Q: How much does this cost?**
A: ~$30-40/month for hosting. All software is free.

**Q: Can I customize this?**
A: Yes! Fork the repo and edit docker-compose.yml.

**Q: What if something breaks?**
A: You have automated backups. Restore in 15-30 minutes.

**Q: Is this secure?**
A: Yes, HTTPS by default. Passwords never committed to git (.gitignore protects .env).

## Installation Options

### Option 1: Command Line (Recommended for Technical Users)
```bash
cd /srv/campaign-stack
bash scripts/install-campaign-stack.sh
```

### Option 2: Web-Based GUI (For Everyone Else)
```bash
cd /srv/campaign-stack/web-installer
php -S 0.0.0.0:8888
```
Then visit `http://YOUR_VPS_IP:8888` in your browser for a user-friendly installation wizard.

See [web-installer/README.md](./web-installer/README.md) for details.

## License

MIT License - See [LICENSE](./LICENSE) file

## Credits & Acknowledgments

Campaign Stack is built on the shoulders of extraordinary open-source projects:

- **WordPress** - CMS powering the website
- **CiviCRM** - Constituent relationship management
- **Docker & Docker Compose** - Container infrastructure
- **Traefik** - Reverse proxy with automatic HTTPS
- **MySQL** - Database system
- **Let's Encrypt** - Free SSL/TLS certificates
- **Storj** - Decentralized backup storage
- **Christian Lempa** - Docker infrastructure patterns and best practices
- **Claude AI (Anthropic)** - Development assistance and documentation

Special thanks to all open-source maintainers and the global community of developers building tools for civic engagement.

For the complete list of acknowledgments and how to contribute, see **[CREDITS.md](./CREDITS.md)**

---

Built with ❤️ for political campaigns and civic engagement

