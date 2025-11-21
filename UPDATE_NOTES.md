# 🔧 Update Notes - v2.3.1

**Date**: January 20, 2025
**Type**: Bug Fixes & Compatibility Improvements

---

## 📋 Quick Summary

All installation scripts and Docker configuration have been updated to fix compatibility issues and migrate to modern Docker Compose V2 standard.

**✅ What's Fixed:**
- Scripts now work on multiple Linux distributions (Ubuntu, RHEL, CentOS, Fedora)
- Migrated from deprecated Docker Compose V1 to V2
- Fixed platform detection (prevents running on Windows directly)
- Fixed hardcoded paths that caused failures
- Corrected API key validation for Anthropic Claude
- Fixed Docker Compose YAML configuration errors

---

## 🚀 Action Required

### If You're Already Running v2.3.0

**Before updating:**
```bash
# Backup your data
docker compose down
cp .env .env.backup
```

**After pulling updates:**
```bash
# Restart with new configuration
docker compose up -d
```

### If You're Installing Fresh

Just run the installer as normal:
```bash
bash install-campaign-stack.sh
```

**⚠️ Important:** These scripts MUST run on Linux or WSL (Windows Subsystem for Linux).
They will **not** work in Windows CMD or PowerShell.

---

## 🔑 Key Changes

### 1. Docker Compose V2 Migration
- **Changed**: `docker-compose` → `docker compose` (space, not hyphen)
- **Why**: V1 is deprecated, V2 is the official standard
- **Impact**: Better performance and native Docker integration

### 2. Multi-Distribution Support
- **Changed**: Added support for yum/dnf package managers
- **Why**: Works on more Linux distributions beyond Ubuntu
- **Impact**: RHEL, CentOS, Fedora users can now install

### 3. Platform Safety
- **Changed**: Scripts detect Windows and block execution
- **Why**: Prevents confusing errors on Windows
- **Impact**: Clear guidance to use WSL or Linux VPS

### 4. Path Fixes
- **Changed**: Removed hardcoded `/srv/campaign-stack` paths
- **Why**: Scripts work from any installation directory
- **Impact**: More flexible deployment locations

### 5. Compose YAML Corrections
- **Changed**: Fixed environment variable syntax, removed invalid build config
- **Why**: Prevented container startup failures
- **Impact**: WordPress and other services start correctly

---

## 🐛 Bugs Fixed

| Issue | Fix | Files |
|-------|-----|-------|
| Docker Compose V1 deprecated syntax | Migrated to V2 | All `.sh` scripts |
| `apt-get` only support | Added yum/dnf detection | `install-*.sh` |
| macOS `sed` incompatibility | Portable sed syntax | `install-ai-provider.sh`, `setup-claude-code.sh` |
| Invalid Anthropic API key check | Fixed regex to `^sk-ant-` | `install-campaign-stack.sh` |
| Wrong Claude model name | Updated to valid model | `setup-claude-code.sh` |
| Hardcoded Linux paths | Dynamic path detection | `fix-docker-compose.sh` |
| Missing `Dockerfile.wordpress` | Removed build directive | `compose.yaml` |
| Literal "DOMAIN" fallback | Fixed env var syntax | `compose.yaml` |
| Hardcoded `/srv/campaign-stack/docs` | Named volume | `compose.yaml` |

---

## 🔍 Testing Checklist

After updating, verify everything works:

- [ ] `docker compose version` shows V2 (v2.x.x)
- [ ] `docker compose ps` shows all containers running
- [ ] Website accessible at your domain (https://yourdomain.com)
- [ ] WordPress admin accessible (/wp-admin)
- [ ] Wiki.js accessible (wiki.yourdomain.com)
- [ ] No errors in `docker compose logs`

---

## 📚 Full Details

See [CHANGELOG.md](CHANGELOG.md) for complete technical details of all changes.

---

## ❓ Need Help?

**Common Issues:**

1. **"docker-compose: command not found"**
   - This is expected! Use `docker compose` (V2) instead

2. **"This script must run on Linux"**
   - Use WSL on Windows or deploy to a Linux VPS

3. **API key validation warning**
   - Anthropic keys should start with `sk-ant-`
   - OpenAI keys start with `sk-proj-` or `sk-`

4. **Container won't start**
   - Check logs: `docker compose logs [service-name]`
   - Verify .env file has all required variables

---

## 📞 Support

- **Documentation**: See `docs/` folder
- **Issues**: Check existing issues or create new one
- **Logs**: Always include output of `docker compose logs` when reporting issues

---

**Tested On:**
- ✅ Ubuntu 22.04 LTS
- ✅ Debian 11
- ✅ RHEL 9
- ✅ CentOS Stream 9
- ✅ Fedora 38
- ✅ Windows 11 + WSL2 (Ubuntu 22.04)
