# VPS Requirements & Shopping Guide

## Overview

This guide helps you choose the right VPS specifications for running Campaign Stack with all modules (Core + ACBC + Chatbot).

**Note:** The stack includes CiviCRM (constituent relationship management), not ERPNext. CiviCRM is specifically designed for political campaigns and nonprofits.

## Quick Recommendation

**For a small campaign (5-20 active users):**
- **Without local AI:** 4 vCPU, 8GB RAM, 160GB SSD → $24-40/month
- **With local AI (Ollama):** 6 vCPU, 16GB RAM, 240GB SSD → $48-80/month

**Scroll down for detailed breakdown and Black Friday providers.**

## What's Running in Full Stack

### Core Stack (Always Running)
- **WordPress** - Campaign website, blog
- **CiviCRM** - Donor/volunteer/contact management (runs inside WordPress)
- **MySQL 8.0** - WordPress/CiviCRM database
- **Traefik** - Reverse proxy with HTTPS
- **Wiki.js** - Knowledge management + PostgreSQL database
- **Portainer** - Container management UI
- **Backup Service** - Daily backups to Storj

### ACBC Module (Beta)
- **LimeSurvey** - Survey platform (Apache + PHP)
- **ACBC MySQL Database** - Voter intelligence data
- **Analytics Engine** - Python/Flask API
- **Admin Dashboard** - Node.js app

### Chatbot Module (Beta)
- **Chatbot MySQL Database** - Conversation logs
- **AI Router** - Python/Flask API (routes queries)
- **Wiki.js Connector** - Python/Flask API (fetches content)
- **Ollama** (Optional) - Local AI models (VERY resource-intensive)

**Total Services:** 15+ Docker containers

## Resource Breakdown

### CPU Requirements

| Service | CPU Usage | Notes |
|---------|-----------|-------|
| WordPress + PHP-FPM | 0.5-1 vCPU | Spikes during page loads |
| CiviCRM | 0.5-1 vCPU | Complex queries can spike |
| MySQL (WordPress) | 1-2 vCPU | Depends on query complexity |
| MySQL (ACBC) | 0.5-1 vCPU | Lower traffic initially |
| MySQL (Chatbot) | 0.5-1 vCPU | Grows with conversations |
| Wiki.js + PostgreSQL | 0.5-1 vCPU | Moderate usage |
| LimeSurvey | 0.5 vCPU | Burst during survey submissions |
| Python Services (3x) | 0.5-1 vCPU | AI router, analytics, Wiki connector |
| Traefik | 0.1-0.2 vCPU | Very light |
| **Ollama (local AI)** | **2-4 vCPU** | **Heavy during inference** |
| **Total without Ollama** | **4-6 vCPU** | Recommended: 4 minimum, 6 comfortable |
| **Total with Ollama** | **6-10 vCPU** | Recommended: 6 minimum, 8 comfortable |

### RAM Requirements

| Service | RAM Usage | Notes |
|---------|-----------|-------|
| WordPress + PHP-FPM | 512MB-1GB | Multiple PHP workers |
| CiviCRM | 512MB-1GB | Added to WordPress memory |
| MySQL (WordPress) | 1-2GB | InnoDB buffer pool |
| MySQL (ACBC) | 512MB-1GB | Smaller dataset initially |
| MySQL (Chatbot) | 512MB | Conversation logs |
| Wiki.js + PostgreSQL | 512MB-1GB | Content caching |
| LimeSurvey | 512MB | Apache + PHP |
| Python Services (3x) | 256MB each | Flask apps are lightweight |
| Traefik + Portainer | 256MB | Very light |
| OS + Overhead | 512MB-1GB | Ubuntu base |
| **Ollama + Models** | **4-8GB** | **Model loaded in memory** |
| **Total without Ollama** | **6-8GB minimum** | **8-12GB recommended** |
| **Total with Ollama** | **12-16GB minimum** | **16-24GB recommended** |

### Storage Requirements

