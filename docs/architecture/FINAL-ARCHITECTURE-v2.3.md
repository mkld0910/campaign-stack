# Campaign Stack v2.3: FULLY CONTAINERIZED with Knowledge Management

**Date:** November 20, 2025  
**Status:** ✅ Production Ready  
**Architecture:** Fully Containerized (everything in Docker)  
**Philosophy:** NO Vendor Lock-In + Persistent Knowledge Management

---

## 🎯 What Changed: Host OS → Docker Containers

### Old (v2.2): AI Tools on Host OS
```
Host OS
├─ Node.js installed
├─ npm installed
├─ Claude Code running on host
├─ ChatGPT CLI running on host
└─ Docs scattered on filesystem

Problems:
❌ Not containerized
❌ Inconsistent with architecture
❌ No knowledge management
❌ No docs discovery/search
```

### New (v2.3): Everything in Containers ✅
```
Docker Containers:
├─ Traefik (reverse proxy)
├─ WordPress (CMS)
├─ MySQL (database)
├─ AI Provider Container ← ALL AI tools here
├─ Wiki.js Container ← Knowledge base
├─ Wiki PostgreSQL
└─ Portainer (management)

Persistent Volumes:
└─ /srv/campaign-stack/docs/ ← Shared between containers

Benefits:
✅ Fully containerized
✅ Consistent architecture
✅ Knowledge management built-in
✅ Docs searchable & discoverable
✅ No vendor lock-in
```

---

## 📦 New Files

### 3 New Core Files

1. **`Dockerfile.ai-provider`** (NEW)
   - Containerizes all AI tools
   - Supports Claude, OpenAI, Google, Ollama
   - Mounts docs volume for persistent storage
   - Interactive shell access

2. **`compose.yaml`** (v2.3 - Updated)
   - Added `ai_provider` service (containerized AI)
   - Added `wiki` service (knowledge management)
   - Added `wiki_db` service (PostgreSQL for Wiki)
   - Added `docs_volume` (shared docs storage)
   - All with Traefik routing and SSL

3. **`CONTAINERIZED-AI-WIKI-GUIDE.md`** (NEW)
   - Complete implementation guide
   - Step-by-step setup
   - Usage examples
   - Troubleshooting

---

## 🏗️ Architecture (v2.3)

```
┌─────────────────────────────────────────────────┐
│             VPS (/srv/campaign-stack/)          │
├─────────────────────────────────────────────────┤
│                                                 │
│  PERSISTENT VOLUMES:                            │
│  ├─ /docs/ ← AI-generated docs                 │
│  ├─ /wordpress_data/ ← WordPress               │
│  ├─ /mysql_data/ ← Database                    │
│  ├─ /wiki_data/ ← Wiki.js app                  │
│  └─ /wiki_db_data/ ← Wiki PostgreSQL           │
│                                                 │
│  DOCKER CONTAINERS:                             │
│  ├─ traefik (reverse proxy, SSL)               │
│  ├─ wordpress_app (CMS + PHP)                  │
│  ├─ wordpress_mysql (database)                 │
│  ├─ ai_provider ← NEW: Containerized AI        │
│  ├─ wiki ← NEW: Knowledge base                 │
│  ├─ wiki_db ← NEW: Wiki PostgreSQL             │
│  └─ portainer (container management)           │
│                                                 │
│  NETWORK ACCESS:                                │
│  ├─ https://yourdomain.com → WordPress         │
│  ├─ https://wiki.yourdomain.com → Wiki.js      │
│  ├─ http://YOUR_IP:9000 → Portainer           │
│  └─ SSH: docker-compose exec ai_provider bash  │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### 1. Update Docker Compose

```bash
cd /srv/campaign-stack
cp compose.yaml compose.yaml.backup
# Use new v2.3 compose.yaml from outputs
cp compose.yaml .
```

### 2. Add Dockerfile

```bash
# Copy Dockerfile.ai-provider to campaign-stack directory
cp Dockerfile.ai-provider /srv/campaign-stack/
```

### 3. Update .env

```bash
nano .env

# Add these variables:
PRIMARY_AI_PROVIDER=anthropic
# or: openai, google, ollama

