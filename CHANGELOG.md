# Changelog

All notable changes to Campaign Stack will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### In Development (develop branch)
- Future features for v2.5.0+

## [2.4.0-beta.1] - 2024-11-21 (Beta Testing)

### Added - ACBC Voter Intelligence Module (Phase 1)
- LimeSurvey integration for ACBC survey data collection
- Database schema for voter utilities, segments, and engagement profiles
- Analytics engine for calculating voter preferences
- Admin dashboard for monitoring segment analytics
- CiviCRM integration points for contact tracking
- Dual domain routing support for admin interfaces
- Complete documentation in acbc-module/docs/

### Added - AI Policy Chatbot Module (Phase 1)
- Multi-backend AI routing service (Ollama, Anthropic, OpenAI, Google)
- Intelligent query routing based on complexity and budget
- Wiki.js GraphQL connector for policy content fetching
- Sophistication detection for adaptive explanations
- Budget controls and cost tracking
- Database schema for conversations, analytics, and misconceptions
- Privacy-first design with GDPR/CCPA compliance
- Complete documentation in chatbot-module/docs/

### Added - Development Infrastructure
- Branching strategy documentation (BRANCHING_STRATEGY.md)
- Migration guide for proper git flow (MIGRATION_TO_BRANCHES.md)
- Automated migration script (scripts/migrate-to-branches.sh)
- Beta testing guidelines in README

### Changed
- Repository organized with master (stable), beta (testing), develop (dev) branches
- README updated with branch structure and installation options
- Version numbering follows semantic versioning

### Status
⚠️ **Beta Release** - These features are untested in production environments. Deploy on test VPS only. Report issues via GitHub.

## [2.3.0] - 2024-11-21 (Stable)

### Added
- Web-based GUI installer for non-technical users
  - Visual installation wizard with progress tracking
  - Real-time API key validation
  - Post-installation management panel
  - Complete documentation in web-installer/

- API key validation for AI providers
  - Validates Anthropic, OpenAI, Google API keys with real endpoint tests
  - Integrated into CLI installer (scripts/install-campaign-stack.sh)
  - Integrated into GUI installer (web-installer/validate-key.php)
  - Integrated into AI provider switching script (scripts/install-ai-provider.sh)
  - Returns specific error codes (0=valid, 1=invalid, 2=network error)

- Git workflow documentation
  - BRANCHING_STRATEGY.md with complete git flow guidelines
  - MIGRATION_TO_BRANCHES.md with step-by-step migration guide
  - Branch migration automation script
  - GitHub setup instructions

### Changed
- Repository structure reorganized
  - Architecture docs moved to docs/architecture/
  - Changelogs moved to docs/
  - All scripts consolidated in scripts/ directory (removed root duplicates)
  - Removed 4 duplicate scripts from repository root

- Domain examples replaced with generic examples
  - Changed from personal domains (markcampaign.com) to generic (janedoeforcongress.com)
  - Updated CiviCRM installer to use variables for dual domain whitelist
  - Removed Really Simple Security references (paywalled, not used)

- README improvements
  - Added credits summary with link to full CREDITS.md
  - Updated with all new documentation locations
  - Branch structure explanation
  - Beta testing guide

### Fixed
- Docker Compose image validation when AI provider skipped
  - Added Alpine placeholder image to ai_provider service
  - Prevents build validation errors when using profiles

- Script path detection improved
  - install-campaign-stack.sh now works from root or scripts/ directory
  - Proper REPO_DIR detection with conditional logic

- Docker Compose pull command corrected
  - Changed from explicit service list to automatic profile exclusion
  - Prevents "no configuration file" errors

### Documentation
- README.md: Added branch structure, beta testing guide, installation options
- BRANCHING_STRATEGY.md: Complete git workflow and contribution guidelines
- MIGRATION_TO_BRANCHES.md: Step-by-step branch migration guide
- BRANCH_NOTICE.md: Branch consolidation explanation
- GITHUB_SETUP_INSTRUCTIONS.md: Repository configuration guide
- CREDITS.md: Full acknowledgments and credits
- Updated all documentation with correct paths

### Infrastructure
- All core services tested and stable
- WordPress, CiviCRM, Traefik, MySQL, Wiki.js functioning properly
- Automated backups to Storj working
- Dual domain support tested
- HTTPS with Let's Encrypt verified
- Web installer tested on fresh Ubuntu installations

## [2.2.0] - 2024-11 (Prior Stable)

### Added
- Dual domain support (separate public and backend domains)
- CiviCRM installation automation
- Storj backup integration
- AI provider support (Ollama, Anthropic, OpenAI, Google)

### Core Stack
- WordPress 6.x with CiviCRM integration
- Traefik reverse proxy with automatic HTTPS
- MySQL 8.0 database
- Wiki.js knowledge management
- Portainer container management

## Version Numbering

Campaign Stack follows [Semantic Versioning](https://semver.org/):

- **MAJOR.MINOR.PATCH** (e.g., 2.3.0)
  - MAJOR: Breaking changes, major architecture updates
  - MINOR: New features, backward-compatible
  - PATCH: Bug fixes, security patches

- **Beta versions**: MAJOR.MINOR.PATCH-beta.N (e.g., 2.4.0-beta.1)
- **Release candidates**: MAJOR.MINOR.PATCH-rc.N (e.g., 2.4.0-rc.1)

## Release Branches

- `master` - Stable production releases (currently v2.3.0)
- `beta` - Release candidates for testing (currently v2.4.0-beta.1)
- `develop` - Active development (v2.5.0+ features)

See [BRANCHING_STRATEGY.md](BRANCHING_STRATEGY.md) for complete git workflow.

## Links

- [Repository](https://github.com/mkld0910/campaign-stack)
- [Issues](https://github.com/mkld0910/campaign-stack/issues)
- [Releases](https://github.com/mkld0910/campaign-stack/releases)
- [Documentation](README.md)

---

**Legend:**
- ✅ Stable and tested
- ⚠️ Beta - needs testing
- 🚧 In development
