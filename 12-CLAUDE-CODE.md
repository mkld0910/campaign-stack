# CLAUDE CODE - Terminal-Based Development Integration

**Version:** 1.0  
**Last Updated:** November 20, 2025  
**Optional Feature** - Not required for basic deployment

---

## What is Claude Code?

Claude Code is a command-line interface that lets you delegate coding tasks to Claude AI directly from your terminal. It's designed for developers who want to integrate Claude into their existing development workflow without switching to a browser.

**Key Features:**
- ✅ Terminal-native AI assistant
- ✅ Full codebase context awareness
- ✅ Can read, edit, and execute commands
- ✅ Integrates with Git, shell commands, and IDEs
- ✅ Agentic coding capabilities

**Not Required For:**
- Running Campaign Stack
- Managing WordPress/CiviCRM
- Using the website normally

**Good For:**
- Extending Campaign Stack functionality
- Writing custom plugins/themes
- Automating deployment tasks
- Code generation and refactoring

---

## Installation

### During Initial Setup

The main installer (`install-campaign-stack.sh`) asks:
```
Enable Claude Code CLI? (y/n, default=n)
```

If you answer `yes`, it will:
1. Detect and install Node.js/npm (if needed)
2. Install Claude Code CLI globally
3. Configure API key in `.env`

### After Initial Setup

If you didn't enable it initially, run:

```bash
cd /srv/campaign-stack
bash scripts/setup-claude-code.sh
```

This script allows you to:
- Enable Claude Code
- Update API key
- Test authentication
- Setup helper aliases

### Manual Installation

If automated setup fails:

```bash
# Install Node.js (if needed)
apt-get install nodejs npm

# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Authenticate
export ANTHROPIC_API_KEY=sk-your-key-here
claude login
```

---

## Getting Your API Key

1. **Visit Anthropic Console:**
   - https://console.anthropic.com

2. **Navigate to API Keys:**
   - Click "API Keys" in sidebar
   - Or: https://console.anthropic.com/api-keys

3. **Create New Key:**
   - Click "+ Create new secret key"
   - Copy the key (starts with `sk-`)
   - Save in secure location

4. **Store in Campaign Stack:**
   - Option A: Enter during installer
   - Option B: Run `setup-claude-code.sh`
   - Option C: Edit `.env` file manually

**Important:** Your API key is stored in `.env` and never committed to git.

---

## How It Works

### Architecture

```
Your Terminal
    ↓
Claude Code CLI
    ↓
Anthropic API (uses your API key)
    ↓
Claude Model (processes requests)
    ↓
Results (code, analysis, suggestions)
```

### Authentication Flow

1. **First Run:** `claude login`
   - Checks for `ANTHROPIC_API_KEY` environment variable
   - Or prompts for interactive authentication

2. **Subsequent Runs:** Auto-authenticates
   - API key loaded from `.env`
   - No repeated login needed

3. **API Key Storage:**
   - Stored in `.env` (not committed to git)
   - Loaded as environment variable
   - Never sent anywhere except Anthropic

---

## Basic Usage

### Starting a Session

```bash
# Start new Claude Code session
claude

# Continue from last session
claude -c

# Start with specific directory context
cd /path/to/project
claude
```

### Common Commands

Inside a Claude Code session, use these commands:

```bash
/help                # Show all available commands
/status              # Check token usage this session
/model               # Switch between models
/clear               # Clear conversation history
/logout              # Exit and logout
```

### Example Workflow

**Scenario: Add a custom WordPress plugin feature**

```bash
# 1. SSH to your VPS
ssh root@YOUR_VPS_IP

# 2. Navigate to WordPress
cd /srv/campaign-stack/wordpress_data/wp-content/plugins

# 3. Start Claude Code session
claude

# 4. Ask Claude to help
"Create a custom plugin that adds a donor dashboard page"

# 5. Claude will:
#    - Understand your project structure
#    - Create necessary files
#    - Run tests
#    - Make changes with your approval

# 6. Exit when done
/logout
```

---

## Available Models

Claude Code supports multiple models. Switch with `/model`:

| Model | Speed | Capability | Best For |
|-------|-------|-----------|----------|
| **claude-opus-4.1** | Slow | Highest | Complex problems, large context |
| **claude-sonnet-4.5** | Medium | High | General purpose, good balance |
| **claude-haiku-4.5** | Fast | Good | Quick tasks, simple edits |

**Default:** Opus 4.1 (most capable)

**Switch models:**
```bash
/model                    # See options and switch
/model claude-sonnet-4.5  # Use Sonnet directly
```

---

## Real-World Examples

