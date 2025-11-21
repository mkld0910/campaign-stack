#!/usr/bin/env python3
"""
AI Policy Chatbot - Multi-Backend Router
Intelligently routes queries to optimal AI backend based on complexity and budget
"""

import os
import json
import time
import uuid
from datetime import datetime
from typing import Dict, List, Optional, Tuple

from flask import Flask, request, jsonify
from flask_cors import CORS
import pymysql
import requests

# Import AI backend clients (will fail gracefully if not configured)
try:
    from anthropic import Anthropic
except ImportError:
    Anthropic = None

try:
    import openai
except ImportError:
    openai = None

try:
    import google.generativeai as genai
except ImportError:
    genai = None

app = Flask(__name__)
CORS(app)

# ============================================================================
# Configuration
# ============================================================================

class Config:
    """Configuration from environment variables"""

    # Database
    DB_HOST = os.getenv('CHATBOT_DB_HOST', 'chatbot_db')
    DB_NAME = os.getenv('CHATBOT_DB_NAME', 'chatbot')
    DB_USER = os.getenv('CHATBOT_DB_USER', 'chatbot')
    DB_PASSWORD = os.getenv('CHATBOT_DB_PASSWORD', 'chatbotsecure123')

    # AI Backends
    DEFAULT_BACKEND = os.getenv('CHATBOT_DEFAULT_BACKEND', 'ollama')
    OLLAMA_HOST = os.getenv('OLLAMA_HOST', 'http://ai_provider:11434')
    OLLAMA_MODEL = os.getenv('OLLAMA_MODEL', 'llama2')
    ANTHROPIC_API_KEY = os.getenv('ANTHROPIC_API_KEY', '')
    ANTHROPIC_MODEL = os.getenv('ANTHROPIC_MODEL', 'claude-3-haiku-20240307')
    OPENAI_API_KEY = os.getenv('OPENAI_API_KEY', '')
    OPENAI_MODEL = os.getenv('OPENAI_MODEL', 'gpt-4o-mini')
    GOOGLE_API_KEY = os.getenv('GOOGLE_API_KEY', '')
    GOOGLE_MODEL = os.getenv('GOOGLE_MODEL', 'gemini-pro')

    # Budget Controls
    MONTHLY_BUDGET = float(os.getenv('CHATBOT_MONTHLY_BUDGET', '100'))
    ANTHROPIC_BUDGET = float(os.getenv('CHATBOT_ANTHROPIC_BUDGET', '50'))
    OPENAI_BUDGET = float(os.getenv('CHATBOT_OPENAI_BUDGET', '30'))
    GOOGLE_BUDGET = float(os.getenv('CHATBOT_GOOGLE_BUDGET', '20'))

    # Routing Thresholds (tokens)
    SIMPLE_THRESHOLD = int(os.getenv('CHATBOT_SIMPLE_TOKENS', '50'))
    COMPLEX_THRESHOLD = int(os.getenv('CHATBOT_COMPLEX_TOKENS', '200'))

    # Privacy
    REQUIRE_CONSENT = os.getenv('CHATBOT_REQUIRE_CONSENT', 'true').lower() == 'true'
    ANONYMIZE_DATA = os.getenv('CHATBOT_ANONYMIZE_DATA', 'true').lower() == 'true'

config = Config()

# ============================================================================
# Database Connection
# ============================================================================

def get_db_connection():
    """Create database connection"""
    return pymysql.connect(
        host=config.DB_HOST,
        user=config.DB_USER,
        password=config.DB_PASSWORD,
        database=config.DB_NAME,
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )

# ============================================================================
# Backend Clients
# ============================================================================