| Component | Storage | Notes |
|-----------|---------|-------|
| Ubuntu OS | 10GB | Base system |
| Docker Images | 10-15GB | All containers |
| WordPress Files | 5-10GB | Themes, plugins, uploads |
| CiviCRM Data | 2-5GB | Contact database grows |
| Wiki.js Content | 1-2GB | Pages, uploads |
| MySQL Data (3 DBs) | 5-15GB | Grows with usage |
| LimeSurvey Data | 2-3GB | Survey responses |
| Logs | 2-5GB | Application logs |
| Local Backups | 5-10GB | Before Storj upload |
| **Ollama Models** | **4-20GB per model** | **llama2: 4GB, llama3: 8GB, codellama: 7GB** |
| **Total without Ollama** | **60-80GB minimum** | **120-160GB recommended** |
| **Total with Ollama** | **100-120GB minimum** | **200-240GB recommended** |

### Network Requirements

| Metric | Requirement | Notes |
|--------|-------------|-------|
| Bandwidth | 2-3TB/month | Moderate campaign traffic |
| Port Speed | 1Gbps | Standard for most VPS |
| Latency | <50ms domestic | Better user experience |

## Recommended VPS Tiers

### Tier 1: Small Campaign (Basic)
**Use Case:** Small campaign, 5-20 users, cloud AI only (no Ollama)

**Specifications:**
- **CPU:** 4 vCPU (or 2 dedicated cores)
- **RAM:** 8GB
- **Storage:** 160GB SSD
- **Bandwidth:** 2-4TB/month

**What Runs:**
- ✅ Full core stack
- ✅ ACBC module
- ✅ Chatbot with OpenAI/Anthropic APIs
- ❌ Ollama (use cloud APIs instead)

**Cost:** $24-40/month

**Who It's For:**
- Local/small campaigns
- Limited concurrent users
- Willing to pay ~$15-20/month for AI API usage

**Example Providers:**
- Hetzner CPX31: 4 vCPU, 8GB RAM, 160GB, €13.40/month (~$14)
- Linode Dedicated 8GB: 4 vCPU, 8GB RAM, 160GB, $36/month
- Vultr High Frequency 8GB: 4 vCPU, 8GB RAM, 180GB, $48/month

### Tier 2: Medium Campaign (Recommended)
**Use Case:** Medium campaign, 20-50 users, local AI + cloud fallback

**Specifications:**
- **CPU:** 6 vCPU (or 3 dedicated cores)
- **RAM:** 16GB
- **Storage:** 240GB SSD
- **Bandwidth:** 4-6TB/month

**What Runs:**
- ✅ Full core stack
- ✅ ACBC module
- ✅ Chatbot with Ollama (local AI)
- ✅ Cloud API fallback for complex queries
- ✅ Comfortable performance
- ✅ Room for growth

**Cost:** $48-80/month

**Who It's For:**
- State/regional campaigns
- 20-50 concurrent users
- Want to minimize AI API costs
- Need consistent performance

**Example Providers:**
- Hetzner CPX41: 8 vCPU, 16GB RAM, 240GB, €26.40/month (~$29) ⭐ **BEST VALUE**
- Linode Dedicated 16GB: 8 vCPU, 16GB RAM, 320GB, $72/month
- DigitalOcean Dedicated 16GB: 8 vCPU, 16GB RAM, 320GB, $96/month

### Tier 3: Large Campaign (High Performance)
**Use Case:** Large campaign, 50-100+ users, heavy AI usage

**Specifications:**
- **CPU:** 8-12 vCPU (or 4-6 dedicated cores)
- **RAM:** 24-32GB
- **Storage:** 320-480GB SSD
- **Bandwidth:** 6-10TB/month

**What Runs:**
- ✅ Full stack with headroom
- ✅ Multiple Ollama models loaded
- ✅ High concurrent user capacity
- ✅ Fast AI responses
- ✅ Heavy analytics workloads

**Cost:** $80-150/month

**Who It's For:**
- Statewide/federal campaigns
- 50-100+ concurrent users
- Heavy chatbot usage
- Complex ACBC analytics
- Need guaranteed performance

**Example Providers:**
- Hetzner CCX33: 8 vCPU, 32GB RAM, 240GB, €51.90/month (~$57) ⭐ **BEST PERFORMANCE/PRICE**
- Linode Dedicated 32GB: 16 vCPU, 32GB RAM, 640GB, $144/month
- DigitalOcean Dedicated 32GB: 16 vCPU, 32GB RAM, 640GB, $192/month

