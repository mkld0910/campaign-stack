# Testing Guide for Beta Features

## Overview

This guide shows you how to test the ACBC Voter Intelligence and AI Policy Chatbot modules on the beta branch.

## ⚠️ Important Safety Notes

**DO NOT test on production VPS!**

- ✅ Use a separate test VPS for beta testing
- ✅ Use a test domain (e.g., test.yourdomain.com)
- ❌ Never test untested features on live campaign sites
- ❌ Never test with real voter data

## Testing Setup Options

### Option 1: Fresh Test VPS (Recommended)

Set up a completely separate VPS for testing:

**Cost:** ~$6-12 for one month (DigitalOcean, Linode)
**Benefit:** Zero risk to production, can destroy after testing

**Steps:**
1. Spin up new Ubuntu 22.04/24.04 VPS
2. Point test subdomain to new VPS
3. Install beta features
4. Test thoroughly
5. Destroy VPS when done

### Option 2: Same VPS, Different Directory (Advanced)

Run beta stack alongside production:

**Requirement:** Additional 2GB RAM, different ports
**Benefit:** Can compare side-by-side
**Risk:** Port conflicts, resource competition

**Not recommended unless you know Docker well**

### Option 3: Local Testing with Docker Desktop (Development)

Run on your Windows/Mac machine:

**Requirement:** Docker Desktop installed
**Benefit:** Fast iteration, no VPS cost
**Limitation:** Need local DNS setup, limited real-world testing

## 🚀 Quick Start: Testing Beta on Fresh VPS

### Step 1: Provision Test VPS

```bash
# Provider: DigitalOcean, Linode, Vultr, etc.
# OS: Ubuntu 22.04 or 24.04 LTS
# Size: 2 CPU, 4GB RAM minimum
# Cost: $6-12/month (destroy after testing)
```

### Step 2: Point Test Domain

Add DNS A record:
```
beta.yourdomain.com → TEST_VPS_IP
```

Wait 5-10 minutes for DNS propagation.

### Step 3: SSH into Test VPS

```bash
ssh root@TEST_VPS_IP
```

### Step 4: Install Beta Stack

```bash
# Clone repository
cd /srv
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack

# Switch to beta branch
git checkout beta

# Verify you're on beta
git branch --show-current
# Should output: beta

# View what's different
git log --oneline master..beta
# Shows commits only on beta (ACBC and Chatbot)

# Run installer
bash scripts/install-campaign-stack.sh
```

**During installation:**
- Use your test domain: `beta.yourdomain.com`
- Use test email addresses
- Select Ollama (local AI) for cost-free testing
- Note all credentials shown

### Step 5: Verify Base Installation

```bash
# Check all services running
docker compose ps

# Should see these running:
# - traefik
# - portainer
# - wordpress_mysql
# - wordpress_app
# - wiki_db
# - wiki
# - (ai_provider if you selected Ollama)
```

Visit your test site:
```
https://beta.yourdomain.com
```

Should see WordPress installation page.

## 🧪 Testing ACBC Module

### Install ACBC Module

```bash
cd /srv/campaign-stack
bash scripts/install-acbc-module.sh
```

**What it installs:**
- LimeSurvey (survey platform)
- ACBC database
- Analytics engine
- Admin dashboard

### Verify ACBC Installation

```bash
# Check ACBC services
docker compose -f compose.yaml -f compose-acbc.yaml ps

# Should see these ADDITIONAL services:
# - limesurvey
# - acbc_db
# - acbc_analytics
# - acbc_dashboard
```

### Access ACBC Services

Get credentials:
```bash
cat CREDENTIALS_BACKUP.txt | grep -A 10 "ACBC MODULE"
```

**Test each service:**

1. **LimeSurvey Admin:**
   ```
   URL: https://survey.beta.yourdomain.com/admin
   Username: admin
   Password: [from CREDENTIALS_BACKUP.txt]
   ```
   ✅ Should load LimeSurvey admin interface

2. **ACBC Dashboard:**
   ```
   URL: https://acbc.beta.yourdomain.com
   ```
   ✅ Should show "System Active" message

3. **Analytics API Health:**
   ```bash
   curl https://acbc-api.beta.yourdomain.com/health
   ```
   ✅ Should return: `{"status":"healthy"}`

