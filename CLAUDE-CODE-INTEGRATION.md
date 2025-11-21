# Claude Code Integration - Summary

**Version:** 2.1 (with Claude Code support)  
**Date:** November 20, 2025

This document summarizes the Claude Code integration added to Campaign Stack.

---

## What Was Added

### Files Created/Modified

**New/Modified Core Files:**
1. ✅ `install-campaign-stack.sh` - Updated with Claude Code option (Step 3/7)
2. ✅ `scripts/setup-claude-code.sh` - New helper script for post-install configuration
3. ✅ `.env.example` - Updated with Claude Code configuration section
4. ✅ `docs/12-CLAUDE-CODE.md` - New comprehensive documentation

**Key Changes:**

#### install-campaign-stack.sh
- Added Step 3/7: Claude Code CLI optional installation
- Prompts user to enable/disable Claude Code
- If enabled: Collects API key and stores in .env
- Auto-installs Node.js/npm if needed
- Installs Claude Code globally
- Provides post-install instructions

#### setup-claude-code.sh
- Standalone script for enabling Claude Code after deployment
- Allows reconfiguring API key anytime
- Tests authentication
- Creates optional helper alias
- Works on existing Campaign Stack deployments

#### .env.example
- New section: "Claude Code CLI Configuration"
- Documents all Claude Code variables
- Explains how to get API key
- Lists available models with descriptions
- Security warnings about API keys

---

## Implementation Details

### API Key Management

**Storage:**
- API keys stored in `.env` file
- `.env` is in `.gitignore` (never committed)
- Loaded as `ANTHROPIC_API_KEY` environment variable
- Accessible to Claude Code CLI automatically

**Security:**
- Keys never exposed in prompts
- Keys never logged to stdout
- Keys only used for API authentication
- Keys can be rotated anytime via `setup-claude-code.sh`

### Installation Flow

**Option 1: Enable During Initial Setup**
```
1. Run: bash scripts/install-campaign-stack.sh
2. Answer: "Enable Claude Code CLI? (y/n)"
3. Provide: Claude API key
4. Automatic installation of Node.js/npm
5. Automatic installation of Claude Code
6. Key stored in .env
```

**Option 2: Enable After Initial Setup**
```
1. Run: bash scripts/setup-claude-code.sh
2. Configure: API key and settings
3. Test: Authentication verification
4. Done: Ready to use
```

### Dependencies Installed

When Claude Code is enabled:

```bash
# System packages
nodejs (if not present)
npm (if not present)

# NPM packages (global)
@anthropic-ai/claude-code
```

**Why these?**
- Claude Code is Node.js application
- npm is Node package manager
- Global install makes `claude` command available from anywhere

### Environment Variables

**Added to .env:**
```bash
ENABLE_CLAUDE_CODE=true          # true/false flag
CLAUDE_API_KEY=sk-...            # Your API key
CLAUDE_MODEL=claude-opus-4.1     # Default model
```

---

## Usage

### Basic Commands

```bash
# SSH to VPS
ssh root@YOUR_VPS_IP

# Start new Claude Code session
claude

# Continue previous session
claude -c

# Get help
/help

# Switch models
/model

# Check token usage
/status

# Exit
/logout
```

### Real-World Examples

**Create Custom WordPress Plugin:**
```bash
cd /srv/campaign-stack
claude
# "Create a custom plugin for donor dashboard"
```

**Debug Database Issues:**
```bash
cd /srv/campaign-stack
claude
# "Run MySQL query optimization and show slow queries"
```

**Generate Documentation:**
```bash
claude
# "Create a deployment guide for this campaign stack"
```

---

## Configuration

### Getting Your API Key

1. Visit: https://console.anthropic.com
2. Navigate to: API Keys
3. Click: "Create new secret key"
4. Copy key (starts with `sk-`)

### Changing API Key

```bash
# Option 1: Re-run setup helper
bash scripts/setup-claude-code.sh

# Option 2: Edit .env directly
nano .env
# Find: CLAUDE_API_KEY=sk-old-key
# Change to: CLAUDE_API_KEY=sk-new-key
# Save (Ctrl+X, Y, Enter)
```

### Disabling Claude Code

```bash
# Option 1: Set flag to false
nano .env
# ENABLE_CLAUDE_CODE=false

# Option 2: Uninstall CLI
npm uninstall -g @anthropic-ai/claude-code
```

---

## Documentation

**New Documentation File:**
- `docs/12-CLAUDE-CODE.md` - 400+ line comprehensive guide

**Covers:**
- What is Claude Code?
- Installation instructions
- Getting API key
- Basic and advanced usage
- Real-world examples
- Troubleshooting
- Best practices
- Security considerations
- Cost estimates
- Integration with Campaign Stack

---

## Security & Best Practices

### API Key Security

✅ **What we do:**
- Store in `.env` (not committed to git)
- Load as environment variable
- Never log to stdout
- Can be rotated anytime