## Black Friday VPS Providers (November 2024)

### 🏆 Top Picks for Campaign Stack

#### 1. Hetzner Cloud ⭐ BEST VALUE
**Why:** Exceptional price/performance, European data centers, excellent uptime

**Black Friday Expectations:** 15-20% off, free credits
**Locations:** Germany, Finland, USA (Ashburn, VA)
**Pros:**
- ✅ Best price/performance ratio
- ✅ High-quality hardware (AMD EPYC, NVMe SSD)
- ✅ Excellent network (20Gbps)
- ✅ Simple, transparent pricing
- ✅ Great for Docker workloads

**Cons:**
- ⚠️ Primarily European (but has US datacenter)
- ⚠️ Support is email-only (but very good)

**Recommended Plan:** CPX41 (8 vCPU, 16GB, 240GB) @ €26.40/month (~$29)

**Black Friday Deal:** Watch for https://www.hetzner.com/black-friday

#### 2. Linode (Akamai Cloud) - RELIABLE
**Why:** Excellent uptime, great support, now backed by Akamai

**Black Friday Expectations:** $100-200 free credits, 20-30% off annual plans
**Locations:** 11 global locations including US
**Pros:**
- ✅ Rock-solid reliability (99.99% uptime)
- ✅ Excellent 24/7 support
- ✅ Simple pricing, no surprises
- ✅ Good documentation
- ✅ Dedicated CPU plans ideal for databases

**Cons:**
- ⚠️ More expensive than Hetzner
- ⚠️ Network speeds lower than Hetzner

**Recommended Plan:** Dedicated 16GB (8 vCPU, 16GB, 320GB) @ $72/month

**Black Friday Deal:** Watch for https://www.linode.com/lp/black-friday/

#### 3. DigitalOcean - BEGINNER FRIENDLY
**Why:** Easiest to use, excellent documentation, marketplace apps

**Black Friday Expectations:** $200-300 credits for new accounts
**Locations:** 15 global regions
**Pros:**
- ✅ Extremely user-friendly interface
- ✅ Best documentation and tutorials
- ✅ 1-click backups and snapshots
- ✅ Large community
- ✅ Managed databases available

**Cons:**
- ⚠️ More expensive than competitors
- ⚠️ Support quality varies

**Recommended Plan:** Dedicated 16GB (8 vCPU, 16GB, 320GB) @ $96/month

**Black Friday Deal:** Watch for https://www.digitalocean.com/

#### 4. Vultr - GOOD PERFORMANCE
**Why:** Fast hardware, competitive pricing, many locations

**Black Friday Expectations:** 30-50% off first month, free credits
**Locations:** 25+ global locations
**Pros:**
- ✅ High-frequency compute (good CPU performance)
- ✅ Competitive pricing
- ✅ DDoS protection included
- ✅ Block storage available

**Cons:**
- ⚠️ Support can be slow
- ⚠️ Network occasionally inconsistent

**Recommended Plan:** High Frequency 16GB (4 vCPU, 16GB, 260GB) @ $96/month

**Black Friday Deal:** Watch for https://www.vultr.com/

#### 5. Contabo - ULTRA BUDGET
**Why:** Extremely cheap, high specs

**Black Friday Expectations:** Extra RAM/storage upgrades
**Locations:** USA, Germany, UK, Singapore
**Pros:**
- ✅ Incredibly cheap (VPS L: 8 vCPU, 30GB RAM, 800GB @ $13.99/month!)
- ✅ Generous resources
- ✅ Good for testing/development

**Cons:**
- ⚠️ Oversold servers (performance can vary)
- ⚠️ Poor support reputation
- ⚠️ Network speeds inconsistent
- ⚠️ **NOT recommended for production campaigns**

**Use Case:** Testing beta features, development environments only

**Recommended Plan:** VPS L (8 vCPU, 30GB RAM, 800GB) @ $13.99/month

**Black Friday Deal:** Watch for https://contabo.com/

