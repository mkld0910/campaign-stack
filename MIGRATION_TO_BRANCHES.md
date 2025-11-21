# Migration to Proper Branch Structure

## Current Situation

We've pushed untested features (ACBC and Chatbot modules) directly to master. This is not ideal for production deployments.

## Solution

Reorganize into proper branch structure:
- `master` = Stable, production-ready (v2.3.0)
- `beta` = Latest features for testing (v2.4.0-beta.1)
- `develop` = Active development

## Step-by-Step Migration

### Step 1: Tag Current Master as Beta

Current master has untested ACBC and Chatbot modules, so tag it as beta:

```bash
cd /path/to/campaign-stack

# Tag current state as beta
git tag -a v2.4.0-beta.1 -m "Beta release: ACBC and Chatbot modules (untested)"
git push origin v2.4.0-beta.1
```

### Step 2: Create Beta Branch

Create beta branch from current master (contains all features):

```bash
# Create and push beta branch
git checkout -b beta
git push origin beta

# Return to master
git checkout master
```

### Step 3: Create Develop Branch

Create develop branch from current master:

```bash
# Create and push develop branch
git checkout -b develop
git push origin develop

# Return to master
git checkout master
```

### Step 4: Revert Master to Stable Version

Master should only have tested, production-ready code. Last stable commit was `ff7719b` (before ACBC module):

```bash
# Create revert commit to remove untested features
git revert --no-commit 5714b25  # Revert Chatbot
git revert --no-commit 4f559df  # Revert ACBC dual domain fix
git revert --no-commit 3b9b6b1  # Revert ACBC README update
git revert --no-commit cd08487  # Revert ACBC module

# Commit the reverts
git commit -m "Revert untested modules from master

Move ACBC and Chatbot modules to beta branch for testing.
Master remains at v2.3.0 with only tested features.

Untested features available on beta branch for early adopters.

See BRANCHING_STRATEGY.md for branch usage guidelines."

# Push to master
git push origin master
```

### Step 5: Tag Stable Master

Tag the now-stable master as v2.3.0:

```bash
git tag -a v2.3.0 -m "Stable release v2.3.0

Includes:
- Core stack (WordPress, CiviCRM, Traefik, MySQL, Wiki.js)
- Web-based GUI installer
- Automated backups to Storj
- Dual domain support
- API key validation for AI providers
- Repository reorganization
- Branch migration guides"

git push origin v2.3.0
```

### Step 6: Update README on Master

Update README.md on master to explain branch structure:

```bash
# Add section to README about branches
# (Edit README.md - see below)

git add README.md
git commit -m "docs: Add branch structure explanation to README"
git push origin master
```

### Step 7: Verify Branch Structure

```bash
# List all branches
git branch -a

# Should show:
# * master (stable - v2.3.0)
#   beta (untested features - v2.4.0-beta.1)
#   develop (active development)

# List tags
git tag

# Should show:
#   v2.3.0 (master)
#   v2.4.0-beta.1 (beta)
```

### Step 8: Set Default Branch on GitHub

1. Go to https://github.com/mkld0910/campaign-stack/settings
2. Under "Default branch", change from `master` to `master` (confirm it's set)
3. Enable branch protection for master:
   - Settings → Branches → Add rule
   - Branch name pattern: `master`
   - ✅ Require pull request reviews before merging
   - ✅ Require status checks to pass
   - Save changes

## README Section to Add

Add this section to README.md on master branch:

```markdown
## Branch Structure

Campaign Stack uses multiple branches for stability and development:

### 🟢 master (Stable - Production Ready)
**Current Version:** v2.3.0
**Status:** ✅ Tested and stable
**Use for:** Production campaign deployments

```bash
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
# Master is default branch
bash scripts/install-campaign-stack.sh
```

**Includes:**
- Core stack (WordPress, CiviCRM, Traefik, MySQL, Wiki.js)
- Web-based GUI installer
- Automated backups
- Dual domain support
- API key validation

### 🟡 beta (Beta Testing)
**Current Version:** v2.4.0-beta.1
**Status:** ⚠️ Beta - needs testing
**Use for:** Early adopters, beta testers

```bash
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
git checkout beta
bash scripts/install-campaign-stack.sh
bash scripts/install-acbc-module.sh
bash scripts/install-chatbot-module.sh
```

**Additional Features:**
- ACBC Voter Intelligence Module (Phase 1)
- AI Policy Chatbot Module (Phase 1)

**⚠️ Warning:** These modules are untested in production. Use at your own risk.

### 🔵 develop (Development)
**Status:** 🚧 Active development
**Use for:** Contributors, developers

```bash
git clone https://github.com/mkld0910/campaign-stack.git
cd campaign-stack
git checkout develop
```

**For developers:** See [BRANCHING_STRATEGY.md](BRANCHING_STRATEGY.md) for contribution guidelines.

---

**Not sure which branch to use?**
- **Production campaign → master**
- **Want to test new features → beta**
- **Contributing code → develop**

See [BRANCHING_STRATEGY.md](BRANCHING_STRATEGY.md) for complete documentation.
```

## After Migration

### For Production Users
Nothing changes - they'll continue using master (v2.3.0 stable).

### For Beta Testers
They can switch to beta branch to test new modules:
```bash
git checkout beta
git pull origin beta
bash scripts/install-acbc-module.sh
bash scripts/install-chatbot-module.sh
```

### For Developers
Create feature branches from develop:
```bash
git checkout develop
git checkout -b feature/my-new-feature
# Make changes
git push origin feature/my-new-feature
# Create PR to develop
```

## Timeline

1. **Immediate**: Create branches and tags (Steps 1-7)
2. **Week 1-2**: Beta testing of ACBC and Chatbot modules
3. **Week 3**: Collect feedback, fix bugs on beta
4. **Week 4**: If stable, merge beta → master, tag as v2.4.0

## Questions?

**Q: What happens to people who already cloned master with ACBC/Chatbot?**
A: Their local master will have the modules. They can:
- Keep using it (it works, just untested)
- Switch to beta: `git checkout beta`
- Update to stable master: `git pull origin master`

**Q: Can I still use the new modules?**
A: Yes! They're on the beta branch. Just `git checkout beta`.

**Q: When will ACBC/Chatbot be on master?**
A: After 2-4 weeks of beta testing with no critical issues.

---

**Ready to migrate?** Run the commands in Steps 1-7 above.
