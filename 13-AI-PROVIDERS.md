# AI PROVIDERS - Multi-Provider Guide (NO Vendor Lock-In)

**Version:** 2.2 (Provider-Agnostic)  
**Last Updated:** November 20, 2025  
**Philosophy:** Users choose their AI provider - no vendor lock-in

---

## Overview

Campaign Stack v2.2 supports **multiple AI providers** with **no vendor lock-in**. You can:

✅ Choose your preferred AI provider during installation  
✅ Switch between providers anytime  
✅ Use Anthropic Claude, OpenAI ChatGPT, Google Gemini, or Ollama (local/free)  
✅ Run AI assistants completely offline (Ollama)  
✅ Pay only for what you use  

---

## Supported Providers

| Provider | CLI Tool | Cost | Best For | Offline? |
|----------|----------|------|----------|----------|
| **Anthropic Claude** | Claude Code | $3-15/M tokens | Complex tasks | ❌ No |
| **OpenAI ChatGPT** | ChatGPT CLI | $0.50-60/M tokens | General purpose | ❌ No |
| **Google Gemini** | Google AI CLI | $0.25-0.50/M tokens | **Budget-friendly** | ❌ No |
| **Ollama (Free)** | Ollama | **FREE** | **Offline, private** | ✅ **Yes** |

---

## Installation

### During Initial Setup

```bash
bash scripts/install-campaign-stack.sh

# When asked (Step 3/7):
# Choose provider (1-5):
# 1. Anthropic Claude
# 2. OpenAI ChatGPT
# 3. Google Gemini
# 4. Local Ollama (Free & Offline)
# 5. Skip AI provider
```

### After Initial Setup

```bash
# Switch or add providers anytime
bash scripts/install-ai-provider.sh

# Menu:
# 1. Switch to Anthropic Claude
# 2. Switch to OpenAI ChatGPT
# 3. Switch to Google Gemini
# 4. Switch to Local Ollama (FREE)
# 5. Show all available providers
# 6. Test current provider
# 7. Uninstall all AI providers
```

---

## Provider Details

### Option 1: Anthropic Claude

**What You Get:**
- Highest quality responses
- Multi-step reasoning
- Large context window
- Production-ready

**Cost:**
- Input: $3 per 1M tokens
- Output: $15 per 1M tokens
- Typical: $5-20/month for light use

**Models:**
- `claude-opus-4.1` - Most capable (slow)
- `claude-sonnet-4.5` - Balanced (recommended)
- `claude-haiku-4.5` - Fast (cheapest)

**Getting Started:**

```bash
# 1. Create account
# https://console.anthropic.com

# 2. Get API key
# https://console.anthropic.com/api-keys

# 3. Install during setup (or later)
bash scripts/install-campaign-stack.sh
# Choose: 1. Anthropic Claude

# 4. Use
ssh root@YOUR_VPS_IP
claude
```

**Commands:**
```bash
claude              # Start session
/help               # Show all commands
/status             # Check token usage
/model              # Switch models
/clear              # Clear context
/logout             # Exit
```

**When to Use:**
- Complex problem solving
- Code generation
- Strategic planning
- Tasks requiring deep analysis

---

### Option 2: OpenAI ChatGPT

**What You Get:**
- Powerful, widely-used models
- Good quality responses
- Good price-to-performance ratio
- Large user community

**Cost:**
- GPT-4: $30/M tokens input, $60/M output (expensive)
- GPT-4-Turbo: $10/M tokens input, $30/M output (better)
- GPT-3.5-Turbo: $0.50/M tokens input, $1.50/M output (cheap)

**Models:**
- `gpt-4` - Most capable
- `gpt-4-turbo` - Better value
- `gpt-3.5-turbo` - Fastest/cheapest

**Getting Started:**

```bash
# 1. Create account
# https://platform.openai.com

# 2. Get API key
# https://platform.openai.com/api-keys

# 3. Install during setup (or later)
bash scripts/install-campaign-stack.sh
# Choose: 2. OpenAI ChatGPT

# 4. Use
ssh root@YOUR_VPS_IP
chatgpt
```

**When to Use:**
- General purpose coding
- Content creation
- Brainstorming
- Quick tasks

---

### Option 3: Google Gemini

**What You Get:**
- Cost-effective models
- Good quality responses
- Newest AI technology
- Competitive pricing

**Cost:** 
- **$0.25-0.50 per 1M tokens (CHEAPEST paid option)**
- Typical: $2-10/month for light use

**Models:**
- `gemini-pro` - Powerful
- `gemini-pro-vision` - Multimodal

**Getting Started:**

```bash
# 1. Create account & get API key
# https://ai.google.dev/tutorials/setup

# 2. Install during setup (or later)
bash scripts/install-campaign-stack.sh
# Choose: 3. Google Gemini

# 3. Use
ssh root@YOUR_VPS_IP
google-ai
```

