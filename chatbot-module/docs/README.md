# AI Policy Chatbot Module

## Overview

The AI Policy Chatbot Module provides intelligent, adaptive policy explanations to voters through a multi-backend AI system integrated with Wiki.js knowledge management. It serves dual purposes: voter education and campaign intelligence gathering.

## What It Does

- **Adaptive Explanations**: Same policy explained differently based on voter sophistication
- **Multi-Backend AI**: Routes queries to optimal AI backend (local/cloud) based on complexity and budget
- **Wiki.js Integration**: Single source of truth for policy content via GraphQL API
- **Campaign Intelligence**: Tracks misconceptions, engagement patterns, and message effectiveness
- **Privacy-First**: Opt-in data collection with full GDPR/CCPA compliance
- **CiviCRM Integration**: Logs interactions for voter profiling and follow-up

## Architecture

```
┌─────────────────┐
│  WordPress      │  ← Kognetiks Chatbot Plugin (Frontend)
└────────┬────────┘
         │
         ↓ REST API
┌─────────────────┐
│  AI Router      │  ← Routes queries based on complexity/budget
└────────┬────────┘
         │
         ├─→ Local Models (Ollama) - Free, fast, privacy-focused
         ├─→ Anthropic Claude - Complex reasoning
         ├─→ OpenAI GPT - General queries
         └─→ Google Gemini - Fallback option
         │
         ↓ fetches content
┌─────────────────┐
│   Wiki.js       │  ← Policy knowledge base (GraphQL API)
└────────┬────────┘
         │
         ↓ logs interaction
┌─────────────────┐
│   CiviCRM       │  ← Voter engagement tracking
└─────────────────┘
```

## Key Features

### 1. Multi-Backend AI Router

**Routing Logic:**
- **Simple queries** (<50 tokens, factual) → Local model (Ollama)
- **Medium queries** (50-200 tokens, explanations) → Cost-efficient API (OpenAI GPT-4o-mini)
- **Complex queries** (>200 tokens, nuanced reasoning) → Advanced model (Claude Sonnet)

**Budget Controls:**
- Hard monthly spending limits per backend
- Automatic fallback to local models when budget exceeded
- Real-time cost tracking and alerts
- Token-based usage analytics

### 2. Wiki.js Knowledge Integration

**Content Structure:**
```markdown
# Policy: Healthcare Reform

Tags: healthcare, policy-priority, complexity:medium
Region: National
Last Updated: 2024-11-21

## Simple Explanation (Low-Info Voters)
[Accessible overview with analogies]

## Detailed Explanation (Medium-Info Voters)
[Policy specifics with examples]

## Technical Explanation (High-Info Voters)
[Full policy details, research citations]

## Local Context: {Region}
[Regional examples and impact]

## Common Misconceptions
- Misconception: [false belief]
  Reality: [accurate explanation]
```

**GraphQL Integration:**
- Real-time content fetching from Wiki.js
- Page versioning and update tracking
- Tag-based content filtering
- Full-text search capabilities

### 3. Adaptive Explanation Engine

**Sophistication Detection:**
Analyzes question phrasing to determine voter knowledge level:

- **Low-info indicators**: "explain like I'm 5", "in simple terms", basic vocabulary
- **Medium-info indicators**: specific policy terms, comparison questions
- **High-info indicators**: technical language, implementation details, research references

**Response Adaptation:**
Same question, different explanations:

**Q: "How does your healthcare plan work?"**

*Low-info response:*
> "Think of it like a safety net. Right now, if you lose your job, you might lose healthcare. Our plan makes sure you're always covered, like having car insurance even when you switch cars."

*Medium-info response:*
> "Our healthcare plan creates a public option that competes with private insurance. It's funded through progressive taxation and allows anyone to buy in, regardless of employment status. Pre-existing conditions are fully covered."

*High-info response:*
> "The plan establishes a Medicare-like public option with negotiated drug pricing (targeting 40% reduction via bulk purchasing). Funding comes from closing corporate tax loopholes ($250B/10yr) and a 2% wealth tax on assets >$50M. CBO scoring projects 15M coverage expansion over 5 years."