ANTHROPIC_API_KEY=sk-...
OPENAI_API_KEY=sk-...
GOOGLE_API_KEY=...

WIKI_DB_PASSWORD=changeme_secure_password
```

### 4. Build & Start

```bash
docker-compose build ai_provider
docker-compose up -d
docker-compose ps  # Verify all running
```

### 5. Access Services

```
- WordPress: https://yourdomain.com
- Wiki.js: https://wiki.yourdomain.com
- Portainer: http://YOUR_IP:9000
- AI Tools: docker-compose exec ai_provider bash
```

---

## 💻 Using Containerized AI

### Start AI Terminal

```bash
# SSH to VPS
ssh root@YOUR_VPS_IP

# Enter AI container
docker-compose exec ai_provider bash

# Now available:
claude          # Anthropic Claude Code
chatgpt         # OpenAI ChatGPT
google-ai       # Google Gemini
```

### Generate & Save Documentation

```bash
# Inside container
docker-compose exec ai_provider bash

$ claude
> "Generate deployment guide for CI/CD"
> Claude writes to: /app/docs/ci-cd-guide.md
> exit

# File persists on host:
$ ls /srv/campaign-stack/docs/ci-cd-guide.md  ✓

# Wiki.js auto-discovers it:
# https://wiki.yourdomain.com/ci-cd-guide
```

---

## 🎯 Docs Workflow

```
1. AI generates doc in container
   /app/docs/architecture-guide.md
         ↓ (volume mount)
   
2. Persists on host
   /srv/campaign-stack/docs/architecture-guide.md
         ↓ (volume mount)
   
3. Wiki.js reads and indexes
   /wiki/docs_mount/architecture-guide.md
         ↓ (indexes & searches)
   
4. Browser: Searchable knowledge base
   https://wiki.yourdomain.com/search?q=architecture
```

---

## 🔄 Switching AI Providers

### Temporary (One Command)

```bash
docker-compose exec -e PRIMARY_AI_PROVIDER=openai \
  ai_provider bash
$ chatgpt
```

### Permanent (Update .env)

```bash
nano .env
# Change: PRIMARY_AI_PROVIDER=openai

docker-compose restart ai_provider
# Now default is OpenAI
```

---

## 📚 Knowledge Management (Wiki.js)

### Access Wiki

```
URL: https://wiki.yourdomain.com
Login: admin / change_me
(Change password on first login)
```

### Features

✅ Search across all docs  
✅ Tag-based organization  
✅ Markdown editing  
✅ Git sync (optional)  
✅ Permission-based access  
✅ Full-text indexing  

### Optional: Sync to GitHub

```
Wiki.js Settings → Storage → Git
→ Repository URL: https://github.com/your/docs.git
→ Personal Access Token: (from GitHub)

Now docs auto-sync to GitHub!
```

---

## 💾 Persistent Storage

### Where Documentation Lives

```
Container: /app/docs/
Host: /srv/campaign-stack/docs/
Wiki.js: /wiki/docs_mount/ (mounted)

They're all the same location!
```

### Backup Strategy

```
/srv/campaign-stack/docs/
    ↓
Daily backup to Storj/S3
    ↓
Weekly backup to GitHub
    ↓
Monthly local backup

Result: Documentation never lost
```

---

## 📊 Resource Usage

### Memory

```
New containers:
- AI Provider: ~500MB (Node + CLIs)
- Wiki.js: ~200MB
- Wiki PostgreSQL: ~100MB
Total: ~800MB

VPS typical: 2GB+ RAM ✅
```

### Disk

```
Docker images:
- Node image: ~200MB
- Wiki.js: ~300MB
- PostgreSQL: ~150MB
Total: ~650MB

