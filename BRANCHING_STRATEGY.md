# Branching Strategy

## Overview

Campaign Stack uses a **Git Flow-inspired** branching strategy to ensure stability for production deployments while enabling rapid development and beta testing.

## Branch Structure

### `master` (Production)
- **Purpose**: Stable, production-ready code only
- **Status**: Deployable at any time
- **Merges from**: `beta` branch (after testing)
- **Protected**: Yes - requires pull request and testing
- **Used by**: Production campaign deployments

**Installation:**
```bash
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
# Uses master by default
bash scripts/install-campaign-stack.sh
```

### `develop` (Development)
- **Purpose**: Integration branch for active development
- **Status**: Latest features, may have bugs
- **Merges from**: Feature branches
- **Merges to**: `beta` (when ready for testing)
- **Used by**: Developers working on new features

**Installation:**
```bash
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
git checkout develop
bash scripts/install-campaign-stack.sh
```

### `beta` (Beta Testing)
- **Purpose**: Release candidates for community testing
- **Status**: Feature-complete, undergoing testing
- **Merges from**: `develop` (when features ready)
- **Merges to**: `master` (when testing passes)
- **Used by**: Beta testers, early adopters

**Installation:**
```bash
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
git checkout beta
bash scripts/install-chatbot-module.sh  # Test new features
```

### `feature/*` (Feature Branches)
- **Purpose**: Individual feature development
- **Naming**: `feature/feature-name`
- **Merges to**: `develop`
- **Lifespan**: Deleted after merge
- **Examples**:
  - `feature/acbc-module`
  - `feature/chatbot-module`
  - `feature/email-integration`

## Workflow

### For New Features

```bash
# 1. Create feature branch from develop
git checkout develop
git pull origin develop
git checkout -b feature/my-new-feature

# 2. Develop and commit
git add .
git commit -m "Add feature: description"

# 3. Push feature branch
git push origin feature/my-new-feature

# 4. Create Pull Request to develop
# (via GitHub UI)

# 5. After PR approval, feature merges to develop
# 6. Delete feature branch
git branch -d feature/my-new-feature
git push origin --delete feature/my-new-feature
```

### For Beta Releases

```bash
# 1. Merge develop to beta when ready
git checkout beta
git merge develop
git push origin beta

# 2. Announce beta testing period
# 3. Collect feedback, fix bugs
# 4. Hot fixes go directly to beta

# 5. When testing passes, tag beta release
git tag -a v2.4.0-beta.1 -m "Beta release for ACBC and Chatbot modules"
git push origin v2.4.0-beta.1
```

### For Production Releases

```bash
# 1. Merge beta to master when ready
git checkout master
git merge beta
git push origin master

# 2. Tag production release
git tag -a v2.4.0 -m "Release: ACBC and Chatbot modules"
git push origin v2.4.0

# 3. Create GitHub Release
# (via GitHub UI with release notes)
```

### For Hotfixes

```bash
# 1. Create hotfix branch from master
git checkout master
git checkout -b hotfix/critical-bug

# 2. Fix the bug
git commit -m "Fix: critical bug description"

# 3. Merge to both master and develop
git checkout master
git merge hotfix/critical-bug
git push origin master

git checkout develop
git merge hotfix/critical-bug
git push origin develop

# 4. Tag hotfix release
git tag -a v2.3.1 -m "Hotfix: critical bug"
git push origin v2.3.1

# 5. Delete hotfix branch
git branch -d hotfix/critical-bug
```

## Version Numbering

We use **Semantic Versioning** (semver): `MAJOR.MINOR.PATCH`

- **MAJOR** (v3.0.0): Breaking changes, major architecture updates
- **MINOR** (v2.4.0): New features, backward-compatible
- **PATCH** (v2.3.1): Bug fixes, security patches

**Beta versions**: `v2.4.0-beta.1`, `v2.4.0-beta.2`
**Release candidates**: `v2.4.0-rc.1`

## Current Version Status

### Version 2.3.x (Stable - Master Branch)
- ✅ Core stack (WordPress, CiviCRM, Traefik, MySQL, Wiki.js)
- ✅ Web-based installer
- ✅ Automated backups to Storj
- ✅ Dual domain support
- ✅ API key validation

### Version 2.4.0-beta (Beta Branch)
- 🧪 ACBC Voter Intelligence Module (Phase 1)
- 🧪 AI Policy Chatbot Module (Phase 1)
- ⚠️ **Needs Testing**: Database migrations, API integrations, cost controls

