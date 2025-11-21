# Multi-AI Provider Support Analysis

**Date:** November 20, 2025  
**Question:** Can users swap Claude Code for other AI providers?

---

## Current State: Claude Code Only

**Current Implementation:**
- Hardcoded to use `@anthropic-ai/claude-code` (Anthropic's package)
- API key: `ANTHROPIC_API_KEY` environment variable
- Model selection: Claude models only (Opus, Sonnet, Haiku)
- No abstraction layer for different providers

---

## Analysis: Provider Support

### 1. OpenAI (ChatGPT)

**CLI Options Available:**
- ✅ `ChatGPT CLI` - Official OpenAI command-line tool
- ✅ `aider` - AI pair programming tool (supports OpenAI)
- ✅ `Continue` - IDE plugin (supports OpenAI, Claude, others)
- ✅ `LM Studio` - Local model runner
- ❌ Claude Code NOT compatible with OpenAI

**Feasibility:** ⭐⭐⭐⭐⭐ (Very High)
- Can replace Claude Code entirely with ChatGPT CLI
- Users would use `OPENAI_API_KEY` instead of `ANTHROPIC_API_KEY`
- Similar workflow but different CLI

**Example:**
```bash
# Replace Claude Code with ChatGPT CLI
npm install -g chatgpt-cli

# Use with:
export OPENAI_API_KEY=sk-...
chatgpt-cli  # Instead of: claude
```

---

### 2. Google Gemini

**CLI Options Available:**
- ✅ `google-ai-cli` - Google's AI command-line tool
- ✅ `aider` - Supports Gemini API
- ✅ `Continue` - IDE plugin supports Gemini
- ❌ Claude Code NOT compatible with Gemini

**Feasibility:** ⭐⭐⭐⭐ (High)
- Gemini API is available and similar structure
- Fewer CLI tools compared to OpenAI
- Would require similar setup as Claude

**Example:**
```bash
npm install -g @google/generative-ai-cli

export GOOGLE_API_KEY=...
google-ai-cli  # Instead of: claude
```

---

### 3. Other Providers

**Meta Llama (via API):**
- ✅ `aider` support
- ✅ `LM Studio` support
- Via Replicate API, Together AI, etc.

**Mistral:**
- ✅ `aider` support
- ✅ Available via API

**Local Models (Open Source):**
- ✅ `ollama` - Run locally (no API key needed)
- ✅ `LM Studio` - GUI-based local runner
- ✅ `Continue` - IDE plugin with local model support

---

## Current Implementation: Limitations

### Hard Dependencies

**On Anthropic:**
```bash
# Hardcoded provider
"@anthropic-ai/claude-code"  # Only this package

# Hardcoded environment variable
ANTHROPIC_API_KEY           # Only this key type

# Hardcoded model selection
CLAUDE_MODEL                # Only Claude models

# Hardcoded authentication
export ANTHROPIC_API_KEY    # Only Anthropic auth
```

### Why It's Not Flexible

1. **Claude Code is Anthropic-specific**
   - Not a generic AI wrapper
   - Can't swap out the provider
   - Would need different CLI tool for each provider

2. **Environment Variables are Provider-Specific**
   - `ANTHROPIC_API_KEY` only works with Anthropic
   - OpenAI uses `OPENAI_API_KEY`
   - Google uses `GOOGLE_API_KEY`
   - Can't use same `.env` for multiple providers

3. **Installation is Provider-Specific**
   - `npm install @anthropic-ai/claude-code`
   - Different for OpenAI, Google, etc.
   - Different commands: `claude` vs `chatgpt` vs `gemini`

---

## Recommendation 1: Provider Agnostic Architecture

### Design Option A: Abstract CLI Layer

```bash
# New abstraction in .env
AI_PROVIDER=anthropic        # or: openai, google, ollama, etc.
AI_API_KEY=...              # Generic key
AI_MODEL=...                # Generic model reference

# Scripts auto-detect and install right CLI tool
install-ai-cli.sh          # Smart installer that:
  1. Reads AI_PROVIDER from .env
  2. Installs appropriate CLI package
  3. Configures environment variables
  4. Tests connectivity
```

**Benefits:**
- ✅ Users can swap providers by changing `.env`
- ✅ No reinstalling scripts
- ✅ Unified configuration
- ✅ Easy provider switching

**Implementation:**
```bash
# .env
AI_PROVIDER=anthropic
# AI_PROVIDER=openai
# AI_PROVIDER=google
# AI_PROVIDER=ollama

AI_API_KEY=sk-...
AI_MODEL=gpt-4  # Or: claude-opus-4.1, etc.

# Smart install script detects and installs right CLI
bash scripts/install-ai-cli.sh
```

---

## Recommendation 2: Multi-Provider Support (Enterprise)

### Design Option B: Built-in Multi-Provider

```bash
# Support multiple AI tools simultaneously
ENABLE_CLAUDE_CODE=true
ENABLE_OPENAI_CLI=false
ENABLE_GEMINI_CLI=false
ENABLE_OLLAMA=false

# Each has its own config
CLAUDE_API_KEY=sk-...
OPENAI_API_KEY=sk-...
GOOGLE_API_KEY=...
OLLAMA_BASE_URL=http://localhost:11434

# User can choose which to use
claude              # Use Anthropic Claude
chatgpt             # Use OpenAI ChatGPT
gemini              # Use Google Gemini
ollama run mistral  # Use local model
```

**Benefits:**
- ✅ Maximum flexibility
- ✅ Users can compare different providers
- ✅ Easy to test multiple tools
- ✅ No forced provider lock-in

**Drawbacks:**
- ❌ More complex setup
- ❌ Multiple CLI tools to manage
- ❌ Larger `.env` file
- ❌ More documentation needed

---

## Recommendation 3: Hybrid Approach (Recommended)

### Design Option C: Primary + Optional Fallback

```bash
# Primary AI provider (what was asked about initially)
PRIMARY_AI_PROVIDER=anthropic
CLAUDE_API_KEY=sk-...

# Optional: Install secondary providers
ENABLE_SECONDARY_AI=false

# If secondary enabled, choose which
SECONDARY_AI_PROVIDER=openai
# SECONDARY_AI_PROVIDER=google
# SECONDARY_AI_PROVIDER=ollama

OPENAI_API_KEY=sk-...
```

**Benefits:**
- ✅ Simple by default (one provider)
- ✅ Optional advanced flexibility
- ✅ Clear primary vs secondary
- ✅ Easy upgrade path
- ✅ Not overwhelming for new users

**Implementation Strategy:**
- Keep current Claude Code implementation as PRIMARY
- Add optional secondary provider installation
- Document all supported providers
- Provide provider-switching guide

---

## Comparison: All Options

| Aspect | Current | Option A | Option B | Option C |
|--------|---------|----------|----------|----------|
| **Complexity** | Simple | Medium | Complex | Medium |
| **Flexibility** | None | High | Very High | High |
| **Ease of Switching** | Hard | Easy | Easy | Medium |
| **Learning Curve** | Low | Low-Medium | High | Low |
| **Setup Time** | Fast | Fast | Slow | Fast |
| **Best For** | Anthropic-only | Users wanting choice | Power users | Most users |
| **Recommended** | ❌ Limited | ✅ Good | ✅✅ Best | ✅✅✅ Best |

---

## Easy Switch Option: For Users Right Now

### Without Waiting for Changes

**Users can switch providers TODAY:**

```bash
# 1. Uninstall Claude Code
npm uninstall -g @anthropic-ai/claude-code

# 2. Install preferred provider
npm install -g chatgpt-cli          # For OpenAI
npm install -g @google/ai-cli       # For Google
npm install -g ollama               # For local models

# 3. Use with different commands
# Claude: claude
# OpenAI: chatgpt
# Google: gemini
# Local: ollama run mistral

# 4. Each has own API key environment variable
export OPENAI_API_KEY=...
export GOOGLE_API_KEY=...
# ollama needs no key
```

**Pros:**
- ✅ Works immediately
- ✅ No script changes needed
- ✅ Users have full freedom

**Cons:**
- ❌ Manual installation
- ❌ Different commands
- ❌ No unified `.env` configuration
- ❌ Requires manual documentation

---

## Recommended Path Forward

### Phase 1: Current (Now)
- ✅ Keep Claude Code as primary option
- ✅ Document how to switch manually
- ✅ Add "Switching AI Providers" guide

### Phase 2: Short-term (1-2 months)
- Add abstraction layer for AI provider selection
- Support multiple providers in `.env`
- Create smart installer that auto-detects choice

### Phase 3: Medium-term (3-6 months)
- Full multi-provider support
- Side-by-side comparison docs
- Provider feature comparison matrix

### Phase 4: Long-term (6+ months)
- Unified AI CLI wrapper (single interface for all)
- Cost comparison tools
- Performance benchmarking

---

## Proposal: Update Current Implementation

### For Maximum Flexibility (No Code Changes)

**Add to documentation:**
1. Section: "Using Alternative AI Providers"
2. Step-by-step guides for:
   - OpenAI ChatGPT CLI
   - Google Gemini CLI
   - Local Ollama
   - LM Studio
   - Aider (multi-provider)
3. Cost comparison per provider
4. Model capability matrix
5. Switching between providers

**Example from docs:**
```markdown
## Using OpenAI Instead of Claude

### Installation
```bash
npm uninstall -g @anthropic-ai/claude-code
npm install -g chatgpt-cli
```

### Configuration
```bash
# Get API key from: https://platform.openai.com/api-keys
export OPENAI_API_KEY=sk-...
```

### Usage
```bash
chatgpt  # Same workflow as: claude
```
```

---

## Best Solution: Provider-Agnostic Design

### What to Implement

**Update `.env.example`:**
```bash
# ============================================================================
# AI PROVIDER CONFIGURATION
# ============================================================================
# Choose your preferred AI provider
# Options: anthropic, openai, google, ollama, local

PRIMARY_AI_PROVIDER=anthropic
# PRIMARY_AI_PROVIDER=openai
# PRIMARY_AI_PROVIDER=google
# PRIMARY_AI_PROVIDER=ollama

# Provider-specific API keys
ANTHROPIC_API_KEY=sk-...
OPENAI_API_KEY=sk-...
GOOGLE_API_KEY=...
OLLAMA_BASE_URL=http://localhost:11434

# Model selection per provider
# Anthropic: claude-opus-4.1, claude-sonnet-4.5, claude-haiku-4.5
# OpenAI: gpt-4, gpt-4-turbo, gpt-3.5-turbo
# Google: gemini-pro, gemini-pro-vision
# Ollama: mistral, neural-chat, any local model

AI_MODEL=gpt-4              # Auto-maps to provider's model
```

**Create new script: `install-ai-cli.sh`**
```bash
#!/bin/bash
# Detects PRIMARY_AI_PROVIDER from .env
# Installs appropriate CLI tool
# Tests connection
# Sets up environment variables

# Reads PRIMARY_AI_PROVIDER
# Case: anthropic → npm install @anthropic-ai/claude-code
# Case: openai → npm install chatgpt-cli
# Case: google → npm install @google/ai-cli
# Case: ollama → brew/apt install ollama
```

**Update installer:**
```bash
# In install-campaign-stack.sh, replace Step 3 with:

print_header "Step 3/7: Configure AI Provider"

echo "Select your AI provider:"
echo "1. Anthropic Claude (default)"
echo "2. OpenAI ChatGPT"
echo "3. Google Gemini"
echo "4. Local Ollama (free, offline)"
echo "5. Skip AI provider"

read -p "Choice (1-5): " AI_CHOICE

case $AI_CHOICE in
  1)
    PRIMARY_AI_PROVIDER=anthropic
    read -s -p "Enter Anthropic API key: " ANTHROPIC_API_KEY
    ;;
  2)
    PRIMARY_AI_PROVIDER=openai
    read -s -p "Enter OpenAI API key: " OPENAI_API_KEY
    ;;
  # ... etc for other providers
esac

# Then call:
bash scripts/install-ai-cli.sh
```

**Benefits:**
- ✅ Users choose their provider upfront
- ✅ Auto-installs right CLI tool
- ✅ Single unified configuration
- ✅ Easy switching later
- ✅ No forced vendor lock-in
- ✅ Maximum flexibility

---

## Cost Comparison (For Documentation)

| Provider | Model | Input | Output | Best For |
|----------|-------|-------|--------|----------|
| **Anthropic** | Claude Opus | $3/M tokens | $15/M | Complex tasks |
| **Anthropic** | Claude Sonnet | $3/M tokens | $15/M | Balanced |
| **Anthropic** | Claude Haiku | $0.25/M tokens | $1.25/M | Quick tasks |
| **OpenAI** | GPT-4 | $30/M tokens | $60/M | Advanced |
| **OpenAI** | GPT-4-Turbo | $10/M tokens | $30/M | Good balance |
| **OpenAI** | GPT-3.5-Turbo | $0.50/M tokens | $1.50/M | Budget |
| **Google** | Gemini Pro | $0.25/M tokens | $0.5/M | Cheap |
| **Ollama** | Mistral (local) | Free | Free | Offline |

---

## Conclusion

**Current State:** 
- ❌ Claude Code only (no flexibility)
- ❌ Hard to switch providers
- ❌ Vendor lock-in to Anthropic

**Recommended:** 
- ✅ **Option C - Hybrid Approach**
- Add provider detection/installation
- Keep Claude as primary
- Allow easy switching
- Document all alternatives
- **Effort:** Medium (1-2 days of development)

**Maximum Flexibility:**
- ✅ **Option A/B - Provider Agnostic**
- Abstract AI provider layer
- Users choose during setup
- Easy to switch
- No vendor lock-in
- **Effort:** Medium-High (2-3 days)

---

## Action Items

### Immediate (With Current Code)
1. Document manual provider switching
2. Add provider comparison guide
3. Show cost analysis

### Short-term (Next Release)
1. Add provider detection to installer
2. Create `install-ai-cli.sh` script
3. Update `.env` with all provider keys
4. Update documentation with all options

### Medium-term (Future)
1. Create unified AI CLI wrapper
2. Support side-by-side providers
3. Build cost/performance dashboard
4. Provider feature comparison matrix

