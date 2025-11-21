#!/bin/bash

################################################################################
# API Key Validator
# Tests AI provider API keys before installation
# Returns: 0 (valid), 1 (invalid), 2 (network error)
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

validate_anthropic() {
    local api_key="$1"

    echo "Validating Anthropic Claude API key..."

    # Test API key with a minimal request
    response=$(curl -s -w "\n%{http_code}" --max-time 10 \
        https://api.anthropic.com/v1/messages \
        -H "Content-Type: application/json" \
        -H "x-api-key: $api_key" \
        -H "anthropic-version: 2023-06-01" \
        -d '{
            "model": "claude-3-haiku-20240307",
            "max_tokens": 10,
            "messages": [{"role": "user", "content": "test"}]
        }' 2>&1)

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ Anthropic API key is valid${NC}"
        return 0
    elif [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
        echo -e "${RED}✗ Invalid Anthropic API key${NC}"
        echo "  HTTP Status: $http_code"
        echo "  Key format should be: sk-ant-..."
        return 1
    elif [ -z "$http_code" ] || [ "$http_code" = "000" ]; then
        echo -e "${YELLOW}⚠ Network error - cannot reach Anthropic API${NC}"
        return 2
    else
        echo -e "${YELLOW}⚠ Unexpected response from Anthropic API${NC}"
        echo "  HTTP Status: $http_code"
        return 2
    fi
}

validate_openai() {
    local api_key="$1"

    echo "Validating OpenAI API key..."

    # Test with models endpoint (lightweight)
    response=$(curl -s -w "\n%{http_code}" --max-time 10 \
        https://api.openai.com/v1/models \
        -H "Authorization: Bearer $api_key" 2>&1)

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ OpenAI API key is valid${NC}"
        return 0
    elif [ "$http_code" = "401" ] || [ "$http_code" = "403" ]; then
        echo -e "${RED}✗ Invalid OpenAI API key${NC}"
        echo "  HTTP Status: $http_code"
        echo "  Key format should be: sk-..."
        return 1
    elif [ -z "$http_code" ] || [ "$http_code" = "000" ]; then
        echo -e "${YELLOW}⚠ Network error - cannot reach OpenAI API${NC}"
        return 2
    else
        echo -e "${YELLOW}⚠ Unexpected response from OpenAI API${NC}"
        echo "  HTTP Status: $http_code"
        return 2
    fi
}

validate_google() {
    local api_key="$1"

    echo "Validating Google Gemini API key..."

    # Test with generateContent endpoint
    response=$(curl -s -w "\n%{http_code}" --max-time 10 \
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$api_key" \
        -H "Content-Type: application/json" \
        -d '{
            "contents": [{
                "parts": [{"text": "test"}]
            }]
        }' 2>&1)

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n -1)

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓ Google Gemini API key is valid${NC}"
        return 0
    elif [ "$http_code" = "400" ]; then
        # Check if it's an API key error
        if echo "$body" | grep -qi "API_KEY_INVALID\|invalid.*api.*key"; then
            echo -e "${RED}✗ Invalid Google API key${NC}"
            echo "  HTTP Status: $http_code"
            return 1
        else
            echo -e "${GREEN}✓ Google Gemini API key is valid${NC}"
            echo "  (Request format issue, but key authenticated)"
            return 0
        fi
    elif [ "$http_code" = "403" ]; then
        echo -e "${RED}✗ Google API key is invalid or lacks permissions${NC}"
        echo "  HTTP Status: $http_code"
        echo "  Ensure Generative Language API is enabled"
        return 1
    elif [ -z "$http_code" ] || [ "$http_code" = "000" ]; then
        echo -e "${YELLOW}⚠ Network error - cannot reach Google API${NC}"
        return 2
    else
        echo -e "${YELLOW}⚠ Unexpected response from Google API${NC}"
        echo "  HTTP Status: $http_code"
        return 2
    fi
}

validate_ollama() {
    echo "Validating Ollama service..."

    # Check if ollama is running
    if command -v ollama &> /dev/null; then
        if curl -s --max-time 5 http://localhost:11434/api/tags &> /dev/null; then
            echo -e "${GREEN}✓ Ollama service is running${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ Ollama is installed but not running${NC}"
            echo "  Start it with: ollama serve"
            return 2
        fi
    else
        echo -e "${YELLOW}⚠ Ollama not installed${NC}"
        echo "  It will be installed during setup"
        return 0  # Not an error, will be installed
    fi
}

# Main execution
if [ $# -lt 2 ]; then
    echo "Usage: $0 <provider> <api_key>"
    echo "Providers: anthropic, openai, google, ollama"
    exit 1
fi

PROVIDER="$1"
API_KEY="$2"

case "$PROVIDER" in
    anthropic)
        validate_anthropic "$API_KEY"
        exit $?
        ;;
    openai)
        validate_openai "$API_KEY"
        exit $?
        ;;
    google)
        validate_google "$API_KEY"
        exit $?
        ;;
    ollama)
        validate_ollama
        exit $?
        ;;
    *)
        echo "Unknown provider: $PROVIDER"
        echo "Valid providers: anthropic, openai, google, ollama"
        exit 1
        ;;
esac