**When to Use:**
- Budget-conscious projects
- Cost-effective AI assistance
- Efficient models
- Scale without breaking budget

**Why Choose Gemini:**
- **4-10x cheaper than Anthropic Claude**
- **10-30x cheaper than OpenAI GPT-4**
- Still high quality models
- Perfect for budget-conscious teams

---

### Option 4: Ollama (LOCAL & FREE!)

**What You Get:**
- ✅ **COMPLETELY FREE**
- ✅ Works **OFFLINE**
- ✅ No API key needed
- ✅ Privacy (data stays local)
- ✅ No usage limits
- ✅ Run models locally on VPS

**Cost:** 
- **$0 (completely free)**

**Models Available:**
- `mistral` - Fast, capable (recommended)
- `neural-chat` - Conversational
- `llama2` - Meta's Llama
- `orca` - Specialized
- Many more on: https://ollama.ai/library

**Getting Started:**

```bash
# 1. Install during setup (or later)
bash scripts/install-campaign-stack.sh
# Choose: 4. Local Ollama (FREE)

# 2. Use
ssh root@YOUR_VPS_IP
ollama run mistral

# 3. Switch models
ollama pull neural-chat
ollama run neural-chat

# 4. List available models
ollama list
```

**When to Use:**
- **You want completely FREE AI**
- Privacy is critical (data stays local)
- Offline access required
- No internet API calls
- Unlimited usage
- Learning/experimentation
- Budget is zero

**Why Choose Ollama:**
- **COMPLETELY FREE** (no API costs)
- Works **OFFLINE** (no internet needed)
- Privacy (**no data sent anywhere**)
- **NO LIMITS** (use as much as you want)
- Perfect for testing/learning
- Runs on your VPS

**Performance Notes:**
- Slower than cloud models (running locally)
- Limited to VPS hardware
- Good enough for most tasks
- Scales with VPS RAM/CPU

---

## Cost Comparison

### Monthly Estimate (Light Use - 100K tokens/month)

| Provider | Input Cost | Output Cost | **Total/Month** |
|----------|-----------|-----------|-----------------|
| **Ollama** | **$0** | **$0** | **$0** |
| **Google Gemini** | $0.025 | $0.05 | **~$0.75/mo** |
| **OpenAI GPT-3.5** | $0.05 | $0.15 | **~$2/mo** |
| **Anthropic Haiku** | $0.03 | $0.15 | **~$1.80/mo** |
| **OpenAI GPT-4-Turbo** | $1 | $3 | **~$40/mo** |
| **OpenAI GPT-4** | $3 | $6 | **~$90/mo** |
| **Anthropic Opus** | $3 | $15 | **~$18/mo** |

**Winner:** Ollama (free) or Google Gemini (0.75¢)

### Annual Cost for Heavy Use (10M tokens/month)

| Provider | Annual Cost |
|----------|------------|
| **Ollama** | **$0** |
| **Google Gemini** | **$90** |
| **OpenAI GPT-3.5** | **$240** |
| **Anthropic Claude** | **$2,160** |
| **OpenAI GPT-4** | **$10,800** |

---

## Switching Between Providers

### Option A: Command-Line Menu

```bash
bash scripts/install-ai-provider.sh

# Menu appears:
# 1. Switch to Anthropic Claude
# 2. Switch to OpenAI ChatGPT
# 3. Switch to Google Gemini
# 4. Switch to Local Ollama
# 5. Show all providers
# 6. Test current provider
# 7. Uninstall all providers
```

### Option B: Manual Edit .env

```bash
# Edit .env file
nano .env

# Find: PRIMARY_AI_PROVIDER=anthropic
# Change to: PRIMARY_AI_PROVIDER=openai
# Or: PRIMARY_AI_PROVIDER=google
# Or: PRIMARY_AI_PROVIDER=ollama

# Save (Ctrl+X, Y, Enter)
```

### Option C: Switch Later

```bash
# Current setup with Claude
PRIMARY_AI_PROVIDER=anthropic

# Later, want to try OpenAI:
bash scripts/install-ai-provider.sh
# Select: 2. Switch to OpenAI ChatGPT

# Or want to save money with Google:
bash scripts/install-ai-provider.sh
# Select: 3. Switch to Google Gemini

# Or go completely FREE with Ollama:
bash scripts/install-ai-provider.sh
# Select: 4. Switch to Local Ollama
```

---

## Usage Examples

### Using Claude Code

```bash
ssh root@YOUR_VPS_IP

claude              # Start session
# Inside Claude:
/status             # Check tokens used
/model              # See/switch models
```

### Using OpenAI ChatGPT

```bash
ssh root@YOUR_VPS_IP

chatgpt             # Start session
chatgpt ask "What is Campaign Stack?"  # Single query
```

### Using Google Gemini

