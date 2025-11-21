# Container Architecture Analysis: AI Providers + Knowledge Management

**Date:** November 20, 2025  
**Question:** Does multi-provider AI support make sense in containerized environment?  
**Follow-up:** How to handle persistent documentation storage?

---

## Part 1: Multi-Provider AI in Containers

### Current Architecture

```
┌─────────────────────────────────────────────────┐
│                    VPS (Ubuntu)                 │
├─────────────────────────────────────────────────┤
│                 Docker Container                │
│                  (Host: Root SSH)               │
│  ┌──────────────────────────────────────────┐  │
│  │     Traefik (Reverse Proxy)              │  │
│  │     WordPress Container                  │  │
│  │     MySQL Container                      │  │
│  │     Portainer Container                  │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
│  AI Provider CLI (Claude, OpenAI, etc.)       │
│  Runs on HOST (root SSH terminal)              │
│  NOT in containers                             │
└─────────────────────────────────────────────────┘
```

### ❓ Problem: AI Provider Running on Host, Not in Container

**Current Implementation:**
- AI CLI tools (Claude Code, ChatGPT CLI, etc.) run on **host OS**
- User SSHes into VPS and runs: `claude`
- Not containerized

**Considerations:**

✅ **Advantages of Host-based:**
- Direct access to files and directories
- Can modify WordPress code directly
- Can run Docker commands
- Can access all VPS resources
- Familiar terminal environment