### 4. Campaign Intelligence Features

**Misconception Tracking:**
```json
{
  "misconception_id": "hc_001",
  "false_belief": "Plan eliminates private insurance",
  "frequency": 147,
  "regions": ["District 5", "District 12"],
  "trend": "increasing",
  "corrected_explanation": "Plan creates public option alongside private insurance"
}
```

**Engagement Metrics:**
- Questions per session
- Conversation depth (follow-up questions)
- Topic areas of interest
- Satisfaction indicators (question resolution)

**A/B Message Testing:**
- Track which explanations lead to follow-up engagement
- Measure clarity scores based on follow-up confusion
- Optimize messaging based on real voter understanding

## Installation

### Quick Start

```bash
cd /srv/campaign-stack
bash scripts/install-chatbot-module.sh
```

### Manual Installation

```bash
# Pull latest code
git pull origin master

# Deploy chatbot services
docker compose -f compose.yaml -f compose-chatbot.yaml up -d

# Verify services
docker compose -f compose.yaml -f compose-chatbot.yaml ps
```

## Access Points

After installation, access points depend on your domain configuration:

### Single Domain Configuration
- **Chatbot (Frontend)**: `https://yourdomain.com` (embedded in WordPress)
- **AI Router API**: `https://chatbot-api.yourdomain.com`
- **Analytics Dashboard**: `https://chatbot.yourdomain.com`

### Dual Domain Configuration
- **Chatbot (Frontend)**: `https://yourdomain.com` (public)
- **AI Router API**: `https://chatbot-api.admin.yourdomain.com` (backend)
- **Analytics Dashboard**: `https://chatbot.admin.yourdomain.com` (backend)

## Configuration

### 1. Install Kognetiks Chatbot Plugin

The installer automatically downloads and configures the Kognetiks Chatbot for WordPress plugin.

**Post-Installation Steps:**
1. Log into WordPress admin
2. Navigate to Plugins → Chatbot Settings
3. Configure API endpoints (auto-configured by installer)
4. Customize appearance and behavior
5. Enable privacy consent features

### 2. Structure Wiki.js Content

**Required Tags:**
- `complexity:simple` - Low-info voter content
- `complexity:medium` - Medium-info voter content
- `complexity:detailed` - High-info voter content
- `policy-priority` - Core campaign policies
- `region:{name}` - Regional content

**Recommended Structure:**
```
/policies
  /healthcare
  /environment
  /economy
  /education
/faqs
  /common-questions
  /misconceptions
/local-context
  /district-1
  /district-2
```

### 3. Configure AI Backends

Edit `.env` to set up AI providers:

```bash
# AI Router Configuration
CHATBOT_ENABLED=true
CHATBOT_DEFAULT_BACKEND=ollama  # ollama, anthropic, openai, google

# Budget Controls (USD per month)
CHATBOT_MONTHLY_BUDGET=100
CHATBOT_ANTHROPIC_BUDGET=50
CHATBOT_OPENAI_BUDGET=30
CHATBOT_GOOGLE_BUDGET=20

# Routing Thresholds
CHATBOT_SIMPLE_TOKENS=50
CHATBOT_COMPLEX_TOKENS=200

# Privacy Settings
CHATBOT_REQUIRE_CONSENT=true
CHATBOT_ANONYMIZE_DATA=true
CHATBOT_DATA_RETENTION_DAYS=90
```

### 4. CiviCRM Integration

The installer creates custom fields in CiviCRM:

**Custom Fields:**
- `chatbot_sessions` - Number of chatbot interactions
- `chatbot_topics` - Policy areas discussed (multi-select)
- `chatbot_sophistication` - Detected knowledge level (1-5 scale)
- `chatbot_last_interaction` - Last conversation date
- `chatbot_consent` - Privacy opt-in status

**Automatic Actions:**
- Create/update contact on first chatbot use
- Log conversation topics to contact record
- Trigger follow-up workflows based on topics discussed
- Segment contacts by policy interests

## Development Phases

### ✅ Phase 1: Foundation (Weeks 1-2)