class AIBackend:
    """Base class for AI backend integrations"""

    @staticmethod
    def estimate_tokens(text: str) -> int:
        """Rough token estimation (4 chars ≈ 1 token)"""
        return len(text) // 4

    @staticmethod
    def detect_sophistication(message: str) -> str:
        """Detect sophistication level from message phrasing"""
        message_lower = message.lower()

        # Low sophistication indicators
        low_indicators = [
            'explain like', 'eli5', 'simple terms', 'what does',
            'what is', 'how does', 'in english', 'basic'
        ]

        # High sophistication indicators
        high_indicators = [
            'implementation', 'methodology', 'framework', 'analyze',
            'comparative', 'empirical', 'research', 'study shows',
            'data suggests', 'statistical'
        ]

        low_count = sum(1 for ind in low_indicators if ind in message_lower)
        high_count = sum(1 for ind in high_indicators if ind in message_lower)

        if low_count > high_count:
            return 'low'
        elif high_count > 0:
            return 'high'
        else:
            return 'medium'

class OllamaBackend(AIBackend):
    """Ollama local model backend"""

    @staticmethod
    def query(prompt: str, system_prompt: str = "") -> Tuple[str, int, float]:
        """
        Query Ollama model
        Returns: (response_text, tokens_used, cost)
        """
        try:
            payload = {
                "model": config.OLLAMA_MODEL,
                "prompt": prompt,
                "stream": False
            }

            if system_prompt:
                payload["system"] = system_prompt

            response = requests.post(
                f"{config.OLLAMA_HOST}/api/generate",
                json=payload,
                timeout=60
            )

            if response.status_code == 200:
                data = response.json()
                tokens = data.get('eval_count', 0) + data.get('prompt_eval_count', 0)
                return data.get('response', ''), tokens, 0.0  # Ollama is free
            else:
                raise Exception(f"Ollama error: {response.status_code}")

        except Exception as e:
            print(f"Ollama query failed: {e}")
            raise

class AnthropicBackend(AIBackend):
    """Anthropic Claude backend"""

    @staticmethod
    def query(prompt: str, system_prompt: str = "") -> Tuple[str, int, float]:
        """
        Query Anthropic Claude
        Returns: (response_text, tokens_used, cost)
        """
        if not Anthropic or not config.ANTHROPIC_API_KEY:
            raise Exception("Anthropic not configured")

        try:
            client = Anthropic(api_key=config.ANTHROPIC_API_KEY)

            message = client.messages.create(
                model=config.ANTHROPIC_MODEL,
                max_tokens=1024,
                system=system_prompt if system_prompt else "You are a helpful political campaign policy assistant.",
                messages=[
                    {"role": "user", "content": prompt}
                ]
            )

            tokens = message.usage.input_tokens + message.usage.output_tokens

            # Cost calculation (example rates for Haiku)
            cost = (message.usage.input_tokens * 0.00025 / 1000) + \
                   (message.usage.output_tokens * 0.00125 / 1000)

            return message.content[0].text, tokens, cost

        except Exception as e:
            print(f"Anthropic query failed: {e}")
            raise

class OpenAIBackend(AIBackend):
    """OpenAI GPT backend"""

    @staticmethod
    def query(prompt: str, system_prompt: str = "") -> Tuple[str, int, float]:
        """
        Query OpenAI GPT
        Returns: (response_text, tokens_used, cost)
        """
        if not openai or not config.OPENAI_API_KEY:
            raise Exception("OpenAI not configured")

        try:
            client = openai.OpenAI(api_key=config.OPENAI_API_KEY)

            messages = [
                {"role": "system", "content": system_prompt if system_prompt else "You are a helpful political campaign policy assistant."},
                {"role": "user", "content": prompt}
            ]

            response = client.chat.completions.create(
                model=config.OPENAI_MODEL,
                messages=messages,
                max_tokens=1024
            )

            tokens = response.usage.total_tokens

            # Cost calculation (example rates for GPT-4o-mini)
            cost = (response.usage.prompt_tokens * 0.00015 / 1000) + \
                   (response.usage.completion_tokens * 0.0006 / 1000)

            return response.choices[0].message.content, tokens, cost

        except Exception as e:
            print(f"OpenAI query failed: {e}")
            raise

# ============================================================================
# Routing Logic
# ============================================================================