### Example 1: Generate Campaign Settings Page

```bash
cd /srv/campaign-stack

# Start session in campaign root
claude

# Prompt:
"Create a custom WordPress admin page for campaign settings.
Include fields for campaign name, goal amount, and end date.
Store in custom database table with proper sanitization."

# Claude will:
# - Create plugin file structure
# - Write secure code with nonces
# - Add admin menu items
# - Suggest and run database migrations
# - Ask for approval before each change
```

### Example 2: Optimize Database Queries

```bash
cd /srv/campaign-stack/wordpress_data

claude

# Prompt:
"Review the WordPress database queries in wp-config.php
and identify any N+1 query problems.
Suggest optimizations with WordPress best practices."

# Claude will:
# - Scan configuration
# - Identify performance issues
# - Suggest specific optimizations
# - Show you the changes before applying
```

### Example 3: Add Custom Stripe Integration

```bash
cd /srv/campaign-stack/wordpress_data/wp-content/plugins

claude

# Prompt:
"Create a custom WordPress plugin that integrates Stripe
for recurring monthly donations to our campaign.
Include donation levels and email confirmations."

# Claude will:
# - Create plugin structure
# - Setup Stripe API integration
# - Write webhook handlers
# - Test the implementation
```

---

## Using with Campaign Stack

### Safe Ways to Use

✅ **Good Use Cases:**
- Create custom plugins
- Analyze existing code
- Write documentation
- Optimize database queries
- Add new features to themes
- Generate test data
- Write deployment scripts

❌ **Avoid:**
- Don't have Claude modify core WordPress/CiviCRM files
- Don't use on production without testing
- Don't expose sensitive data in prompts
- Don't auto-accept all changes without review

### Permissions Required

Claude Code can use these tools on your VPS:
- **Read files:** See your code
- **Write files:** Create/modify code
- **Run commands:** Execute bash commands
- **Git access:** Commit and push changes (if configured)

**Always review changes before accepting.**

---

## Integration with Campaign Stack

### Useful Workflows

**1. Database Maintenance**
```bash
claude

# "Run WordPress database optimization
# and show me slow queries"
```

**2. Backup Verification**
```bash
cd backups
claude

# "Verify all backup files are valid
# Check timestamps and sizes"
```

**3. Security Audit**
```bash
cd /srv/campaign-stack

claude

# "Review our Docker configuration
# and WordPress security settings.
# Identify any vulnerabilities."
```

**4. Performance Analysis**
```bash
claude

# "Check MySQL slow query log
# and suggest optimizations"
```

**5. Custom Reports**
```bash
claude

# "Query WordPress database for
# total donations this month
# Generate a CSV report"
```

---

## Token Usage & Costs

### How Tokens Work

Claude Code uses tokens for API requests. Your usage counts against your API quota.

**Token Types:**
- **Input tokens:** What you send to Claude
- **Output tokens:** What Claude sends back
- **Request limit:** ~100 requests per day (standard)

### Cost Estimate

**API Pricing (as of Nov 2025):**
- Claude 3 Opus: ~$0.015/1K input tokens, $0.045/1K output tokens
- Claude 3 Sonnet: ~$0.003/1K input tokens, $0.015/1K output tokens
- Claude 3 Haiku: ~$0.00025/1K input tokens, $0.00125/1K output tokens

**Typical Usage:**
- Simple prompt: 0.1-0.5¢
- Code generation: 0.5-2¢
- Complex analysis: 2-5¢
- **Monthly estimate:** $5-20 (light usage)

**Budget Friendly Tips:**
1. Use Haiku for simple tasks
2. Use Sonnet for most work
3. Use Opus only for complex problems
4. Clear context frequently (`/clear`)
5. Be specific in prompts (less token waste)

---

## Troubleshooting

### "Command not found: claude"

**Problem:** Claude Code not installed or not in PATH

**Solutions:**
```bash
# Check if installed
npm list -g @anthropic-ai/claude-code

# Reinstall
npm install -g @anthropic-ai/claude-code

# Check PATH
which claude

# Add to PATH (if needed)
export PATH="/usr/local/bin:$PATH"
```

### "Authentication failed"

**Problem:** API key invalid or not found

**Solutions:**
```bash
# Verify key is in .env
grep CLAUDE_API_KEY .env

# Update if wrong
bash scripts/setup-claude-code.sh

# Test manually
export ANTHROPIC_API_KEY=sk-your-key
claude --version
```

### "Permission denied"

**Problem:** Can't write to directories

**Solutions:**
```bash
# Run with appropriate permissions
sudo claude  # Use carefully!

# Or fix directory permissions
sudo chown -R $USER /path/to/project

# Then run without sudo
claude
```