### Test ACBC Database

```bash
# Access ACBC database
docker exec -it acbc_db mysql -u root -p

# Enter password from CREDENTIALS_BACKUP.txt (ACBC_DB_ROOT_PASSWORD)

# Check tables
USE limesurvey;
SHOW TABLES LIKE 'acbc_%';

# Should see:
# - acbc_surveys
# - acbc_segments
# - acbc_segment_members
# - acbc_personalization_rules
# - acbc_engagement_profiles
# - acbc_analytics_cache
# - acbc_webhook_log

# Check default segments
SELECT segment_name, description FROM acbc_segments;

# Should see 6 default segments like:
# - high_engagement
# - environmental_focus
# - economic_focus
# etc.

# Exit
exit
```

### What to Test in ACBC

**Basic Functionality:**
- [ ] LimeSurvey admin loads
- [ ] Can create a new survey in LimeSurvey
- [ ] Database has all required tables
- [ ] Default segments exist
- [ ] Analytics API responds to health check
- [ ] Dashboard loads

**Advanced Testing (if you have time):**
- [ ] Create simple survey in LimeSurvey
- [ ] Submit test survey response
- [ ] Check if webhook fires (view logs: `docker logs acbc_analytics`)
- [ ] Verify data in `acbc_surveys` table

**Known Limitations in Beta:**
- CiviCRM integration requires manual custom field setup
- Voter file matching not yet implemented
- Webhook processing is placeholder (Phase 2)

## 💬 Testing Chatbot Module

### Install Chatbot Module

```bash
cd /srv/campaign-stack
bash scripts/install-chatbot-module.sh
```

**During installation:**
- When asked about Wiki.js API key: Skip for now (or create one)
- When asked about Ollama: Say Yes (if not already installed)

**What it installs:**
- AI Router service
- Wiki.js connector
- Chatbot database
- Kognetiks WordPress plugin

### Verify Chatbot Installation

```bash
# Check chatbot services
docker compose -f compose.yaml -f compose-chatbot.yaml ps

# Should see these ADDITIONAL services:
# - chatbot_db
# - ai_router
# - wikijs_connector
```

### Access Chatbot Services

**Test each service:**

1. **AI Router API Health:**
   ```bash
   curl https://chatbot-api.beta.yourdomain.com/health
   ```
   ✅ Should return: `{"status":"healthy","backends_available":{...}}`

2. **Wiki.js Connector Health:**
   ```bash
   curl https://wikijs-connector.beta.yourdomain.com/health
   ```
   ✅ Should return: `{"status":"healthy"}`

### Test Chatbot Database

```bash
# Access chatbot database
docker exec -it chatbot_db mysql -u root -p

# Enter password from CREDENTIALS_BACKUP.txt (CHATBOT_DB_ROOT_PASSWORD)

# Check tables
USE chatbot;
SHOW TABLES;

# Should see:
# - chatbot_conversations
# - chatbot_messages
# - chatbot_misconceptions
# - chatbot_costs
# - chatbot_budget_tracking
# - chatbot_ab_tests
# - chatbot_analytics_daily
# - chatbot_wikijs_cache
# - chatbot_consent_log

# Check default misconceptions
SELECT misconception_key, false_belief FROM chatbot_misconceptions;

# Should see 4 default misconceptions:
# - hc_eliminate_private
# - env_job_loss
# - tax_middle_class
# - edu_free_unfair

# Exit
exit
```

### Test AI Router Directly

```bash
# Test chat endpoint with curl
curl -X POST https://chatbot-api.beta.yourdomain.com/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What is your healthcare policy?",
    "session_id": "test-123",
    "consent": true
  }'
```

✅ **Expected response:**
```json
{
  "response": "Our healthcare plan creates...",
  "session_id": "test-123",
  "sophistication_level": "medium",
  "backend_used": "ollama",
  "cost": 0.0,
  "tokens_used": 150,
  "processing_time_ms": 2500
}
```

### Activate Kognetiks Plugin in WordPress

1. Log into WordPress admin:
   ```
   https://beta.yourdomain.com/wp-admin
   ```

2. Go to: Plugins → Installed Plugins