### 🇪🇺 European-Only Options

#### OVH/OVHcloud
**Locations:** France, Canada, USA
**Pros:** Very cheap, huge company, good network
**Cons:** Complex interface, support quality varies
**Black Friday:** Usually 20-30% off VPS plans
**Recommended:** Comfort (4 vCPU, 8GB, 160GB) @ €30-40/month

#### Scaleway
**Locations:** France, Netherlands, Poland
**Pros:** Competitive pricing, modern platform
**Cons:** Smaller company, limited US presence
**Black Friday:** Watch for instance credits

## Comparison Table

| Provider | Tier 2 Equivalent | Monthly Cost | Annual Cost | Support | Uptime SLA |
|----------|------------------|--------------|-------------|---------|------------|
| **Hetzner** | CPX41: 8/16GB/240GB | $29 | $348 | Email | 99.9% |
| **Linode** | Dedicated 16GB: 8/16GB/320GB | $72 | $864 | 24/7 | 99.99% |
| **DigitalOcean** | Dedicated 16GB: 8/16GB/320GB | $96 | $1,152 | 24/7 | 99.99% |
| **Vultr** | HF 16GB: 4/16GB/260GB | $96 | $1,152 | Ticket | 99.9% |
| **Contabo** | VPS L: 8/30GB/800GB | $14 | $168 | Email | None |

## Calculating Total Cost

### Example: Medium Campaign on Hetzner

**VPS Cost:**
- Hetzner CPX41: €26.40/month = $29/month

**AI API Costs (if not using Ollama):**
- OpenAI GPT-4o-mini: ~$15-30/month (1000 conversations)
- Anthropic Claude Haiku: ~$10-20/month (1000 conversations)

**Total with Cloud AI:** $44-59/month
**Total with Ollama (local):** $29/month

**Annual Cost:**
- VPS: $348/year
- AI APIs: $180-360/year
- **Total: $528-708/year**

**Black Friday Savings:**
- 20% off Hetzner: Save ~$70/year
- $200 DigitalOcean credit: 2 months free
- $100 Linode credit: 1.4 months free

## Special Considerations

### Ollama vs Cloud AI Decision

**Use Ollama (local AI) if:**
- ✅ You can afford 16GB+ RAM VPS
- ✅ Expect >500 chatbot conversations/month
- ✅ Want predictable costs
- ✅ Privacy is important
- ✅ Budget allows $48-80/month VPS

**Use Cloud AI if:**
- ✅ Budget limited to $24-40/month VPS
- ✅ Expect <500 conversations/month
- ✅ Want best AI quality (Claude/GPT-4)
- ✅ OK with variable costs
- ✅ Don't mind data sent to OpenAI/Anthropic

**Hybrid Approach (Best):**
- 16GB VPS with Ollama
- Ollama for simple queries (70% of traffic) = Free
- Cloud API for complex queries (30%) = ~$5-10/month
- **Total: $48-80 VPS + $5-10 API = $53-90/month**

### Geographic Considerations

**US Campaigns:**
- Choose US-based or low-latency providers
- Hetzner Ashburn, VA (good)
- Linode/DigitalOcean US regions (better)
- Avoid pure European providers (higher latency)

**European Campaigns:**
- Hetzner Germany/Finland (best value)
- OVH France
- Scaleway

### Bandwidth Needs

**Estimate your traffic:**
- Small campaign: 500-1000 visitors/day = 1-2TB/month
- Medium campaign: 2000-5000 visitors/day = 3-5TB/month
- Large campaign: 10,000+ visitors/day = 8-12TB/month

Most providers include 2-6TB free, sufficient for most campaigns.

## Black Friday Shopping Checklist

- [ ] Determine your campaign size (users, traffic expectations)
- [ ] Decide: Local AI (Ollama) or Cloud AI?
- [ ] Calculate budget: VPS + AI costs
- [ ] Choose tier (1, 2, or 3) based on needs
- [ ] Sign up for Black Friday alerts:
  - [ ] Hetzner newsletter
  - [ ] Linode emails
  - [ ] DigitalOcean notifications
  - [ ] Vultr promotions
