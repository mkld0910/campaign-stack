# ACBC Voter Intelligence Module

## Overview

The ACBC (Adaptive Choice-Based Conjoint) Voter Intelligence Module adds sophisticated voter analytics and personalization capabilities to Campaign Stack.

## What It Does

- **Survey Engine**: LimeSurvey integration for ACBC data collection
- **Voter Matching**: Links survey responses to voter file records
- **Utility Calculation**: Determines voter preferences and priorities
- **Segmentation**: Automatically groups voters by profile
- **Personalization**: Delivers targeted content based on voter preferences
- **Analytics Dashboard**: Real-time monitoring and insights

## Architecture

```
┌─────────────────┐
│   LimeSurvey    │  ← Voter takes ACBC survey
└────────┬────────┘
         │
         ↓ webhook
┌─────────────────┐
│ Analytics Engine│  ← Calculates utilities
└────────┬────────┘
         │
         ↓ writes
┌─────────────────┐
│   ACBC Database │  ← Stores results
└────────┬────────┘
         │
         ↓ syncs
┌─────────────────┐
│    CiviCRM      │  ← Updates contact records
└─────────────────┘
```

## Installation

### Quick Start

```bash
cd /srv/campaign-stack
bash scripts/install-acbc-module.sh
```

### Manual Installation

```bash
# Pull latest code
git pull origin master

# Deploy ACBC services
docker compose -f compose.yaml -f compose-acbc.yaml up -d

# Verify services
docker compose -f compose.yaml -f compose-acbc.yaml ps
```

## Access Points

After installation:

- **LimeSurvey Admin**: `https://survey.yourdomain.com/admin`
- **ACBC Dashboard**: `https://acbc.yourdomain.com`
- **Analytics API**: `https://acbc-api.yourdomain.com`

## Configuration

### 1. LimeSurvey Setup

1. Log into LimeSurvey admin (credentials in CREDENTIALS_BACKUP.txt)
2. Install ACBC plugin (see LIMESURVEY_SETUP.md)
3. Create your first ACBC survey
4. Configure webhook to analytics engine

### 2. CiviCRM Integration

1. Create custom fields in CiviCRM (see CIVICRM_INTEGRATION.md)
2. Configure API access
3. Test data sync

### 3. Voter File Integration

1. Upload voter file to secure location
2. Configure matching service
3. Test matching accuracy

## Data Flow

### Survey Completion

1. Voter completes ACBC survey on LimeSurvey
2. Webhook triggers analytics engine
3. Engine calculates utility scores
4. Match to voter file record
5. Update CiviCRM contact
6. Assign to segments
7. Trigger personalization rules

### Segmentation

Automatic segmentation based on:
- Utility scores (policy priorities)
- Engagement profile (donor/volunteer/influencer)
- Trust affiliations
- Demographic data

### Personalization

Content delivery adapts to:
- Top policy priorities
- Preferred communication channel
- Engagement level
- Trusted messengers

## API Endpoints

### Survey Webhook

```bash
POST /webhooks/acbc-survey-complete
Content-Type: application/json

{
  "respondent_id": "abc123",
  "response_data": {...}
}
```

### Personalization API

```bash
GET /api/personalized-content/{contact_id}

Response:
{
  "content_blocks": ["environmental_wins", "local_impact"],
  "call_to_action": "join_task_force",
  "messaging": {...}
}
```

See [API.md](./API.md) for complete reference.

## Database Schema

Core tables:
- `acbc_surveys` - Survey responses and utilities
- `acbc_segments` - Voter segments
- `acbc_segment_members` - Segment membership
- `acbc_engagement_profiles` - Donor/volunteer profiles
- `acbc_personalization_rules` - Content rules

See [SCHEMA.md](./SCHEMA.md) for complete schema documentation.

## Development Phases

### Phase 1: Core Survey ✓ (Included)
- LimeSurvey deployment
- Basic database schema
- Analytics engine skeleton
- Admin dashboard

### Phase 2: Integration (Week 1-2)
- CiviCRM custom fields
- Voter file matching
- Webhook processing
- Segment sync

### Phase 3: Personalization (Week 2-3)
- Content rules engine
- API endpoints
- Template system
- A/B testing framework

### Phase 4: Analytics (Week 3-4)
- Advanced segmentation
- Predictive modeling
- Dashboard visualizations
- Performance optimization

## Monitoring & Metrics

### Key Performance Indicators

- **Survey completion rate**: Target >60%
- **Voter match rate**: Target >85%
- **Segment assignment**: Target >90%
- **API response time**: Target <200ms

### Dashboard Metrics

- Total surveys completed
- Active segments
- Segment sizes
- Engagement distribution
- Personalization effectiveness

## Troubleshooting

### LimeSurvey Not Loading

```bash
# Check container status
docker compose -f compose.yaml -f compose-acbc.yaml ps

# View logs
docker compose -f compose.yaml -f compose-acbc.yaml logs limesurvey

# Restart service
docker compose -f compose.yaml -f compose-acbc.yaml restart limesurvey
```

### Analytics Engine Errors

```bash
# Check logs
docker logs acbc_analytics

# Test health endpoint
curl https://acbc-api.yourdomain.com/health

# Restart engine
docker compose -f compose.yaml -f compose-acbc.yaml restart acbc_analytics
```

### Database Issues

```bash
# Access ACBC database
docker exec -it acbc_db mysql -u root -p

# Check tables
USE limesurvey;
SHOW TABLES LIKE 'acbc_%';

# View recent surveys
SELECT * FROM acbc_surveys ORDER BY completion_date DESC LIMIT 10;
```

## Security & Compliance

### Data Protection

- All PII encrypted at rest
- Voter file data access-controlled
- Survey responses anonymized in analytics
- GDPR/CCPA compliant data retention

### Access Control

- LimeSurvey: Role-based admin access
- Analytics API: Token authentication
- Dashboard: CiviCRM SSO integration
- Database: Firewall-protected, internal only

## Support & Documentation

- **Setup Guide**: [SETUP.md](./SETUP.md)
- **CiviCRM Integration**: [CIVICRM_INTEGRATION.md](./CIVICRM_INTEGRATION.md)
- **API Reference**: [API.md](./API.md)
- **Schema Documentation**: [SCHEMA.md](./SCHEMA.md)
- **Troubleshooting**: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

## License

Part of Campaign Stack - MIT License

See main project [LICENSE](../../LICENSE) for details.

## Credits

- **LimeSurvey**: Open-source survey platform
- **ACBC Methodology**: Sawtooth Software research
- **Campaign Stack**: Integration framework

---

**Version**: 1.0
**Last Updated**: November 2024
**Status**: Beta - Production Ready with Phase 1 features