### Version 2.5.0 (Planned - Develop Branch)
- 📋 ACBC Module Phase 2 (CiviCRM deep integration)
- 📋 Chatbot Module Phase 2 (Enhanced AI routing)
- 📋 Mautic email marketing integration
- 📋 Advanced analytics dashboard

## Branch Protection Rules

### Master Branch
- ✅ Require pull request reviews (1 approver minimum)
- ✅ Require status checks to pass
- ✅ Require branches to be up to date
- ✅ No force pushes
- ✅ No deletions

### Beta Branch
- ✅ Require pull request reviews (1 approver minimum)
- ⚠️ Allow force pushes (for rebasing only)

### Develop Branch
- ⚠️ No protection (rapid development)

## Installation Instructions by Use Case

### For Production Campaigns (Stable)
```bash
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
# Master branch is default
bash scripts/install-campaign-stack.sh
```

### For Beta Testing (Latest Features)
```bash
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
git checkout beta
bash scripts/install-campaign-stack.sh
# Then test new modules:
bash scripts/install-acbc-module.sh
bash scripts/install-chatbot-module.sh
```

### For Development (Contributing)
```bash
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
git checkout develop
# Create feature branch
git checkout -b feature/my-contribution
# Make changes, test locally, submit PR
```

## Migration Plan (Retroactive)

Since we've already pushed ACBC and Chatbot modules to master, here's how to reorganize:

### Step 1: Tag Current Master as Beta
```bash
# Current master has untested features
git tag -a v2.4.0-beta.1 -m "Beta: ACBC and Chatbot modules (untested)"
git push origin v2.4.0-beta.1
```

### Step 2: Create Beta Branch from Current Master
```bash
git checkout -b beta
git push origin beta
```

### Step 3: Create Develop Branch
```bash
git checkout -b develop
git push origin develop
```

### Step 4: Revert Master to Last Stable Version
```bash
git checkout master
# Find last stable commit (before ACBC/Chatbot)
git log --oneline
# Revert to stable commit
git revert <commit-hash-of-acbc> <commit-hash-of-chatbot>
# Or create new commit that removes untested features
git push origin master
```

### Step 5: Tag Stable Master
```bash
git tag -a v2.3.0 -m "Stable release: Core stack with web installer"
git push origin v2.3.0
```

## Contributing Guidelines

### For External Contributors

1. **Fork the repository**
2. **Clone your fork**
3. **Create feature branch** from `develop`
4. **Make changes** and commit
5. **Push to your fork**
6. **Create Pull Request** to `develop` branch
7. **Wait for review** and address feedback
8. **Merge** when approved

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(chatbot): Add multi-backend AI routing

Implements intelligent query routing based on complexity.
Routes simple queries to Ollama, complex to Claude.

Closes #123
```

```
fix(acbc): Correct dual domain routing for LimeSurvey

LimeSurvey admin was using PUBLIC_DOMAIN instead of BACKEND_DOMAIN.
Now properly routes to backend domain when configured.

Fixes #456
```

## Testing Requirements

### Before Merging to Beta
- ✅ Local installation test (fresh Ubuntu VPS)
- ✅ Docker build succeeds
- ✅ Services start without errors
- ✅ Basic functionality test
- ✅ Documentation updated

### Before Merging to Master
- ✅ Beta testing period (minimum 2 weeks)
- ✅ At least 3 successful deployments by beta testers
- ✅ No critical bugs reported
- ✅ Performance benchmarks met
- ✅ Security review completed
- ✅ Documentation complete and accurate

## Release Checklist

- [ ] All features tested in beta
- [ ] CHANGELOG.md updated
- [ ] Version bumped in relevant files
- [ ] Documentation updated
- [ ] Migration guide written (if needed)
- [ ] Breaking changes documented
- [ ] Git tag created
- [ ] GitHub Release created with notes
- [ ] Announcement prepared

## Questions?

- **Which branch should I use?**
  - Production: `master`
  - Beta testing: `beta`
  - Development: `develop`

- **How do I report bugs?**
  - Create GitHub Issue with branch name and version
  - Include logs and reproduction steps

- **How do I request features?**
  - Create GitHub Issue with `enhancement` label
  - Describe use case and proposed solution

---

**Last Updated**: November 2024
**Current Stable Version**: v2.3.0
**Current Beta Version**: v2.4.0-beta.1