**Included in Initial Release:**
- Basic chat interface (Kognetiks plugin)
- Wiki.js GraphQL connector
- Single AI backend (Ollama local model)
- Privacy consent workflow
- Core policy Q&A functionality
- Basic CiviCRM logging

**Deliverables:**
- Functional chatbot on WordPress site
- Wiki.js content fetching
- Conversation logging
- Privacy compliance

### Phase 2: Intelligence (Weeks 3-4)

**Features:**
- Multi-backend AI routing with cost controls
- Adaptive explanation levels (sophistication detection)
- Enhanced CiviCRM engagement logging
- Basic analytics dashboard

**Implementation:**
- Query complexity analyzer
- Backend selection algorithm
- Cost tracking system
- Admin dashboard UI

### Phase 3: Optimization (Weeks 5-6)

**Features:**
- Advanced misconception analytics
- Performance optimization (caching, CDN)
- ACBC data pipeline integration
- Campaign staff monitoring tools

**Implementation:**
- Misconception detection ML model
- Redis caching layer
- ACBC cross-referencing
- Staff analytics portal

## API Endpoints

### Chat API

```bash
POST /api/chat
Content-Type: application/json

{
  "message": "How does your healthcare plan work?",
  "session_id": "uuid",
  "contact_id": "civicrm_contact_id",  # optional
  "consent": true,
  "context": {
    "page": "healthcare-policy",
    "region": "District 5"
  }
}

Response:
{
  "response": "Our healthcare plan creates...",
  "sophistication_level": "medium",
  "backend_used": "ollama",
  "cost": 0.00,
  "sources": [
    {
      "title": "Healthcare Reform Policy",
      "url": "https://wiki.yourdomain.com/policies/healthcare",
      "excerpt": "..."
    }
  ],
  "follow_up_suggestions": [
    "How is the plan funded?",
    "What about pre-existing conditions?"
  ]
}
```

### Analytics API

```bash
GET /api/analytics/misconceptions

Response:
{
  "period": "last_30_days",
  "top_misconceptions": [
    {
      "id": "hc_001",
      "false_belief": "Plan eliminates private insurance",
      "occurrences": 147,
      "regions": ["District 5", "District 12"],
      "trend": "increasing",
      "correction_effectiveness": 0.73
    }
  ]
}
```

See [API.md](./API.md) for complete reference.

## Database Schema

Core tables:

- `chatbot_conversations` - Full conversation logs
- `chatbot_messages` - Individual messages
- `chatbot_misconceptions` - Tracked false beliefs
- `chatbot_analytics` - Aggregated metrics
- `chatbot_costs` - Backend usage and costs
- `chatbot_ab_tests` - Message testing results

See [SCHEMA.md](./SCHEMA.md) for complete schema documentation.

## Privacy & Compliance

### Data Collection

**With Consent:**
- Full conversation logs
- Contact ID linking (if authenticated)
- Sophistication profiling
- Topic interest tracking

**Without Consent (Anonymous):**
- Aggregated misconception data
- General topic popularity
- No personally identifiable information

### GDPR/CCPA Compliance

- **Right to Access**: Download all chatbot data via CiviCRM
- **Right to Deletion**: Purge conversation history on request
- **Right to Opt-Out**: Disable tracking at any time
- **Data Retention**: Configurable retention period (default: 90 days)

### Consent Workflow

```
[User visits site]
  ↓
[Chatbot widget appears]
  ↓
[Privacy banner shown on first interaction]
  "This chatbot helps answer policy questions. We'd like to
   save our conversation to better understand voter concerns.
   [Learn More] [Accept] [Decline]"
  ↓
[Accept] → Full logging enabled, CiviCRM integration
[Decline] → Anonymous mode, aggregated data only
```

## Cost Management

### Budget Monitoring

Real-time dashboard showing:
- Monthly spending by backend
- Cost per conversation
- Token usage trends
- Budget remaining
- Projected monthly total

### Automatic Controls

When budget limit reached:
1. Alert campaign staff
2. Switch to free local models
3. Optional: Rate limit conversations
4. Continue service without interruption

### Cost Optimization