```bash
ssh root@YOUR_VPS_IP

google-ai           # Start session
# Similar to OpenAI
```

### Using Ollama (Free/Offline)

```bash
ssh root@YOUR_VPS_IP

# Run default Mistral model
ollama run mistral

# Switch to different model
ollama pull neural-chat
ollama run neural-chat

# See available models
ollama list

# Run another model
ollama run llama2
```

---

## Real-World Scenarios

### Scenario 1: You Want Maximum Quality (No Budget Limit)
```
→ Use: Anthropic Claude
→ Cost: $5-20/month typical
→ Why: Best quality, great for complex work
```

### Scenario 2: You Want Good Quality + Reasonable Cost
```
→ Use: OpenAI GPT-3.5-Turbo or Google Gemini
→ Cost: $1-5/month typical
→ Why: Good balance of capability and price
```

### Scenario 3: You Want MAXIMUM Savings
```
→ Use: Google Gemini (cheapest paid)
→ Cost: ~$1/month typical
→ Why: High quality at 90% discount vs Claude
```

### Scenario 4: You Want COMPLETELY FREE
```
→ Use: Ollama (local models)
→ Cost: $0
→ Why: Free, offline, unlimited, private
```

### Scenario 5: You Want to Compare Providers
```
bash scripts/install-ai-provider.sh
# Try Claude for a week
# Then switch to OpenAI
# Then try Google
# Pick your favorite!
```

---

## Troubleshooting

### "Command not found: claude"

```bash
# Reinstall Claude Code
npm install -g @anthropic-ai/claude-code

# Or switch providers
bash scripts/install-ai-provider.sh
```

### "Invalid API key"

```bash
# Re-enter API key
bash scripts/install-ai-provider.sh

# Then choose your provider again
```

### "Ollama not running"

```bash
# Start Ollama service
ollama serve &

# Then run
ollama run mistral
```

### "Want to switch providers mid-month?"

```bash
# No problem! Just run:
bash scripts/install-ai-provider.sh

# Choose new provider
# Existing data unaffected
# Can switch back anytime
```

---

## Security & Privacy

### API Key Storage

✅ **Secure:**
- Stored in `.env` file
- `.env` is gitignored (not committed)
- Never exposed in logs
- Can be rotated anytime

⚠️ **Your Responsibility:**
- Don't share `.env` file
- Store backups in password manager
- Rotate keys periodically

### Privacy by Provider

| Provider | Data Handling |
|----------|---------------|
| **Claude** | Anthropic uses data for safety improvements |
| **OpenAI** | OpenAI may use for model improvement |
| **Google** | Google may use for training |
| **Ollama** | **Stays completely local, never sent anywhere** |

**Most Private:** Ollama (local-only)

---

## Upgrade/Downgrade Anytime

### Current Cost vs Budget

```
Current: Using Claude ($15/month with heavy use)
Budget: $5/month max

Solution:
bash scripts/install-ai-provider.sh
→ Switch to Google Gemini ($1-2/month)
→ Or switch to Ollama ($0/month)
```

### Want Better Quality?

```
Current: Using Google Gemini
Quality: Good enough, but want better

Solution:
bash scripts/install-ai-provider.sh
→ Switch to Claude ($15/month)
→ Or stick with Google, better instructions
```

### Want Maximum Freedom?

```
Current: Using single provider
Want: Try multiple providers

Solution:
bash scripts/install-ai-provider.sh
→ Keep Claude as primary
→ Manually install others:
  npm install -g chatgpt-cli
  npm install -g @google/generative-ai
  brew install ollama
→ Use whichever you want for each task
```

---

## No Vendor Lock-In!

**What we mean:**

✅ Your data in `.env` not tied to any provider  
✅ Can switch providers in 30 seconds  
✅ No long-term contracts  
✅ No commitments  
✅ Can go completely free with Ollama  
✅ Can try each provider before committing  
✅ Never forced to use one provider  

**You own your choice:**
- Today: Claude
- Tomorrow: OpenAI
- Next week: Gemini
- Next month: Ollama (free)
- Next year: Something new!

---

## Roadmap

**Future Support:**
- Hugging Face models
- Azure OpenAI
- AWS Bedrock
- Cohere
- More Ollama models
- Multi-provider orchestration

**Philosophy:**
- Users choose their provider
- No forced upgrades
- No vendor lock-in
- Always open source
- Always flexible

---

## Getting Help

**Provider Documentation:**
- Claude: https://docs.claude.com
- OpenAI: https://platform.openai.com/docs
- Google: https://ai.google.dev
- Ollama: https://ollama.ai

**Campaign Stack Docs:**
- Installation: See 02-INSTALLATION.md
- Configuration: See 03-CONFIGURATION.md
- Operations: See 08-OPERATIONS.md

---

**Status:** ✅ Production Ready | **Philosophy:** NO vendor lock-in