3. Find "Chatbot" plugin

4. Click "Activate"

5. Go to: Settings → Chatbot

6. Configure:
   - **API Endpoint:** `https://chatbot-api.beta.yourdomain.com/api/chat`
   - **API Method:** POST
   - Enable chatbot widget
   - Customize appearance

7. Visit your site: `https://beta.yourdomain.com`

8. ✅ Should see chatbot widget in bottom right

### Test Chatbot Live

**On your website:**
1. Click chatbot widget
2. Type: "What is your healthcare policy?"
3. ✅ Should get AI response
4. Type follow-up: "How much does it cost?"
5. ✅ Should get another response

**Check database logged conversation:**
```bash
docker exec -it chatbot_db mysql -u chatbot -p
# Password from CREDENTIALS_BACKUP.txt (CHATBOT_DB_PASSWORD)

USE chatbot;

# View conversations
SELECT * FROM chatbot_conversations ORDER BY started_at DESC LIMIT 5;

# View messages
SELECT message_type, message_text, ai_backend, cost
FROM chatbot_messages
ORDER BY created_at DESC LIMIT 10;

# View costs
SELECT backend, SUM(cost_usd) as total_cost, COUNT(*) as queries
FROM chatbot_costs
GROUP BY backend;

exit
```

### What to Test in Chatbot

**Basic Functionality:**
- [ ] AI Router API responds
- [ ] Wiki.js connector responds
- [ ] Database has all required tables
- [ ] Default misconceptions exist
- [ ] Kognetiks plugin installs
- [ ] Chatbot widget appears on site

**Advanced Testing:**
- [ ] Chatbot responds to questions
- [ ] Conversations logged to database
- [ ] Different question types (simple, complex)
- [ ] Cost tracking works (if using paid APIs)
- [ ] Budget limits enforced (set low limit and exceed it)

**Known Limitations in Beta:**
- Wiki.js integration requires API key and structured content
- Sophistication detection is basic pattern matching (Phase 2 will improve)
- CiviCRM contact linking requires manual setup
- Misconception tracking needs manual review

## 📊 Testing Both Modules Together

Once both installed, test integration:

### Test 1: Chatbot with CiviCRM

1. Create a contact in CiviCRM
2. Note the contact ID
3. Use chatbot with that contact ID:
   ```bash
   curl -X POST https://chatbot-api.beta.yourdomain.com/api/chat \
     -H "Content-Type: application/json" \
     -d '{
       "message": "Tell me about your policies",
       "session_id": "test-456",
       "contact_id": 123,
       "consent": true
     }'
   ```
4. Check if conversation linked to contact in database

### Test 2: ACBC Survey → Chatbot Follow-up

**Workflow:**
1. User completes ACBC survey (shows interest in healthcare)
2. Survey data goes to `acbc_surveys` table
3. CiviCRM contact tagged with "healthcare interest"
4. Chatbot could prioritize healthcare topics for that contact

**How to test:**
- Create test survey in LimeSurvey
- Submit response
- Check `acbc_surveys` table for data
- Use chatbot and verify it could access that data

## 🔄 Switching Between Branches

### View Available Branches

```bash
cd /srv/campaign-stack
git branch -a

# Local branches:
#   beta
#   develop
# * master

# Remote branches:
#   remotes/origin/beta
#   remotes/origin/develop
#   remotes/origin/master
```

### Switch to Beta Branch

```bash
# Make sure no uncommitted changes
git status

# Switch to beta
git checkout beta

# Pull latest changes
git pull origin beta

# Verify
git branch --show-current
# Output: beta

# See what's new
git log master..beta --oneline
```

### Switch Back to Stable Master

```bash
git checkout master
git pull origin master

# Note: ACBC and Chatbot modules won't be in files
# Need to redeploy if switching on same VPS
```

### Install Specific Module Only

You can test modules individually:

**Only ACBC:**
```bash
git checkout beta
bash scripts/install-campaign-stack.sh  # Base stack
bash scripts/install-acbc-module.sh     # Just ACBC
# Skip chatbot
```

**Only Chatbot:**
```bash
git checkout beta
bash scripts/install-campaign-stack.sh     # Base stack
bash scripts/install-chatbot-module.sh     # Just Chatbot
# Skip ACBC
```

