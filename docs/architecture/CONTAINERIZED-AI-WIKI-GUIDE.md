# CONTAINERIZED AI + WIKI.JS Implementation Guide

**Version:** 2.3 (Full Container Architecture)  
**Date:** November 20, 2025  
**Status:** Production Ready

---

## Overview

Campaign Stack v2.3 implements **fully containerized AI tools** with **integrated knowledge management**:

✅ **All AI providers in Docker containers** (not on host OS)  
✅ **Wiki.js for knowledge management** (searchable docs)  
✅ **Persistent documentation storage** (/srv/campaign-stack/docs/)  
✅ **Unified architecture** - everything in Docker  
✅ **NO vendor lock-in** - supports Claude, OpenAI, Google, Ollama  

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    VPS (Ubuntu)                         │
│  /srv/campaign-stack/                                   │
│                                                         │
│  Persistent Volumes:                                    │
│  ├─ /docs/ ← AI-generated documentation               │
│  ├─ /wordpress_data/ ← WordPress files                │
│  ├─ /mysql_data/ ← Database                           │
│  └─ /wiki_data/ ← Wiki.js database                    │
│                                                         │
│  Docker Containers:                                     │
│  ├─ Traefik (reverse proxy + SSL)                     │
│  ├─ WordPress (CMS)                                    │
│  ├─ MySQL (database)                                   │
│  ├─ Wiki.js (knowledge base) ← NEW                    │
│  ├─ Wiki PostgreSQL (wiki database) ← NEW             │
│  ├─ AI Provider Container (Claude, OpenAI, etc) ← NEW │
│  └─ Portainer (container management)                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
       ↑ SSH Access
       ↑ HTTP/HTTPS Access
       
┌─────────────────────────────────────────────────────────┐
│         Your Laptop/Terminal                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ SSH to VPS:                                             │
│ $ ssh root@YOUR_VPS_IP                                 │
│ $ docker-compose exec ai_provider bash                 │
│ $ claude                    # Start Claude Code        │
│ $ chatgpt                   # Start OpenAI ChatGPT     │
│ $ google-ai                 # Start Google Gemini      │
│                                                         │
│ Browser:                                                │
│ - https://yourdomain.com    # WordPress                │
│ - https://wiki.yourdomain.com # Wiki.js docs          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Installation

### Step 1: Update Docker Compose File

```bash
cd /srv/campaign-stack

# Backup old compose file
cp compose.yaml compose.yaml.backup

# Use new v2.3 with AI container + Wiki.js
cp compose-v2.3.yaml compose.yaml
```

### Step 2: Add Dockerfile for AI Provider

```bash
# Copy Dockerfile to campaign-stack directory
cp Dockerfile.ai-provider /srv/campaign-stack/
```

### Step 3: Update .env File

```bash
nano .env

# Add/update these variables:

# AI Provider Configuration
PRIMARY_AI_PROVIDER=anthropic
# or: openai, google, ollama, or leave empty for none

ANTHROPIC_API_KEY=sk-...
OPENAI_API_KEY=sk-...
GOOGLE_API_KEY=...
OLLAMA_BASE_URL=http://localhost:11434

# Wiki.js Database Password
WIKI_DB_PASSWORD=changeme_with_secure_password
```

### Step 4: Build and Start Containers

```bash
cd /srv/campaign-stack

# Build AI provider image
docker-compose build ai_provider

# Start all containers (including new ones)
docker-compose up -d

# Verify containers are running
docker-compose ps
```

**Expected output:**
```
NAME              STATUS           
traefik           Up 2 minutes     
wordpress_app     Up 2 minutes     
wordpress_mysql   Up 2 minutes     
wiki              Up 1 minute      
wiki_db           Up 2 minutes     
ai_provider       Up 1 minute      
portainer         Up 2 minutes     
```

### Step 5: Initialize Wiki.js

```bash
# First time setup takes a minute
sleep 60

# Visit in browser
# https://wiki.yourdomain.com

# Default login: admin / change_me
# (Change password on first login)
```

---

## Using Containerized AI Tools

### Option 1: Interactive Shell Access

```bash
# SSH into VPS
ssh root@YOUR_VPS_IP

# Enter AI container
docker-compose exec ai_provider bash

# Now you're inside the container with all tools installed
# You can use:
claude          # Start Anthropic Claude Code
chatgpt         # Start OpenAI ChatGPT CLI
google-ai       # Start Google Gemini
exit            # Return to host
```