**Average Costs (estimates):**
- **Ollama (local)**: $0.00 per query
- **OpenAI GPT-4o-mini**: $0.001 per query
- **Anthropic Claude Sonnet**: $0.015 per query
- **Google Gemini**: $0.003 per query

**Typical Usage:**
- 1,000 conversations/month
- 70% local model (free)
- 20% OpenAI ($2/month)
- 10% Anthropic ($15/month)
- **Total: ~$17/month**

## Monitoring & Metrics

### Key Performance Indicators

- **Engagement Rate**: % of visitors who interact with chatbot
- **Conversation Depth**: Average messages per session (target: >3)
- **Topic Coverage**: % of policies discussed
- **Misconception Detection**: False beliefs identified per week
- **Cost Efficiency**: Cost per meaningful conversation (<$0.05)

### Dashboard Metrics

- Total conversations (daily/weekly/monthly)
- Active topics trending
- Misconceptions by region
- Sophistication distribution
- Backend usage breakdown
- Budget consumption rate

## Troubleshooting

### Chatbot Not Responding

```bash
# Check AI router status
docker compose -f compose.yaml -f compose-chatbot.yaml ps ai_router

# View logs
docker compose -f compose.yaml -f compose-chatbot.yaml logs ai_router

# Test health endpoint
curl https://chatbot-api.yourdomain.com/health
```

### Wiki.js Connection Issues

```bash
# Test GraphQL endpoint
curl -X POST https://wiki.yourdomain.com/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{"query": "{ pages { list { title } } }"}'

# Check connector logs
docker logs chatbot_wikijs_connector
```

### High API Costs

```bash
# View cost breakdown
curl https://chatbot-api.yourdomain.com/api/analytics/costs

# Adjust routing thresholds to use more local models
# Edit .env:
CHATBOT_SIMPLE_TOKENS=100  # Increase to route more to local
CHATBOT_COMPLEX_TOKENS=300  # Increase threshold for expensive models

# Restart services
docker compose -f compose.yaml -f compose-chatbot.yaml restart
```

## Support & Documentation

- **Setup Guide**: [SETUP.md](./SETUP.md)
- **Kognetiks Configuration**: [KOGNETIKS.md](./KOGNETIKS.md)
- **Wiki.js Integration**: [WIKIJS_INTEGRATION.md](./WIKIJS_INTEGRATION.md)
- **CiviCRM Integration**: [CIVICRM_INTEGRATION.md](./CIVICRM_INTEGRATION.md)
- **API Reference**: [API.md](./API.md)
- **Schema Documentation**: [SCHEMA.md](./SCHEMA.md)
- **Troubleshooting**: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

## Strategic Value

### For Voters

- **24/7 Availability**: Get policy answers anytime
- **No Judgment**: Safe space to ask "basic" questions
- **Personalized**: Explanations match understanding level
- **Interactive**: Follow-up questions encouraged

### For Campaign

- **Continuous Focus Group**: Real-time voter understanding metrics
- **Message Refinement**: Data-driven explanation improvement
- **Resource Scaling**: AI handles what staff can't
- **Intelligence Gathering**: Identify concerns before they spread

### Integration with Campaign Stack

**Synergies:**
- **Wiki.js**: Policy content management
- **CiviCRM**: Voter relationship tracking
- **ACBC Module**: Quantitative + qualitative intelligence
- **Mautic**: Trigger personalized follow-ups based on chatbot topics

**Example Workflow:**
1. Voter asks about healthcare via chatbot
2. Chatbot detects medium sophistication, provides detailed explanation
3. CiviCRM tagged with "healthcare interest"
4. ACBC survey invitation sent if voter shows high engagement
5. Mautic sends healthcare-focused email sequence
6. Campaign refines healthcare messaging based on misconception data

## License

Part of Campaign Stack - MIT License

See main project [LICENSE](../../LICENSE) for details.

## Credits

- **Kognetiks Chatbot**: WordPress chatbot plugin
- **Wiki.js**: Knowledge management platform
- **Ollama**: Local AI model infrastructure
- **Campaign Stack**: Integration framework

---

**Version**: 1.0 (Phase 1)
**Last Updated**: November 2024
**Status**: Beta - Phase 1 Implementation Ready