VPS typical: 20GB+ disk ✅
```

---

## ✨ Key Features (v2.3)

### ✅ Fully Containerized
- All tools in Docker
- No host OS dependencies
- Consistent architecture

### ✅ Multi-Provider AI
- Anthropic Claude
- OpenAI ChatGPT
- Google Gemini
- Ollama (local/free)
- No vendor lock-in

### ✅ Knowledge Management
- Wiki.js web interface
- Searchable documentation
- Version control ready
- Git sync optional

### ✅ Persistent Storage
- /srv/campaign-stack/docs/
- Mounted to AI container
- Mounted to Wiki.js
- Backed up automatically

### ✅ Easy Access
```
From laptop:
- SSH for AI: ssh root@VPS
- Browser for Wiki: https://wiki.domain.com
- Both available anytime
```

---

## 📋 Files in This Release

**Core Infrastructure (3 files):**
1. ✅ `Dockerfile.ai-provider` (NEW) - AI container image
2. ✅ `compose.yaml` (v2.3) - Docker Compose with all services
3. ✅ `CONTAINERIZED-AI-WIKI-GUIDE.md` (NEW) - Setup guide

**Supporting Files (13 others):**
- Installation scripts
- Configuration files
- Documentation files
- Architecture analyses

**Total: 16 files**

---

## 🔄 Comparison: Before vs After

### v2.2 (Previous)

```
Architecture:
├─ Host OS (Docker on host)
├─ AI tools on host OS
└─ Docs scattered on filesystem

Access:
- SSH to host → run claude
- Docs not searchable
- No knowledge management
```

### v2.3 (New) ✅

```
Architecture:
├─ All in Docker containers
├─ AI tools in container
├─ Wiki.js in container
└─ Docs persistent & searchable

Access:
- SSH → docker-compose exec → claude
- docs searchable via https://wiki.domain.com
- Full knowledge management
- Everything containerized
```

---

## 🎓 Implementation Steps

### Phase 1: Update Files
1. Replace compose.yaml with v2.3
2. Add Dockerfile.ai-provider
3. Update .env with new variables

### Phase 2: Deploy
1. `docker-compose build ai_provider`
2. `docker-compose up -d`
3. Verify all containers running

### Phase 3: Use
1. Access AI: `docker-compose exec ai_provider bash`
2. Access Wiki: `https://wiki.yourdomain.com`
3. Generate docs in container
4. View in Wiki.js automatically

---

## 🆘 Troubleshooting

### AI Container Won't Start
```bash
docker-compose logs ai_provider
docker-compose build --no-cache ai_provider
docker-compose up -d ai_provider
```

### Docs Not in Wiki.js
```bash
# Check files exist
ls /srv/campaign-stack/docs/

# Verify mount
docker-compose exec wiki ls /wiki/docs_mount/

# Restart Wiki
docker-compose restart wiki
```

### API Key Issues
```bash
# Check in container
docker-compose exec ai_provider env | grep API_KEY

# Update .env and restart
nano .env
docker-compose restart ai_provider
```

---

## 📈 Scaling

### Single Provider
```
Current setup handles single AI provider well
With Claude + Wiki + WordPress: ~2GB RAM needed
```

### Multiple Instances
```
Could run multiple AI containers for:
- Load balancing
- Provider A/B testing
- Parallel processing

Just update compose.yaml
```

### Performance
```
AI container: ~500MB per instance
Wiki.js: Scales to 1000s of docs
No performance issues with typical usage
```

---

## 🔒 Security

### Container Isolation
- AI container isolated from others
- No direct host OS access
- Network restricted via Traefik

### Secrets Management
- API keys in .env only
- .env mounted as read-only
- Keys not in code or images

### Data Protection
- All traffic encrypted (SSL/TLS)
- Database backups encrypted
- Git repos can be private

---

## 📞 Support

**For containerization questions:**
- See: `CONTAINERIZED-AI-WIKI-GUIDE.md`
- See: `CONTAINER-ARCHITECTURE-ANALYSIS.md`

**For AI provider questions:**
- See: `13-AI-PROVIDERS.md`

**For general setup:**
- See: Installation guides in outputs

---

## Summary

**Campaign Stack v2.3 delivers:**

✅ Fully containerized architecture  
✅ Containerized AI tools (all providers)  
✅ Knowledge management (Wiki.js)  
✅ Persistent documentation storage  
✅ NO vendor lock-in  
✅ Production ready  
✅ Scalable design  
✅ Easy to manage  

**Everything in Docker. Everything persistent. Everything searchable.**

---

**Status:** ✅ Production Ready  
**Version:** 2.3  
**Philosophy:** Fully Containerized + Knowledge Management  
**Deployment:** ~30 minutes