### Option 2: Direct Command Execution

```bash
# Run without entering interactive shell
docker-compose exec ai_provider claude

# Or run a single command
docker-compose exec ai_provider bash -c "claude --version"
```

### Option 3: Run Specific Provider

```bash
# The container detects PRIMARY_AI_PROVIDER from .env
# To override, set environment variable:

docker-compose exec -e PRIMARY_AI_PROVIDER=openai ai_provider bash
# Now inside: chatgpt will be ready to use
```

---

## AI-Generated Documentation Workflow

### Ideal Workflow

```
1. SSH into VPS
   $ ssh root@YOUR_VPS_IP

2. Enter AI container
   $ docker-compose exec ai_provider bash

3. Generate documentation
   $ claude
   > "Generate deployment guide for our CI/CD pipeline"
   > Claude generates guide...
   > You save it to: /app/docs/ci-cd-guide.md
   > (Files in /app/docs are mounted to /srv/campaign-stack/docs/)

4. Documentation persists:
   $ exit  (leave container)
   $ ls /srv/campaign-stack/docs/
   ci-cd-guide.md  ✓ File is here

5. Wiki.js auto-discovers it:
   $ Open browser: https://wiki.yourdomain.com
   $ Docs page shows: ci-cd-guide.md
   $ Search works
   $ You can view/edit in web interface

6. Version control:
   $ cd /srv/campaign-stack/docs/
   $ git add .
   $ git commit -m "Add CI/CD guide"
   $ git push origin main  (if using GitHub)
```

---

## File Storage

### Where Documentation Lives

```
Container: /app/docs/
Host: /srv/campaign-stack/docs/
Wiki.js: /wiki/docs_mount/ (mounted)

They're all the same location, just accessed differently!
```

### Example: Create and Persist a Document

```bash
# Inside AI container
docker-compose exec ai_provider bash
$ cd /app/docs
$ echo "# My Campaign Guide" > campaign-guide.md
$ exit

# Back on host
$ cat /srv/campaign-stack/docs/campaign-guide.md
# My Campaign Guide

# Wiki.js can now see it at:
# https://wiki.yourdomain.com/campaign-guide
```

---

## Switching AI Providers

### Option 1: Temporary Switch (One Command)

```bash
# Use OpenAI for this session only
docker-compose exec -e PRIMARY_AI_PROVIDER=openai ai_provider bash
$ chatgpt
```

### Option 2: Permanent Switch

```bash
# Edit .env
nano .env

# Change:
PRIMARY_AI_PROVIDER=openai
OPENAI_API_KEY=sk-...

# Restart container
docker-compose restart ai_provider

# Now default provider is OpenAI
docker-compose exec ai_provider bash
$ chatgpt  # Ready to use
```

---

## Wiki.js Configuration

### Access Wiki.js

```
URL: https://wiki.yourdomain.com
Default login: admin / change_me

First time:
1. Change admin password
2. Configure storage (can link to Git repo)
3. Create home page
4. Start adding documentation
```

### Link to Git Repo (Optional)

```
Wiki.js Settings → Storage
→ Git
→ Repository URL: https://github.com/your-user/campaign-docs.git
→ Token: (GitHub personal access token)

Now docs auto-sync to GitHub!
```

### Import Existing Docs

```bash
# Copy existing docs to /srv/campaign-stack/docs/
cp /path/to/old/docs/* /srv/campaign-stack/docs/

# Wiki.js will auto-discover them
# They'll appear in the web interface
```

---

## Persistent Storage Architecture

```
┌─────────────────────────────────────────┐
│  AI Container generates docs            │
│  /app/docs/architecture-guide.md       │
└──────────────┬──────────────────────────┘
               │ Volume mount
               ↓
┌─────────────────────────────────────────┐
│  Host filesystem                        │
│  /srv/campaign-stack/docs/              │
│  ├─ architecture-guide.md               │
│  ├─ deployment-guide.md                 │
│  └─ troubleshooting.md                  │
└──────────────┬──────────────────────────┘
               │ Volume mount
               ↓
┌─────────────────────────────────────────┐
│  Wiki.js Container sees files           │
│  /wiki/docs_mount/                      │
│  ├─ architecture-guide.md               │
│  ├─ deployment-guide.md                 │
│  └─ troubleshooting.md                  │
└──────────────┬──────────────────────────┘
               │ Indexes & displays
               ↓
┌─────────────────────────────────────────┐
│  Browser: https://wiki.yourdomain.com   │
│  Searchable knowledge base!             │
└─────────────────────────────────────────┘
```