class RouterService:
    """Intelligent backend routing based on complexity and budget"""

    @staticmethod
    def select_backend(message: str, complexity_override: Optional[str] = None) -> str:
        """
        Select optimal backend based on query complexity and budget
        Returns: backend name ('ollama', 'anthropic', 'openai', 'google')
        """
        # Estimate complexity
        estimated_tokens = AIBackend.estimate_tokens(message)

        # Check budget availability
        current_month = datetime.now().strftime('%Y-%m')

        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT backend, budget_limit, current_spend
                    FROM chatbot_budget_tracking
                    WHERE month_year = %s
                """, (current_month,))
                budgets = {row['backend']: row for row in cursor.fetchall()}

        # Simple queries → Ollama (free)
        if estimated_tokens < config.SIMPLE_THRESHOLD:
            return 'ollama'

        # Medium queries → OpenAI (cost-efficient) if budget available
        if estimated_tokens < config.COMPLEX_THRESHOLD:
            if 'openai' in budgets:
                budget = budgets['openai']
                if budget['current_spend'] < budget['budget_limit'] and config.OPENAI_API_KEY:
                    return 'openai'
            return 'ollama'  # Fallback to free

        # Complex queries → Anthropic (advanced reasoning) if budget available
        if 'anthropic' in budgets:
            budget = budgets['anthropic']
            if budget['current_spend'] < budget['budget_limit'] and config.ANTHROPIC_API_KEY:
                return 'anthropic'

        # Fallback chain: OpenAI → Ollama
        if 'openai' in budgets:
            budget = budgets['openai']
            if budget['current_spend'] < budget['budget_limit'] and config.OPENAI_API_KEY:
                return 'openai'

        return 'ollama'

    @staticmethod
    def route_query(backend: str, prompt: str, system_prompt: str = "") -> Tuple[str, int, float]:
        """
        Route query to specified backend
        Returns: (response, tokens, cost)
        """
        if backend == 'ollama':
            return OllamaBackend.query(prompt, system_prompt)
        elif backend == 'anthropic':
            return AnthropicBackend.query(prompt, system_prompt)
        elif backend == 'openai':
            return OpenAIBackend.query(prompt, system_prompt)
        else:
            # Fallback to Ollama
            return OllamaBackend.query(prompt, system_prompt)

# ============================================================================
# API Routes
# ============================================================================

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'AI Policy Chatbot Router',
        'backends_available': {
            'ollama': True,  # Always available
            'anthropic': bool(config.ANTHROPIC_API_KEY),
            'openai': bool(config.OPENAI_API_KEY),
            'google': bool(config.GOOGLE_API_KEY)
        }
    })

@app.route('/api/chat', methods=['POST'])
def chat():
    """
    Main chat endpoint
    Accepts: message, session_id, contact_id (optional), consent, context
    Returns: response, sophistication_level, backend_used, cost, sources
    """
    start_time = time.time()

    try:
        data = request.json
        message = data.get('message', '').strip()
        session_id = data.get('session_id')
        contact_id = data.get('contact_id')
        consent = data.get('consent', False)
        context = data.get('context', {})

        if not message:
            return jsonify({'error': 'Message is required'}), 400

        if not session_id:
            session_id = str(uuid.uuid4())

        # Detect sophistication
        sophistication = AIBackend.detect_sophistication(message)

        # Select backend
        backend = RouterService.select_backend(message)

        # Build system prompt based on sophistication
        system_prompts = {
            'low': "You are a helpful political campaign policy assistant. Explain policies in simple, accessible language using everyday examples and analogies. Avoid jargon.",
            'medium': "You are a helpful political campaign policy assistant. Provide clear policy explanations with specific details and relevant examples.",
            'high': "You are a helpful political campaign policy assistant. Provide detailed policy analysis with technical specifics, research citations, and implementation details."
        }

        system_prompt = system_prompts.get(sophistication, system_prompts['medium'])

        # Route query
        try:
            response_text, tokens_used, cost = RouterService.route_query(
                backend, message, system_prompt
            )
        except Exception as e:
            # Fallback to Ollama if primary backend fails
            print(f"Primary backend failed, falling back to Ollama: {e}")
            backend = 'ollama'
            response_text, tokens_used, cost = OllamaBackend.query(message, system_prompt)

        processing_time = int((time.time() - start_time) * 1000)

        # Log to database
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                # Create/update conversation
                cursor.execute("""
                    INSERT INTO chatbot_conversations
                    (session_id, civicrm_contact_id, consent_given, detected_sophistication, region)
                    VALUES (%s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                    total_messages = total_messages + 1,
                    detected_sophistication = %s
                """, (session_id, contact_id, consent, sophistication,
                      context.get('region'), sophistication))

                # Get conversation ID
                cursor.execute("SELECT id FROM chatbot_conversations WHERE session_id = %s", (session_id,))
                conversation = cursor.fetchone()
                conversation_id = conversation['id']

                # Log user message
                cursor.execute("""
                    INSERT INTO chatbot_messages
                    (conversation_id, message_type, message_text, created_at)
                    VALUES (%s, 'user', %s, NOW())
                """, (conversation_id, message))

                # Log assistant response
                cursor.execute("""
                    INSERT INTO chatbot_messages
                    (conversation_id, message_type, message_text, response_sophistication,
                     ai_backend, cost, tokens_used, processing_time_ms, created_at)
                    VALUES (%s, 'assistant', %s, %s, %s, %s, %s, %s, NOW())
                """, (conversation_id, response_text, sophistication, backend,
                      cost, tokens_used, processing_time))

                message_id = cursor.lastrowid

                # Log cost if non-zero
                if cost > 0:
                    cursor.execute("CALL sp_log_message_cost(%s, %s, %s, %s)",
                                 (message_id, backend, cost, tokens_used))

                conn.commit()

        return jsonify({
            'response': response_text,
            'session_id': session_id,
            'sophistication_level': sophistication,
            'backend_used': backend,
            'cost': cost,
            'tokens_used': tokens_used,
            'processing_time_ms': processing_time,
            'sources': [],  # Will be populated by Wiki.js connector in Phase 2
            'follow_up_suggestions': []  # Will be populated in Phase 2
        })

    except Exception as e:
        print(f"Chat error: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/analytics/costs', methods=['GET'])
def get_costs():
    """Get cost analytics"""
    try:
        period = request.args.get('period', 'month')  # day, week, month

        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                if period == 'day':
                    cursor.execute("""
                        SELECT backend, SUM(cost_usd) as total_cost, COUNT(*) as query_count
                        FROM chatbot_costs
                        WHERE DATE(created_at) = CURDATE()
                        GROUP BY backend
                    """)
                else:  # month
                    cursor.execute("""
                        SELECT backend, SUM(cost_usd) as total_cost, COUNT(*) as query_count
                        FROM chatbot_costs
                        WHERE DATE_FORMAT(created_at, '%Y-%m') = DATE_FORMAT(NOW(), '%Y-%m')
                        GROUP BY backend
                    """)

                costs = cursor.fetchall()

        return jsonify({'costs': costs})

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/analytics/conversations', methods=['GET'])
def get_conversations():
    """Get conversation analytics"""
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT
                        COUNT(*) as total_conversations,
                        AVG(total_messages) as avg_messages_per_conversation,
                        COUNT(DISTINCT civicrm_contact_id) as unique_contacts,
                        SUM(CASE WHEN consent_given = TRUE THEN 1 ELSE 0 END) as consented_conversations
                    FROM chatbot_conversations
                    WHERE DATE(started_at) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
                """)

                stats = cursor.fetchone()

        return jsonify(stats)

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# Main
# ============================================================================

if __name__ == '__main__':
    port = int(os.getenv('CHATBOT_API_PORT', 5001))
    app.run(host='0.0.0.0', port=port, debug=False)
