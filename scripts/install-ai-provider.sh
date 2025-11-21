#!/bin/bash

################################################################################
# Campaign Stack - AI Provider Manager
# Version: 1.0
# Purpose: Switch between AI providers anytime after deployment
# Usage: bash scripts/install-ai-provider.sh
#
# Features:
# - List installed AI providers
# - Switch primary provider
# - Install new providers
# - Uninstall providers
# - Test provider connectivity
################################################################################

set -e

# Platform Detection
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo "Error: This script must run on Linux (Ubuntu/Debian/RHEL/CentOS)"
    echo "Please run this on your VPS or use WSL on Windows"
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Get repo directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

cd "$REPO_DIR"

# Check if .env exists
if [ ! -f .env ]; then
    print_error ".env file not found"
    print_info "Have you run the main installer? (scripts/install-campaign-stack.sh)"
    exit 1
fi

print_header "AI Provider Manager"

# Show current provider
CURRENT_PROVIDER=$(grep "PRIMARY_AI_PROVIDER=" .env | cut -d '=' -f2 | tr -d ' ' || echo "none")
print_info "Current primary provider: $CURRENT_PROVIDER"

# Menu
echo ""
echo "What would you like to do?"
echo ""
echo "1. Switch to Anthropic Claude"
echo "2. Switch to OpenAI ChatGPT"
echo "3. Switch to Google Gemini"
echo "4. Switch to Local Ollama (FREE)"
echo "5. Show all available providers"
echo "6. Test current provider"
echo "7. Uninstall all AI providers"
echo "8. Exit"
echo ""

read -p "Choose option (1-8): " CHOICE

case $CHOICE in
  1)
    print_header "Setting up Anthropic Claude"
    
    echo "Get your API key from: https://console.anthropic.com/api-keys"
    read -s -p "Enter Anthropic API key (sk-...): " ANTHROPIC_API_KEY
    echo ""

    # Validate API key
    print_info "Validating API key..."
    if bash "$SCRIPT_DIR/validate-api-key.sh" anthropic "$ANTHROPIC_API_KEY"; then
        print_success "Anthropic API key validated successfully"
    else
        validation_result=$?
        if [ $validation_result -eq 1 ]; then
            print_error "API key validation failed"
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "Cancelled"
                exit 1
            fi
        else
            print_warning "Could not validate key (network issue). Continuing..."
        fi
    fi

    # Update .env (portable sed)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/^PRIMARY_AI_PROVIDER=/d' .env
        sed -i '' '/^ANTHROPIC_API_KEY=/d' .env
    else
        sed -i '/^PRIMARY_AI_PROVIDER=/d' .env
        sed -i '/^ANTHROPIC_API_KEY=/d' .env
    fi

    cat >> .env << EOF

PRIMARY_AI_PROVIDER=anthropic
ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
EOF

    # Install if needed
    if ! command -v node &> /dev/null; then
        print_info "Installing Node.js..."

        # Detect package manager
        if command -v apt-get &> /dev/null; then
            apt-get update -qq > /dev/null 2>&1
            apt-get install -y -qq nodejs npm > /dev/null 2>&1
        elif command -v yum &> /dev/null; then
            yum install -y nodejs npm > /dev/null 2>&1
        elif command -v dnf &> /dev/null; then
            dnf install -y nodejs npm > /dev/null 2>&1
        else
            print_error "Unsupported package manager. Install Node.js manually."
            exit 1
        fi
    fi
    
    print_info "Installing Claude Code CLI..."
    npm install -g @anthropic-ai/claude-code > /dev/null 2>&1
    
    print_success "Anthropic Claude configured"
    print_info "Usage: claude"
    ;;
  
  2)
    print_header "Setting up OpenAI ChatGPT"
    
    echo "Get your API key from: https://platform.openai.com/api-keys"
    read -s -p "Enter OpenAI API key (sk-...): " OPENAI_API_KEY
    echo ""

    # Validate API key
    print_info "Validating API key..."
    if bash "$SCRIPT_DIR/validate-api-key.sh" openai "$OPENAI_API_KEY"; then
        print_success "OpenAI API key validated successfully"
    else
        validation_result=$?
        if [ $validation_result -eq 1 ]; then
            print_error "API key validation failed"
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "Cancelled"
                exit 1
            fi
        else
            print_warning "Could not validate key (network issue). Continuing..."
        fi
    fi

    # Update .env (portable sed)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/^PRIMARY_AI_PROVIDER=/d' .env
        sed -i '' '/^OPENAI_API_KEY=/d' .env
    else
        sed -i '/^PRIMARY_AI_PROVIDER=/d' .env
        sed -i '/^OPENAI_API_KEY=/d' .env
    fi

    cat >> .env << EOF