---

## Backup Strategy

### Docs Backup

```bash
# Daily backup of /srv/campaign-stack/docs/
# → Storj cloud backup
# → GitHub repository
# → Local machine backup

# Result: Never lose documentation
```

### Wiki.js Backup

```bash
# Wiki.js data in Docker volumes:
# wiki_data      ← Application data
# wiki_db_data   ← PostgreSQL database

# Both included in standard backup strategy
```

---

## Troubleshooting

### AI Container Won't Start

```bash
# Check logs
docker-compose logs ai_provider

# Rebuild image
docker-compose build --no-cache ai_provider

# Start fresh
docker-compose up -d ai_provider
```

### Documentation Not Showing in Wiki.js

```bash
# Verify docs exist
ls -la /srv/campaign-stack/docs/

# Check container mount
docker-compose exec wiki ls -la /wiki/docs_mount/

# Restart Wiki.js
docker-compose restart wiki
```

### AI Tools Not Found

```bash
# Verify container is running
docker-compose ps ai_provider

# Enter container and check
docker-compose exec ai_provider which claude
docker-compose exec ai_provider npm list -g

# Rebuild if missing
docker-compose build --no-cache ai_provider
docker-compose up -d ai_provider
```

---

## Performance Considerations

### Memory Usage

```
Containers added:
- Wiki.js: ~200MB
- Wiki PostgreSQL: ~100MB
- AI Provider: ~500MB (with Node/npm)

Total new: ~800MB

Typical VPS has 2GB+ RAM, so no problem.
```

### Disk Space

```
Docker images:
- Wiki.js: ~300MB
- PostgreSQL: ~150MB
- Node image: ~200MB

Total: ~650MB

Generated docs: ~10-100MB (depending on volume)

Total VPS needs: 20GB+ (plenty of room)
```

---

## Comparison: Host vs Container

### Before (v2.2): Host-based AI Tools
```
Host OS
├─ Node.js installed
├─ npm installed  
├─ Claude Code CLI on host
├─ ChatGPT CLI on host
├─ Google AI CLI on host
└─ Docs scattered on filesystem

Problems:
❌ Not containerized (inconsistent)
❌ Dependencies on host OS
❌ No centralized docs management
❌ No easy discovery/search
```

### After (v2.3): Containerized Everything
```
Docker Containers
├─ AI Provider Container (all CLIs)
├─ Wiki.js Container (knowledge base)
├─ Traefik Container (web access)
├─ WordPress Container (CMS)
├─ MySQL Container (database)
└─ Portainer Container (management)

Persistent Volumes
└─ /srv/campaign-stack/docs/ (shared)

Benefits:
✅ Fully containerized
✅ Consistent architecture
✅ Scalable (can run multiple instances)
✅ Centralized documentation
✅ Searchable knowledge base
✅ Version controlled
✅ Backed up
```

---

## Summary

### What You Get

✅ **Containerized AI Tools**
- All AI providers (Claude, OpenAI, Google, Ollama) in one container
- No host OS pollution
- Easy to manage with Docker

✅ **Knowledge Management**
- Wiki.js for searchable documentation
- Web interface at wiki.yourdomain.com
- Markdown support
- Tag-based organization

✅ **Persistent Storage**
- /srv/campaign-stack/docs/ mounts to:
  - AI container (/app/docs/)
  - Wiki.js container (/wiki/docs_mount/)
- Files never lost
- Easy backup

✅ **Unified Architecture**
- Everything in Docker
- Everything in docker-compose.yaml
- Everything accessible via SSH or browser
- No special setup required

---

## Next Steps

1. ✅ Update compose.yaml to v2.3
2. ✅ Copy Dockerfile.ai-provider
3. ✅ Update .env with AI provider config + Wiki password
4. ✅ Build and start: `docker-compose up -d`
5. ✅ Access Wiki.js: https://wiki.yourdomain.com
6. ✅ Generate docs: `docker-compose exec ai_provider bash`
7. ✅ Watch docs appear in Wiki.js automatically

---

**Status:** ✅ Production Ready  
**Architecture:** Fully Containerized  
**Knowledge Management:** Wiki.js Integrated  
**Documentation Storage:** Persistent & Searchable