### "Out of tokens"

**Problem:** API request limit reached

**Solutions:**
1. Wait for quota reset (usually daily)
2. Use cheaper model: `/model claude-haiku-4.5`
3. Use fewer, more specific prompts
4. Check usage: https://console.anthropic.com

### Session keeps disconnecting

**Problem:** Long sessions timeout

**Solutions:**
```bash
# Clear old context
/clear

# Save progress to file
# Exit and restart with: claude -c

# Or use screen/tmux for persistent sessions
screen -S claude
claude
# Ctrl+A then D to detach
```

---

## Best Practices

### 1. Be Specific in Prompts

**Bad:** "Fix this error"
**Good:** "The contact form is returning 'undefined' error on line 42. Can you debug it?"

### 2. Provide Context

```bash
# Bad approach - just ask
"Create a donation form"

# Good approach - show structure
"I have WordPress with Elementor installed.
Create a donation form plugin that:
- Uses Stripe API
- Stores donations in custom database table
- Sends email confirmation to donors"
```

### 3. Review Changes

Always review Claude's changes before accepting:
- Read proposed code changes
- Understand what will change
- Ask for explanations if unclear
- Test on staging first

### 4. Use Incremental Steps

```bash
# Better than one giant prompt:
# Step 1: "Create plugin file structure"
# Step 2: "Add admin menu"
# Step 3: "Add form handling"
# Step 4: "Add database storage"
```

### 5. Test First, Then Commit

```bash
# Never auto-accept and forget:
claude

# ... make changes ...

# Test thoroughly
docker-compose logs wordpress_app | tail -20
wp plugin verify-plugin

# Then commit
git add .
git commit -m "Add feature with Claude Code"
```

---

## Disabling Claude Code

If you no longer want Claude Code:

### Option 1: Stop Using It
Just don't run `claude` command. The CLI stays installed but unused.

### Option 2: Uninstall
```bash
npm uninstall -g @anthropic-ai/claude-code
```

### Option 3: Remove API Key from .env
```bash
# Edit .env
nano .env

# Change:
ENABLE_CLAUDE_CODE=false
CLAUDE_API_KEY=

# Save and exit
```

---

## Advanced: Custom Aliases

The installer can create a helper script:

```bash
# Create if not already present
bash scripts/setup-claude-code.sh

# Use the helper
bash scripts/claude-vps-login

# This automatically loads API key from .env
```

---

## Advanced: Claude Code Configuration

For power users, Claude Code supports configuration files:

**`.claude/config.json`:**
```json
{
  "model": "claude-opus-4.1",
  "max_tokens": 4096,
  "timeout": 300,
  "auto_accept": false
}
```

**`.claude/commands/` directory:**
Store custom command shortcuts for frequent tasks.

See official docs: https://docs.claude.com/en/docs/claude-code/

---

## Security Considerations

### What Claude Can Access

Claude Code runs on your VPS and can:
- Read any file you have access to
- Modify files (with your approval)
- Execute shell commands
- Access Git history

### What Claude Cannot Access

- Your API key from prompts (it's environment variable)
- Content outside the project directory (unless you navigate there)
- Other users' files (depends on VPS permissions)
- Network traffic (runs locally)

### Security Best Practices

1. **Review Changes:** Always review code before accepting
2. **Sensitive Data:** Don't paste passwords/keys in prompts
3. **Commit Often:** Use git to track changes
4. **Test First:** Test changes before production
5. **Keep Secrets:** Don't expose `.env` file contents
6. **Audit Access:** Check git log for changes

---

## Limitations

**Claude Code works best with:**
- Code files (PHP, JavaScript, Python, etc.)
- Configuration files
- Documentation
- Test execution

**Claude Code struggles with:**
- Very large codebases (>100K lines)
- Complex system administration
- Interactive debugging
- Real-time monitoring

---

## Getting Help

**For Claude Code issues:**
- Official docs: https://docs.claude.com/en/docs/claude-code/
- GitHub discussions: https://github.com/anthropic-ai/claude-code
- Command help: `/help` (in Claude session)

**For Campaign Stack issues using Claude Code:**
- See [TROUBLESHOOTING.md](./04-TROUBLESHOOTING.md)
- GitHub issues: https://github.com/mkld0910/campaign-stack/issues

---

## Next Steps

1. ✅ Installed and tested Claude Code
2. → Start with simple tasks (`/help`)
3. → Graduate to complex tasks
4. → Integrate into your workflow

---

**Enjoy using Claude Code with Campaign Stack!**

For questions or feedback, open an issue on GitHub.