PRIMARY_AI_PROVIDER=openai
OPENAI_API_KEY=${OPENAI_API_KEY}
EOF

    # Install if needed
    if ! command -v node &> /dev/null; then
        print_info "Installing Node.js..."

        # Detect package manager
        if command -v apt-get &> /dev/null; then
            apt-get update -qq > /dev/null 2>&1
            apt-get install -y -qq nodejs npm > /dev/null 2>&1
        elif command -v yum &> /dev/null; then
            yum install -y nodejs npm > /dev/null 2>&1
        elif command -v dnf &> /dev/null; then
            dnf install -y nodejs npm > /dev/null 2>&1
        else
            print_error "Unsupported package manager. Install Node.js manually."
            exit 1
        fi
    fi
    
    print_info "Installing ChatGPT CLI..."
    npm install -g chatgpt-cli > /dev/null 2>&1
    
    print_success "OpenAI ChatGPT configured"
    print_info "Usage: chatgpt"
    ;;
  
  3)
    print_header "Setting up Google Gemini"
    
    echo "Get your API key from: https://ai.google.dev/tutorials/setup"
    read -s -p "Enter Google API key: " GOOGLE_API_KEY
    echo ""

    # Validate API key
    print_info "Validating API key..."
    if bash "$SCRIPT_DIR/validate-api-key.sh" google "$GOOGLE_API_KEY"; then
        print_success "Google Gemini API key validated successfully"
    else
        validation_result=$?
        if [ $validation_result -eq 1 ]; then
            print_error "API key validation failed"
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_info "Cancelled"
                exit 1
            fi
        else
            print_warning "Could not validate key (network issue). Continuing..."
        fi
    fi

    # Update .env (portable sed)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/^PRIMARY_AI_PROVIDER=/d' .env
        sed -i '' '/^GOOGLE_API_KEY=/d' .env
    else
        sed -i '/^PRIMARY_AI_PROVIDER=/d' .env
        sed -i '/^GOOGLE_API_KEY=/d' .env
    fi

    cat >> .env << EOF

PRIMARY_AI_PROVIDER=google
GOOGLE_API_KEY=${GOOGLE_API_KEY}
EOF

    # Install if needed
    if ! command -v node &> /dev/null; then
        print_info "Installing Node.js..."

        # Detect package manager
        if command -v apt-get &> /dev/null; then
            apt-get update -qq > /dev/null 2>&1
            apt-get install -y -qq nodejs npm > /dev/null 2>&1
        elif command -v yum &> /dev/null; then
            yum install -y nodejs npm > /dev/null 2>&1
        elif command -v dnf &> /dev/null; then
            dnf install -y nodejs npm > /dev/null 2>&1
        else
            print_error "Unsupported package manager. Install Node.js manually."
            exit 1
        fi
    fi
    
    print_info "Installing Google Gemini CLI..."
    npm install -g @google/generative-ai > /dev/null 2>&1
    
    print_success "Google Gemini configured"
    print_info "Usage: google-ai"
    print_info "Cost: $0.25-0.50 per 1M tokens (CHEAPEST option)"
    ;;
  
  4)
    print_header "Setting up Local Ollama (FREE)"
    
    # Update .env (portable sed)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' '/^PRIMARY_AI_PROVIDER=/d' .env
        sed -i '' '/^OLLAMA_BASE_URL=/d' .env
    else
        sed -i '/^PRIMARY_AI_PROVIDER=/d' .env
        sed -i '/^OLLAMA_BASE_URL=/d' .env
    fi

    cat >> .env << EOF

