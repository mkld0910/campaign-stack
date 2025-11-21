# Changelog

All notable changes to the Campaign Stack project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.3.1] - 2025-01-20

### Fixed - Shell Scripts Platform Compatibility & Docker Compose V2 Migration

#### Overview
All installation scripts have been updated to fix critical compatibility issues, migrate to Docker Compose V2, and support multiple Linux distributions. These changes ensure the scripts work correctly on Ubuntu, Debian, RHEL, CentOS, Fedora, and macOS.

#### Shell Scripts Fixed
- `install-campaign-stack.sh`
- `install-ai-provider.sh`
- `setup-claude-code.sh`
- `fix-docker-compose.sh`

---

### Changes Made

#### 1. **Docker Compose V2 Migration**
**What Changed:**
- All `docker-compose` (hyphen) commands replaced with `docker compose` (space)
- Updated Docker Compose installation to use the official V2 CLI plugin method

**Why:**
- Docker Compose V1 (`docker-compose`) is deprecated and no longer maintained
- Docker Compose V2 (`docker compose`) is the official standard as of Docker Desktop 3.4.0
- V2 provides better performance, native integration with Docker CLI, and improved compatibility

**Impact:**
- Scripts now install Docker Compose V2 as a CLI plugin (`~/.docker/cli-plugins/`)
- All scripts use consistent `docker compose` syntax throughout
- Fixed `install-campaign-stack.sh:367, 370, 461, 466, 471, 472, 480`
- Fixed `fix-docker-compose.sh:39-41, 46`

---

#### 2. **Platform Detection & Safety**
**What Changed:**
- Added platform detection to all shell scripts
- Scripts now exit with clear error message when run on Windows

**Why:**
- These are Linux bash scripts that won't work on Windows without WSL
- Prevents confusing errors when users try to run scripts in Windows CMD/PowerShell
- Guides users to run on Linux VPS or Windows Subsystem for Linux (WSL)

**Impact:**
- All scripts check `$OSTYPE` and block execution on `msys`, `win32`, and `cygwin`
- Users are directed to use WSL or a Linux VPS

**Files Modified:**
- `install-campaign-stack.sh:20-25`
- `install-ai-provider.sh:19-24`
- `setup-claude-code.sh:18-23`
- `fix-docker-compose.sh:4-9`

---

#### 3. **Multi-Distribution Package Manager Support**
**What Changed:**
- Added automatic detection of package managers (apt-get, yum, dnf)
- Node.js installation now works on Ubuntu/Debian, RHEL/CentOS, and Fedora

**Why:**
- Original scripts only supported `apt-get` (Ubuntu/Debian)
- Many users deploy on RHEL, CentOS, or Fedora which use `yum`/`dnf`
- Improves portability across different Linux distributions

**Impact:**
- Scripts now detect and use the appropriate package manager
- Falls back to manual installation message if no supported package manager found

**Files Modified:**
- `install-campaign-stack.sh:383-400, 404-421, 428-445`
- `install-ai-provider.sh:113-129, 160-176, 207-223`
- `setup-claude-code.sh:151-173`

---

#### 4. **Portable `sed` Commands (macOS Compatibility)**
**What Changed:**
- Made all `sed -i` commands portable for both Linux and macOS
- Added `sed -i ''` syntax detection for macOS

**Why:**
- `sed -i` works differently on GNU (Linux) vs BSD (macOS)
- Linux: `sed -i 's/foo/bar/' file`
- macOS: `sed -i '' 's/foo/bar/' file` (requires empty string for in-place edit)
- Original scripts would fail on macOS with "command expects followed by text" error

**Impact:**
- All scripts now check `$OSTYPE` for `darwin` (macOS)
- Uses appropriate `sed` syntax based on platform

**Files Modified:**
- `install-ai-provider.sh:98-105, 145-152, 192-199, 236-243, 360-373`
- `setup-claude-code.sh:129-138`

---

#### 5. **Anthropic API Key Validation Correction**
**What Changed:**
- Updated API key validation from `^sk-` to `^sk-ant-`
- Improved validation messages

**Why:**
- Anthropic API keys use the format `sk-ant-api03-...`, not just `sk-`
- OpenAI keys start with `sk-proj-...` or `sk-...`
- Previous validation incorrectly validated Anthropic keys

**Impact:**
- More accurate API key validation
- Prevents false warnings for valid Anthropic API keys

**Files Modified:**
- `install-campaign-stack.sh:216-219`
- `setup-claude-code.sh:117-118`

---

#### 6. **Updated Claude Model Name**
**What Changed:**
- Changed default Claude model from `claude-opus-4.1` to `claude-sonnet-4-20250514`

**Why:**
- `claude-opus-4.1` doesn't exist in Anthropic's model lineup
- `claude-sonnet-4-20250514` is a valid, current model
- Prevents API errors when scripts try to use non-existent models

**Impact:**
- Scripts now reference a valid Claude model
- Users won't encounter "model not found" errors

**Files Modified:**
- `setup-claude-code.sh:146`

---

#### 7. **Dynamic Path Resolution**
**What Changed:**
- Removed hardcoded `/srv/campaign-stack` path
- Implemented dynamic path detection using `$SCRIPT_DIR` and `$REPO_DIR`