❌ **Disadvantages:**
- Not containerized (inconsistent with philosophy)
- Requires root SSH access
- Not scalable (can't run multiple instances)
- Requires Node.js/npm on host OS
- Version conflicts possible

---

## Part 2: Containerized AI Solution

### Option A: AI Container

```dockerfile
# Dockerfile.ai-provider
FROM node:18-alpine

# Install providers
RUN npm install -g @anthropic-ai/claude-code
RUN npm install -g chatgpt-cli
RUN npm install -g @google/generative-ai
RUN apt-get install -y ollama

# Mount .env for API keys
VOLUME ["/app/.env"]

# Mount code directory for access
VOLUME ["/app/workspace"]

# Default: Claude
CMD ["claude"]
```

**docker-compose.yaml addition:**
```yaml
ai-provider:
  build:
    context: .
    dockerfile: Dockerfile.ai-provider
  container_name: ai-provider
  environment:
    ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
    OPENAI_API_KEY: ${OPENAI_API_KEY}
    GOOGLE_API_KEY: ${GOOGLE_API_KEY}
  volumes:
    - ./wordpress_data:/app/workspace
    - ./docs:/app/docs
  stdin_open: true
  tty: true
  networks:
    - traefik
```

**Usage:**
```bash
docker-compose exec ai-provider claude
# Or
docker-compose run ai-provider claude
```

---

## Part 3: Persistent Documentation Storage

### Current Problem

Generated documentation (from AI) has **nowhere to live**:
- AI generates docs during terminal session
- User manually saves to file
- No persistent storage system
- No version control
- No knowledge management

### Option 1: Host-Based File System

```
/srv/campaign-stack/
├── docs/                    # Manual docs
├── generated_docs/          # AI-generated docs (NEW)
│   ├── 2025-11-20/
│   │   ├── campaign-strategy.md
│   │   ├── setup-guide.md
│   │   └── troubleshooting.md
│   └── 2025-11-21/
│       └── deployment-checklist.md
└── wordpress_data/          # WordPress files
```

**Pros:**
- Simple file system
- Easy version control with git
- Works with all editors

**Cons:**
- No knowledge management
- Manual organization
- No search/indexing
- No relationships between docs

---

## Part 4: Knowledge Management Integration

### Option A: Obsidian (Local)

**What is Obsidian:**
- Markdown-based knowledge management
- Local-first (files live on your computer)
- Bidirectional linking
- Graph view
- Search and indexing
- Sync options

**Architecture:**

```
Your Laptop (Obsidian Vault)
    ↓ SSH/SFTP
    ↓
VPS (/srv/campaign-stack/docs/)
    ↓
Git Sync (Optional)
    ↓
GitHub (Backup)
```

**Setup:**

```bash
# On VPS
mkdir -p /srv/campaign-stack/obsidian-vault
cd /srv/campaign-stack/obsidian-vault

# Initialize git
git init

# On your laptop
# 1. Open Obsidian
# 2. Create vault → Remote Folder
# 3. Point to: sftp://root@YOUR_VPS_IP/srv/campaign-stack/obsidian-vault
# 4. Files sync as you edit
```

**Workflow:**

```
Campaign Stack VPS
    ↓
AI generates documentation
claude > "Create architecture guide"
    ↓
Generate file:
/srv/campaign-stack/obsidian-vault/guides/architecture.md
    ↓
Obsidian (your laptop) auto-syncs
    ↓
You view in Obsidian UI with:
- Backlinks
- Graph view
- Search
- Tags
```

---

### Option B: Wiki.js (Containerized Knowledge Base)

**What is Wiki.js:**
- Self-hosted wiki platform
- Containerized (fits your architecture!)
- Web-based interface
- Markdown support
- Search and tagging
- Git sync capability

**Architecture:**

```
┌──────────────────────────────────┐
│    Your Laptop Browser           │
│    http://wiki.yourdomain.com    │
└──────────────────────────────────┘
            ↑
            │ HTTP
            ↓
┌──────────────────────────────────┐
│  VPS - Docker Container          │
│  Wiki.js Container               │
│  - PostgreSQL (database)         │
│  - Wiki.js (app)                 │
└──────────────────────────────────┘
            ↑
            │ Mount
            ↓
┌──────────────────────────────────┐
│  /srv/campaign-stack/wiki-docs/  │
│  (Persistent storage)            │
└──────────────────────────────────┘
```

**docker-compose.yaml addition:**

```yaml
wiki-db:
  image: postgres:15-alpine
  environment:
    POSTGRES_DB: wiki
    POSTGRES_USER: wiki
    POSTGRES_PASSWORD: ${WIKI_DB_PASSWORD}
  volumes:
    - wiki_db_data:/var/lib/postgresql/data
  networks:
    - traefik

wiki:
  image: requarks/wiki:latest
  container_name: wiki
  depends_on:
    - wiki-db
  environment:
    DB_TYPE: postgres
    DB_HOST: wiki-db
    DB_PORT: 5432
    DB_USER: wiki
    DB_PASS: ${WIKI_DB_PASSWORD}
    DB_NAME: wiki
  volumes:
    - wiki_data:/data
  labels:
    - "traefik.enable=true"
    - "traefik.http.routers.wiki.rule=Host(`wiki.${DOMAIN}`)"
    - "traefik.http.routers.wiki.entrypoints=web,websecure"
    - "traefik.http.routers.wiki.tls=true"
    - "traefik.http.routers.wiki.tls.certresolver=letsencrypt"
    - "traefik.http.services.wiki.loadbalancer.server.port=3000"
  networks:
    - traefik

volumes:
  wiki_data:
  wiki_db_data:
```

**Usage:**

```bash
# Access at: https://wiki.yourdomain.com
# Login with credentials
# Create pages for generated docs
# Search and navigate
```

---

### Option C: Gitbook (Cloud-Based)

**What is Gitbook:**
- Cloud-hosted knowledge base
- Beautiful UI
- GitHub integration
- Real-time sync from Git repo
- Search and navigation

**Architecture:**

```
Your Laptop
    ↓
AI generates docs locally
    ↓
Commit to Git
    ↓
Push to GitHub
    ↓
Gitbook auto-syncs from GitHub
    ↓
Beautiful published knowledge base
```

**Setup:**

```bash
# 1. Create GitHub repo: my-campaign-docs
# 2. Push generated docs there
# 3. Connect to Gitbook
# 4. Gitbook auto-publishes from GitHub
# 5. Auto-updates when you push

# Result: https://myname.gitbook.io/campaign-docs/
```

**Pros:**
- No infrastructure needed
- Beautiful auto-generated UI
- Great search
- Versioning built-in

**Cons:**
- Free tier limited
- Paid: $10-40/month
- Cloud-hosted (not self-hosted)

---

## Part 5: AI Documentation Generation Workflow

### Ideal Workflow (Containerized)

```
┌─────────────────────────────────────────────────┐
│  User in Claude Code terminal (on VPS)          │
├─────────────────────────────────────────────────┤
│                                                 │
│  claude                                         │
│  > "Generate deployment guide for CI/CD"       │
│  > Claude writes to file:                       │
│    /srv/campaign-stack/docs/ci-cd-guide.md    │
│                                                 │
│  > "Create troubleshooting guide"              │
│  > Claude writes to file:                       │
│    /srv/campaign-stack/docs/troubleshooting.md│
│                                                 │
│  > "Extract key concepts as glossary"          │
│  > Claude writes to file:                       │
│    /srv/campaign-stack/docs/glossary.md       │
│                                                 │
└─────────────────────────────────────────────────┘
            ↓
    All files persisted to:
    /srv/campaign-stack/docs/
            ↓
┌─────────────────────────────────────────────────┐
│  Knowledge Management System                    │
│  (Obsidian / Wiki.js / Gitbook)                │
│                                                 │
│  - Auto-discover new files                     │
│  - Index and search                            │
│  - Display with nice UI                        │
│  - Link related documents                      │
│  - Version control                             │
└─────────────────────────────────────────────────┘
```

---

## Part 6: Recommendation

### Best Architecture: Hybrid Approach

**Container-Based Components:**
1. ✅ WordPress (container)
2. ✅ MySQL (container)
3. ✅ Traefik (container)
4. ✅ Portainer (container)
5. ✅ Wiki.js (container - NEW)

**Host-Based Components:**
1. ⚠️ AI CLI tools (on host, but could containerize)
2. ✅ Documentation storage (host filesystem, synced to containers)

**Knowledge Management:**
- ✅ **Wiki.js** (containerized, self-hosted)
- Stores all AI-generated docs
- Searchable and indexed
- Beautiful UI
- Fits container philosophy

---

## Part 7: Implementation Plan

### Phase 1: Current (Now)
```
Host OS
├─ Docker containers (WordPress, MySQL, etc.)
├─ AI CLI on host (claude, chatgpt, etc.)
└─ Docs stored in: /srv/campaign-stack/docs/
```

**Works, but not fully containerized**

### Phase 2: Add Wiki.js (Recommended)
```
Containers:
├─ Traefik
├─ WordPress
├─ MySQL
├─ Wiki.js (NEW) ← Knowledge base
└─ Portainer

Volumes:
├─ /srv/campaign-stack/docs/ (mounted to Wiki.js)
└─ /srv/campaign-stack/wiki-data/ (Wiki.js storage)
```

**Adds knowledge management, keeps AI on host**

### Phase 3: Full Containerization (Optional)
```
Containers:
├─ Traefik
├─ WordPress
├─ MySQL
├─ Wiki.js
├─ AI Provider (NEW) ← Containerized claude/chatgpt
└─ Portainer

# Run: docker-compose exec ai-provider claude
```

**100% containerized, scalable**

---

## Part 8: Persistent Storage Strategy

### Current Problem

**Without persistent storage:**
```
Session 1: claude > Generate guide
           ↓ (file created)
           
User closes SSH
           ↓
Session 2: claude > Generate deployment
           ↓ (file created)
           
No easy way to:
- Find all generated docs
- Search across docs
- Link docs together
- Version docs
```

### Solution: Managed Docs Volume

**docker-compose.yaml:**

```yaml
volumes:
  docs_generated:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /srv/campaign-stack/docs

services:
  wiki:
    volumes:
      - docs_generated:/data/pages  # Wiki reads from here
      
  wordpress:
    volumes:
      - docs_generated:/app/docs    # WordPress can read too
```

**Result:**
```
/srv/campaign-stack/docs/
├─ AI-generated docs live here
├─ Persisted to host filesystem
├─ Mounted into Wiki.js container
├─ Searchable and indexed
├─ Version controlled with git
└─ Backed up with system backups
```

---

## Part 9: Complete Recommended Architecture

```
┌─────────────────────────────────────────────────────────┐
│              VPS (Ubuntu 22.04)                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Persistent Volumes                                     │
│  ├─ /srv/campaign-stack/docs/                          │
│  ├─ /srv/campaign-stack/wordpress_data/                │
│  ├─ /srv/campaign-stack/mysql_data/                    │
│  └─ /srv/campaign-stack/wiki_data/                     │
│                                                         │
│  Docker Containers                                      │
│  ├─ Traefik (reverse proxy, SSL)                       │
│  ├─ WordPress + PHP + Apache                           │
│  ├─ MySQL (database)                                   │
│  ├─ Wiki.js (knowledge base)                           │
│  ├─ Wiki.js PostgreSQL (wiki database)                 │
│  └─ Portainer (container management)                   │
│                                                         │
│  Host-Based Tools                                       │
│  ├─ Docker & Docker Compose                            │
│  ├─ AI CLI (Claude, ChatGPT, etc.)                      │
│  ├─ Git (version control)                              │
│  └─ Bash (orchestration)                               │
│                                                         │
└─────────────────────────────────────────────────────────┘

                        ↓ SSH Access
                        
┌─────────────────────────────────────────────────────────┐
│              Your Laptop/Desktop                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ├─ SSH Terminal (run AI CLI on VPS host)              │
│  ├─ Browser (access Wiki.js at wiki.domain.com)        │
│  ├─ Obsidian (optional: local vault sync)              │
│  └─ Git Client (sync docs to GitHub)                   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Part 10: Persistent Storage for Docs

### How Docs Get Persisted

```
1. User runs: claude
2. Claude generates: architecture-guide.md
3. User saves to: /srv/campaign-stack/docs/
4. File persists on host filesystem
5. Wiki.js container reads from mount
6. Wiki.js indexes and displays
7. Can search and navigate

# File lives at:
# Host: /srv/campaign-stack/docs/architecture-guide.md
# Container: /data/pages/architecture-guide.md (mounted)
# Accessible: https://wiki.yourdomain.com/architecture-guide
```

### Backup Strategy

```
/srv/campaign-stack/docs/ 
    ↓ Daily backup to Storj (or S3)
    ↓ Weekly backup to GitHub
    ↓ Monthly backup to local machine
    
Result: Docs never lost
```

---

## Part 11: Should You Use Obsidian vs Wiki.js?

### Obsidian

**Best if:**
- You want markdown on your laptop
- You like local-first approach
- You want powerful search/linking
- You prefer desktop app
- You work offline often

**Workflow:**
```
VPS /docs/ ← SFTP → Obsidian vault ← Local editing
```

### Wiki.js

**Best if:**
- You want web-based knowledge base
- You want team collaboration
- You want professional UI
- You want everything containerized
- You want to share publicly

**Workflow:**
```
VPS /docs/ → Wiki.js container → https://wiki.domain.com
```

### Recommendation: Use Both!

```
/srv/campaign-stack/docs/
    ├─ Syncs to: Your laptop Obsidian vault
    ├─ Mounted in: Wiki.js container
    ├─ Pushed to: GitHub
    
Result:
- Edit in Obsidian locally
- Share via Wiki.js web
- Version control via GitHub
- Synced automatically
```

---

## Summary

### Does Multi-Provider AI Make Sense in Containers?

✅ **YES**, but with caveats:
- AI CLI tools currently run on host (not containerized)
- Could be containerized (optional improvement)
- Works well for ad-hoc coding assistance
- Good access to WordPress/project files

### Persistent Documentation Storage?

✅ **ABSOLUTELY NEEDED**:
- Without it, generated docs are lost
- No knowledge management
- No version control
- No discovery mechanism

### Recommended Setup

1. ✅ Keep AI CLI on host (simple, works well)
2. ✅ Add Wiki.js container (knowledge management)
3. ✅ Store docs in /srv/campaign-stack/docs/ (persistent)
4. ✅ Mount to Wiki.js (searchable)
5. ✅ Sync to GitHub (version control)
6. ✅ Optional: Obsidian sync (local editing)

### Files Generated by AI Should Live In:
```
/srv/campaign-stack/docs/
├─ Mounted to Wiki.js container
├─ Persisted to host filesystem
├─ Backed up daily
├─ Version controlled with git
└─ Accessible via wiki.yourdomain.com
```