## 🐛 Troubleshooting

### Service Won't Start

```bash
# View logs for specific service
docker compose -f compose.yaml -f compose-acbc.yaml logs acbc_analytics

# Restart service
docker compose -f compose.yaml -f compose-acbc.yaml restart acbc_analytics
```

### Database Connection Errors

```bash
# Check database is running
docker compose -f compose.yaml -f compose-acbc.yaml ps acbc_db

# Check database logs
docker logs acbc_db

# Verify password in .env matches
grep ACBC_DB_PASSWORD .env
```

### API Not Responding

```bash
# Test internal network (from within container)
docker exec ai_router curl http://chatbot_db:3306

# Test external access
curl https://chatbot-api.beta.yourdomain.com/health

# Check Traefik logs
docker logs traefik
```

### Reset and Start Over

```bash
# Stop all services
docker compose -f compose.yaml -f compose-acbc.yaml -f compose-chatbot.yaml down

# Remove volumes (DESTROYS ALL DATA!)
docker volume prune

# Start fresh
bash scripts/install-campaign-stack.sh
bash scripts/install-acbc-module.sh
bash scripts/install-chatbot-module.sh
```

## 📋 Testing Checklist

### Pre-Testing
- [ ] Test VPS provisioned
- [ ] Test domain pointing to VPS
- [ ] SSH access confirmed
- [ ] NOT using production VPS

### Base Stack (master branch)
- [ ] Core services install successfully
- [ ] WordPress accessible
- [ ] CiviCRM installs
- [ ] Wiki.js accessible
- [ ] HTTPS working

### ACBC Module (beta branch)
- [ ] ACBC services install
- [ ] LimeSurvey admin accessible
- [ ] Database tables created
- [ ] Default segments exist
- [ ] Analytics API responds
- [ ] Dashboard loads

### Chatbot Module (beta branch)
- [ ] Chatbot services install
- [ ] AI Router API responds
- [ ] Wiki.js connector responds
- [ ] Database tables created
- [ ] Default misconceptions exist
- [ ] Kognetiks plugin activates
- [ ] Chatbot widget appears
- [ ] Chatbot responds to questions
- [ ] Conversations logged

### Integration
- [ ] Both modules running simultaneously
- [ ] No port conflicts
- [ ] Resource usage acceptable (<80% RAM/CPU)
- [ ] All domains resolve correctly

### Reporting
- [ ] Document what works
- [ ] Document what doesn't work
- [ ] Note any errors or warnings
- [ ] Check logs for issues
- [ ] Create GitHub issues for bugs

## 📝 Reporting Issues

When you find a bug:

1. **Create GitHub Issue:**
   - Go to: https://github.com/mkld0910/campaign-stack/issues/new
   - Add label: `beta`
   - Add label: `bug` or `enhancement`

2. **Include:**
   - Branch: `beta`
   - Module: `ACBC` or `Chatbot`
   - Expected behavior
   - Actual behavior
   - Steps to reproduce
   - Relevant logs
   - Your environment (Ubuntu version, RAM, CPU)

3. **Example Issue:**
   ```
   Title: [Beta] ACBC Analytics API returns 500 error

   **Branch:** beta
   **Module:** ACBC
   **Version:** v2.4.0-beta.1

   **Expected:** Analytics API health check returns 200
   **Actual:** Returns 500 Internal Server Error

   **Steps to reproduce:**
   1. Install ACBC module on Ubuntu 22.04
   2. curl https://acbc-api.domain.com/health
   3. Get 500 error

   **Logs:**
   ```
   docker logs acbc_analytics
   [error output here]
   ```

   **Environment:**
   - Ubuntu: 22.04
   - RAM: 4GB
   - Docker: 24.0.7
   ```

## 🎯 Next Steps After Testing

1. **Document your findings** in GitHub issues
2. **Share feedback** on what works well
3. **Suggest improvements** for documentation
4. **Wait for fixes** on beta branch
5. **Re-test** after updates
6. **Approve for production** when stable

---

**Questions?** Create a GitHub issue with the `question` label.

**Ready to test?** Start with a fresh VPS and follow the Quick Start section above!