**Why:**
- Hardcoded paths fail when users install to different directories
- Scripts should work regardless of installation location
- Improves flexibility and user experience

**Impact:**
- Scripts auto-detect their location and work from any directory
- No need to install to specific path

**Files Modified:**
- `fix-docker-compose.sh:54-58`

---

### compose.yaml Fixes

#### 1. **Removed Invalid Build Configuration**
**What Changed:**
- Removed `build` section from `wordpress_app` service
- Deleted reference to non-existent `Dockerfile.wordpress`

**Why:**
- Service specified both `image: wordpress:latest` AND a build directive
- Referenced `Dockerfile.wordpress` which doesn't exist in the repository
- Caused Docker Compose to fail when trying to build

**Impact:**
- WordPress now uses official `wordpress:latest` image from Docker Hub
- No custom build step required

**Files Modified:**
- `compose.yaml:85-90` (removed lines 88-90)

---

#### 2. **Fixed Hardcoded Volume Path**
**What Changed:**
- Removed hardcoded `/srv/campaign-stack/docs` bind mount
- Converted `docs_volume` to Docker-managed named volume

**Why:**
- Hardcoded Linux path `/srv/campaign-stack/docs` fails on Windows
- Bind mounts to non-existent paths cause container startup failures
- Named volumes are portable across platforms

**Impact:**
- Docker automatically creates and manages the volume
- Works on any platform (Linux, Windows with WSL, macOS)
- Volume location: `/var/lib/docker/volumes/` on Linux

**Files Modified:**
- `compose.yaml:263-269`

---

#### 3. **Fixed Environment Variable Fallback Syntax**
**What Changed:**
- Changed `WP_HOME: https://${PUBLIC_DOMAIN:-DOMAIN}` to `https://${PUBLIC_DOMAIN:-${DOMAIN}}`
- Changed `WP_SITEURL: https://${BACKEND_DOMAIN:-DOMAIN}` to `https://${BACKEND_DOMAIN:-${DOMAIN}}`

**Why:**
- Original syntax used literal string "DOMAIN" as fallback
- WordPress would receive `https://DOMAIN` instead of actual domain value
- Correct syntax references the `${DOMAIN}` environment variable

**Impact:**
- WordPress now correctly falls back to main domain when dual-domain not configured
- Prevents WordPress from using invalid "DOMAIN" URL

**Files Modified:**
- `compose.yaml:96-97`

---

## Migration Guide

### For Existing Installations

If you're upgrading from v2.3.0 or earlier:

1. **Backup your data:**
   ```bash
   docker compose down
   cp -r mysql_data mysql_data.backup
   cp -r wordpress_data wordpress_data.backup
   cp .env .env.backup
   ```

2. **Update your files:**
   ```bash
   git pull origin main
   # Or manually replace the shell scripts and compose.yaml
   ```

3. **Verify Docker Compose V2:**
   ```bash
   docker compose version
   # Should show: Docker Compose version v2.x.x
   ```

4. **Restart services:**
   ```bash
   docker compose up -d
   ```

### For New Installations

1. **Clone the repository** on a Linux VPS or WSL:
   ```bash
   git clone <repo-url>
   cd campaign-stack
   ```

2. **Run the installer:**
   ```bash
   bash install-campaign-stack.sh
   ```

3. **Follow the prompts** to configure domains, email, and AI provider

---

## Platform Requirements

### Supported Platforms
- ✅ Ubuntu 20.04+ (LTS recommended)
- ✅ Debian 10+
- ✅ RHEL 8+
- ✅ CentOS 8+
- ✅ Fedora 35+
- ✅ Windows 10/11 with WSL2
- ✅ macOS 11+ (for development, not recommended for production)

### Minimum Requirements
- **OS**: Linux (any supported distribution)
- **Docker**: 20.10.0+
- **Docker Compose**: V2 (2.0.0+)
- **RAM**: 2GB minimum, 4GB recommended
- **Disk**: 20GB minimum free space

---

## Known Issues

### Docker Compose V1 Compatibility
If you have Docker Compose V1 installed, it may conflict with V2. To resolve:

```bash
# Remove old docker-compose V1
sudo rm /usr/local/bin/docker-compose

# Verify V2 is working
docker compose version
```

### WSL Path Issues
When running on Windows with WSL, ensure you're working in the Linux filesystem (`/home/...`), not Windows paths (`/mnt/c/...`), for better performance.

---

## Deprecation Notices

- **Docker Compose V1** (`docker-compose` with hyphen) is deprecated and no longer supported
- **Hardcoded installation paths** are deprecated; scripts now use dynamic path detection

---

## Contributors
- Script fixes and Docker Compose V2 migration
- Platform compatibility improvements
- Documentation updates

---

## Questions or Issues?

If you encounter any problems with these updates:
1. Check the [Troubleshooting Guide](docs/04-TROUBLESHOOTING.md)
2. Verify you're using Docker Compose V2: `docker compose version`
3. Ensure scripts are run on Linux or WSL, not Windows directly
4. Open an issue on GitHub with full error output