PRIMARY_AI_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
EOF
    
    # Install if needed
    if ! command -v ollama &> /dev/null; then
        print_info "Installing Ollama..."
        curl -fsSL https://ollama.ai/install.sh | sh > /dev/null 2>&1
    fi
    
    print_info "Starting Ollama service..."
    ollama serve > /dev/null 2>&1 &
    sleep 5
    
    print_info "Downloading Mistral model (first time takes a few minutes)..."
    ollama pull mistral > /dev/null 2>&1
    
    print_success "Ollama configured with Mistral model"
    print_info "Usage: ollama run mistral"
    print_info "Cost: FREE, works completely offline"
    print_info "Other models: ollama pull neural-chat, ollama pull llama2"
    ;;
  
  5)
    print_header "Available AI Providers"
    
    echo "1. Anthropic Claude"
    echo "   - CLI: Claude Code"
    echo "   - Command: claude"
    echo "   - Cost: $3-15 per 1M tokens"
    echo "   - Best for: Complex tasks, highest quality"
    echo ""
    
    echo "2. OpenAI ChatGPT"
    echo "   - CLI: ChatGPT CLI"
    echo "   - Command: chatgpt"
    echo "   - Cost: $0.50-60 per 1M tokens"
    echo "   - Best for: General purpose, popular models"
    echo ""
    
    echo "3. Google Gemini"
    echo "   - CLI: Google AI CLI"
    echo "   - Command: google-ai"
    echo "   - Cost: $0.25-0.50 per 1M tokens (CHEAPEST)"
    echo "   - Best for: Budget-conscious, efficient models"
    echo ""
    
    echo "4. Local Ollama"
    echo "   - CLI: Ollama"
    echo "   - Command: ollama run <model>"
    echo "   - Cost: FREE"
    echo "   - Best for: Privacy, offline use, no API limits"
    echo "   - Models: Mistral, Llama 2, Neural Chat, etc."
    echo ""
    
    echo "5. Other Options"
    echo "   - Aider: Multi-provider support"
    echo "   - LM Studio: GUI-based local models"
    echo "   - Continue: IDE plugin (Claude, OpenAI, Gemini)"
    ;;
  
  6)
    print_header "Testing Current Provider"
    
    if [ "$CURRENT_PROVIDER" = "anthropic" ]; then
        print_info "Testing Anthropic Claude..."
        if command -v claude &> /dev/null; then
            print_success "Claude Code CLI is installed"
            CLAUDE_VERSION=$(claude --version 2>/dev/null || echo "unknown")
            print_info "Version: $CLAUDE_VERSION"
        else
            print_error "Claude Code CLI not installed"
        fi
    elif [ "$CURRENT_PROVIDER" = "openai" ]; then
        print_info "Testing OpenAI ChatGPT..."
        if command -v chatgpt &> /dev/null; then
            print_success "ChatGPT CLI is installed"
        else
            print_error "ChatGPT CLI not installed"
        fi
    elif [ "$CURRENT_PROVIDER" = "google" ]; then
        print_info "Testing Google Gemini..."
        if npm list -g @google/generative-ai &> /dev/null; then
            print_success "Google Gemini CLI is installed"
        else
            print_error "Google Gemini CLI not installed"
        fi
    elif [ "$CURRENT_PROVIDER" = "ollama" ]; then
        print_info "Testing Ollama..."
        if command -v ollama &> /dev/null; then
            print_success "Ollama is installed"
            ollama list 2>/dev/null || print_warning "Ollama service not running"
        else
            print_error "Ollama not installed"
        fi
    else
        print_warning "No AI provider configured"
    fi
    ;;
  
  7)
    print_header "Uninstalling All AI Providers"
    
    read -p "Are you sure? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstalling AI providers..."
        
        npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
        npm uninstall -g chatgpt-cli 2>/dev/null || true
        npm uninstall -g @google/generative-ai 2>/dev/null || true

        # Update .env (portable sed)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/^PRIMARY_AI_PROVIDER=/d' .env
            sed -i '' '/^ANTHROPIC_API_KEY=/d' .env
            sed -i '' '/^OPENAI_API_KEY=/d' .env
            sed -i '' '/^GOOGLE_API_KEY=/d' .env
            sed -i '' '/^OLLAMA_BASE_URL=/d' .env
        else
            sed -i '/^PRIMARY_AI_PROVIDER=/d' .env
            sed -i '/^ANTHROPIC_API_KEY=/d' .env
            sed -i '/^OPENAI_API_KEY=/d' .env
            sed -i '/^GOOGLE_API_KEY=/d' .env
            sed -i '/^OLLAMA_BASE_URL=/d' .env
        fi

        cat >> .env << EOF

PRIMARY_AI_PROVIDER=
EOF
        
        print_success "All AI providers uninstalled"
    else
        print_info "Cancelled"
    fi
    ;;
  
  8)
    print_info "Exiting"
    exit 0
    ;;
  
  *)
    print_error "Invalid option"
    exit 1
    ;;
esac

print_header "AI Provider Setup Complete!"

NEW_PROVIDER=$(grep "PRIMARY_AI_PROVIDER=" .env | cut -d '=' -f2 | tr -d ' ' || echo "none")

if [ -z "$NEW_PROVIDER" ] || [ "$NEW_PROVIDER" = "none" ]; then
    print_info "No AI provider configured"
else
    print_success "Primary provider set to: $NEW_PROVIDER"
fi

echo ""
print_info "To run provider commands from VPS:"
echo "  ssh root@YOUR_VPS_IP"
echo ""

case $NEW_PROVIDER in
  anthropic)
    echo "  claude              # Start Claude Code session"
    echo "  /help               # Show available commands"
    echo "  /status             # Check token usage"
    ;;
  openai)
    echo "  chatgpt             # Start ChatGPT session"
    echo "  chatgpt ask <query> # Ask single question"
    ;;
  google)
    echo "  google-ai           # Start Gemini session"
    ;;
  ollama)
    echo "  ollama run mistral  # Run Mistral model"
    echo "  ollama list         # List available models"
    ;;
esac

echo ""
print_info "To switch providers later, run this script again"
print_info "To see documentation: see docs/13-AI-PROVIDERS.md"
