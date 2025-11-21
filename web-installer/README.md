# Campaign Stack - Web Installer

A simple, user-friendly GUI for installing Campaign Stack without using the command line.

## Quick Start

### 1. Clone the Repository

```bash
cd /srv
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
```

### 2. Start PHP Built-in Server

```bash
cd web-installer
php -S 0.0.0.0:8888
```

### 3. Access the Web Installer

Open your web browser and navigate to:
```
http://YOUR_VPS_IP:8888
```

Replace `YOUR_VPS_IP` with your server's actual IP address.

### 4. Follow the Installation Wizard

The web installer will guide you through:
1. **Prerequisites Check** - Verifies Docker and permissions
2. **Configuration** - Domain setup and AI provider selection
3. **Installation** - Automated deployment with real-time progress
4. **Completion** - Access links and next steps

## Features

- ✅ No command line knowledge required
- ✅ Real-time installation progress
- ✅ Automatic prerequisites checking
- ✅ Secure password generation
- ✅ Post-installation management panel
- ✅ One-click CiviCRM installation
- ✅ Service status monitoring
- ✅ Clean, responsive interface

## Post-Installation Management

After installation, access the management panel at:
```
http://YOUR_VPS_IP:8888/manage.php
```

Features:
- Check service status
- Install CiviCRM
- Restart services
- View Docker logs
- Quick access links to all services

## Security Notes

### Important: Remove After Installation

For production use, **remove the web-installer directory** after completing setup:

```bash
cd /srv/campaign-stack
sudo rm -rf web-installer
```

### Alternative: Password Protection

Or password-protect it with Apache/Nginx basic auth:

**Apache (.htaccess):**
```apache
AuthType Basic
AuthName "Campaign Stack Installer"
AuthUserFile /srv/campaign-stack/web-installer/.htpasswd
Require valid-user
```

**Nginx:**
```nginx
location /web-installer {
    auth_basic "Campaign Stack Installer";
    auth_basic_user_file /srv/campaign-stack/web-installer/.htpasswd;
}
```

Create password file:
```bash
htpasswd -c .htpasswd admin
```

## Troubleshooting

### Port 8888 Already in Use

Change the port number:
```bash
php -S 0.0.0.0:9999
```

### Permission Denied Errors

Ensure the web server has write permissions:
```bash
sudo chown -R $USER:$USER /srv/campaign-stack
chmod -R 755 /srv/campaign-stack
```

### Docker Not Found

Install Docker first:
```bash
curl -fsSL https://get.docker.com | sh
```

### Can't Access from Browser

Check firewall:
```bash
# Ubuntu/Debian
sudo ufw allow 8888/tcp

# CentOS/RHEL
sudo firewall-cmd --add-port=8888/tcp --permanent
sudo firewall-cmd --reload
```

## Architecture

The web installer consists of:

- **index.php** - Main installation wizard
- **check-prereqs.php** - Prerequisites validation
- **install.php** - Installation backend
- **manage.php** - Post-installation management
- **action.php** - Management panel actions
- **style.css** - Responsive styling
- **script.js** - Frontend interactions

## Requirements

- PHP 7.4+ (PHP 8.0+ recommended)
- Docker 20.10+
- Docker Compose V2
- 2GB+ RAM
- 20GB+ disk space

## For Advanced Users

If you prefer the command line, you can skip the web installer:

```bash
cd /srv/campaign-stack
bash install-campaign-stack.sh
```

## Support

- **Documentation**: [GitHub Repository](https://github.com/mkld0910/campaign-stack)
- **Issues**: [Report Bug](https://github.com/mkld0910/campaign-stack/issues)
- **Troubleshooting**: See `docs/TROUBLESHOOTING.md`

---

**Campaign Stack v2.3** - Making campaign technology accessible to everyone