- [ ] Compare annual vs monthly pricing
- [ ] Check for student/nonprofit discounts
- [ ] Review provider's refund policy
- [ ] Test with small VPS first, upgrade later
- [ ] Consider annual commitment for bigger discount

## Money-Saving Tips

### 1. Start Small, Scale Up
**Strategy:** Begin with Tier 1, monitor usage, upgrade if needed
- Month 1-2: Test with 4 vCPU, 8GB ($24-40)
- Month 3: Analyze resource usage
- Month 4+: Upgrade if consistently >80% RAM/CPU

**Savings:** $24-40/month vs $48-80/month = $288-480/year

### 2. Annual Commitments
**Discounts:**
- Hetzner: No discount (monthly only)
- Linode: 10% off annual
- DigitalOcean: ~5% off annual

**Caveat:** Only commit annually if sure of provider

### 3. Use Cloud AI Initially
**Strategy:** Start without Ollama, add later if needed
- Month 1-3: Use 4 vCPU, 8GB + OpenAI API
- Monitor chatbot usage
- If >500 conversations/month, upgrade + add Ollama

### 4. Black Friday Credits
**Best deals:**
- DigitalOcean: Usually $200 credit (2-3 months free on Tier 2)
- Linode: Usually $100 credit (1-2 months free)
- Vultr: Usually $100-150 credit

**Strategy:** Sign up during Black Friday, use credits, then decide

### 5. Nonprofit Discounts
Many campaigns are nonprofits or can partner with one:
- DigitalOcean for Nonprofits: $1,200/year credit
- Google Cloud for Nonprofits: $10,000/year credit
- AWS Activate for Nonprofits: Credits available

## Final Recommendations

### Best Overall Value
**Hetzner CPX41** (8 vCPU, 16GB, 240GB) @ $29/month
- Runs full stack with Ollama comfortably
- Best price/performance ratio
- European company (GDPR compliant)
- Excellent for Docker workloads

### Best for US Campaigns
**Linode Dedicated 16GB** @ $72/month
- Excellent US presence and support
- Rock-solid uptime
- 24/7 support for mission-critical campaigns
- Simple, predictable pricing

### Best for Beginners
**DigitalOcean Dedicated 8GB** @ $48/month (without Ollama)
- Easiest interface
- Best documentation
- 1-click features
- Good community support
- Wait for $200 Black Friday credit

### Best Budget Option
**Hetzner CPX31** (4 vCPU, 8GB, 160GB) @ $14/month
- Runs core stack + ACBC + Chatbot (cloud AI only)
- Amazing value
- Good for small campaigns
- Easy to upgrade later

### NOT Recommended
**Contabo** - Too unreliable for production campaigns
- OK for testing only
- Don't risk your campaign on oversold servers

## Monitoring & Scaling

### Set Up Monitoring

**Use Portainer** (included):
- Monitor CPU/RAM usage per container
- Watch for consistently high usage (>80%)
- Identify bottlenecks

**Commands to check resources:**
```bash
# Overall usage
docker stats

# Disk space
df -h

# Memory usage
free -h

# Top processes
htop
```

### When to Upgrade

**Upgrade if you see:**
- ⚠️ RAM >80% consistently
- ⚠️ CPU >80% during normal hours
- ⚠️ Disk >80% full
- ⚠️ Slow response times (>3 sec page loads)
- ⚠️ MySQL queries timing out
- ⚠️ Out of memory errors in logs

**How to upgrade:**
Most providers allow easy resizing:
1. Take snapshot/backup
2. Resize VPS (usually 1-5 min downtime)
3. Reboot and verify

## Conclusion

**For most campaigns, we recommend:**

**Tier 2: Hetzner CPX41** @ $29/month
- Perfect balance of cost and performance
- Runs full stack including Ollama
- Room to grow
- Amazing value

**Alternative: Linode Dedicated 16GB** @ $72/month
- If you need US-based hosting
- If you want premium support
- If reliability is paramount

**Start here, scale up if needed!**

---

**Questions about VPS selection?** Create a GitHub issue with the `question` label.

**Black Friday Tips:** Sign up for provider newsletters NOW to get early Black Friday access!