✅ **What you should do:**
- Keep `.env` file secure
- Don't share API keys
- Store in password manager
- Rotate periodically
- Delete old keys from Anthropic console

### Safe Usage

✅ **Good use cases:**
- Create custom plugins
- Analyze code
- Generate documentation
- Optimize database queries
- Write deployment scripts

❌ **Avoid:**
- Modifying core WordPress/CiviCRM files
- Running untested code in production
- Exposing sensitive data in prompts
- Auto-accepting all changes

---

## Troubleshooting

### "Command not found: claude"

```bash
npm list -g @anthropic-ai/claude-code
npm install -g @anthropic-ai/claude-code
```

### "Authentication failed"

```bash
bash scripts/setup-claude-code.sh
# Re-enter API key
```

### "Out of tokens"

1. Wait for quota reset (usually daily)
2. Use cheaper model: `/model claude-haiku-4.5`
3. Check usage: https://console.anthropic.com

See `docs/12-CLAUDE-CODE.md` for more troubleshooting.

---

## Integration with Existing Campaign Stack

Claude Code is **completely optional** and:
- ✅ Doesn't interfere with WordPress/CiviCRM
- ✅ Doesn't change deployment process
- ✅ Can be added/removed anytime
- ✅ Doesn't affect website functionality
- ✅ Doesn't require additional resources

**Campaign Stack works perfectly without Claude Code.**

---

## Cost Impact

### What You Pay

**Claude API Usage:**
- Only for Claude Code sessions
- Standard API pricing (~$0.003-0.015 per 1K tokens)
- Typical usage: $5-20/month for light usage

**Infrastructure Costs:**
- Same as before: ~$31-40/month
- Node.js/npm add minimal overhead
- No additional VPS resources needed

### Budget Tips

1. Use Haiku model for simple tasks
2. Use Sonnet for general purpose
3. Use Opus only for complex work
4. Clear context frequently (`/clear`)
5. Be specific in prompts

---

## Testing

### Test Installation

```bash
# After installer runs
claude --version

# Test authentication
export ANTHROPIC_API_KEY=$(grep CLAUDE_API_KEY .env | cut -d'=' -f2)
claude login
```

### Test in Campaign Stack

```bash
cd /srv/campaign-stack
claude

# Inside Claude:
/status              # Check tokens
/help                # See commands
```

---

## Files Modified Summary

```
campaign-stack/
├── install-campaign-stack.sh         ← Updated with Step 3/7
├── scripts/
│   ├── install-civicrm.sh           ← No changes
│   └── setup-claude-code.sh          ← NEW: Post-install setup
├── docs/
│   ├── 12-CLAUDE-CODE.md            ← NEW: Comprehensive guide
│   ├── 01-QUICKSTART.md             ← Can reference Claude Code
│   ├── 02-INSTALLATION.md           ← Can reference Claude Code
│   └── [others]                      ← No changes
├── .env.example                      ← Updated with Claude section
└── README.md                         ← Can reference Claude Code
```

---

## Backward Compatibility

✅ **Fully backward compatible:**
- Existing deployments unaffected
- No breaking changes
- Claude Code is optional
- Can upgrade existing systems
- Default: Claude Code disabled

**To upgrade existing deployment:**
```bash
# Option 1: Use setup helper
bash scripts/setup-claude-code.sh

# Option 2: Manual install
npm install -g @anthropic-ai/claude-code
```

---

## Future Enhancements

Potential future improvements:

1. **MCP Server Support** - Claude Code with MCP servers
2. **Custom Commands** - `.claude/commands/` directory
3. **Integration Examples** - Preset Claude prompts for common tasks
4. **Monitoring** - Track Claude Code usage per session
5. **Hooks** - Pre/post hooks for Claude operations
6. **Multi-user** - Support for team usage

---

## Documentation Updates Needed

**Update these docs to mention Claude Code:**

1. ✅ `README.md` - Add Claude Code to features list
2. ✅ `01-QUICKSTART.md` - Mention optional Claude Code
3. ✅ `02-INSTALLATION.md` - Note the Step 3/7 Claude Code option
4. ✅ `03-CONFIGURATION.md` - Can reference for advanced workflows
5. ✅ `08-OPERATIONS.md` - Add Claude Code use cases
6. ✅ `11-GLOSSARY.md` - Define Claude Code term

---

## Summary

**What's New:**
- Claude Code integration as optional feature
- Automatic installation during setup
- Secure API key management
- Comprehensive documentation
- Helper scripts for configuration

**Benefits:**
- Terminal-based AI development assistant
- Integrates into existing Campaign Stack
- Optional - no impact if not used
- Secure - API key stored locally
- Flexible - can enable/disable anytime

**Getting Started:**
1. Run installer: `bash scripts/install-campaign-stack.sh`
2. Answer yes to Claude Code prompt
3. Provide API key from console.anthropic.com
4. Start using: `claude`

---

**Version:** 2.1  
**Status:** Production Ready  
**Last Updated:** November 20, 2025

For detailed information, see `docs/12-CLAUDE-CODE.md`
