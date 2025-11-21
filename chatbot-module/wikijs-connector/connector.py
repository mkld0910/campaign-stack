#!/usr/bin/env python3
"""
Wiki.js GraphQL Connector
Fetches policy content from Wiki.js and caches for chatbot use
"""

import os
import json
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional

from flask import Flask, request, jsonify
from flask_cors import CORS
import pymysql
import requests

app = Flask(__name__)
CORS(app)

# ============================================================================
# Configuration
# ============================================================================

class Config:
    """Configuration from environment variables"""

    # Wiki.js
    WIKIJS_URL = os.getenv('WIKIJS_URL', 'http://wiki:3000')
    WIKIJS_API_KEY = os.getenv('WIKIJS_API_KEY', '')

    # Database
    DB_HOST = os.getenv('CHATBOT_DB_HOST', 'chatbot_db')
    DB_NAME = os.getenv('CHATBOT_DB_NAME', 'chatbot')
    DB_USER = os.getenv('CHATBOT_DB_USER', 'chatbot')
    DB_PASSWORD = os.getenv('CHATBOT_DB_PASSWORD', 'chatbotsecure123')

    # Cache settings
    CACHE_TTL_HOURS = int(os.getenv('WIKIJS_CACHE_TTL_HOURS', '24'))

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
# Wiki.js GraphQL Client
# ============================================================================

class WikiJSClient:
    """Wiki.js GraphQL API client"""

    def __init__(self):
        self.api_url = f"{config.WIKIJS_URL}/graphql"
        self.headers = {
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {config.WIKIJS_API_KEY}'
        }

    def query(self, graphql_query: str, variables: Optional[Dict] = None) -> Dict:
        """Execute GraphQL query"""
        try:
            payload = {
                'query': graphql_query,
                'variables': variables or {}
            }

            response = requests.post(
                self.api_url,
                json=payload,
                headers=self.headers,
                timeout=30
            )

            if response.status_code == 200:
                return response.json()
            else:
                raise Exception(f"Wiki.js GraphQL error: {response.status_code}")

        except Exception as e:
            print(f"Wiki.js query failed: {e}")
            raise

    def list_pages(self, tags: Optional[List[str]] = None) -> List[Dict]:
        """List all pages, optionally filtered by tags"""
        query = """
        query ($tags: [String!]) {
            pages {
                list(tags: $tags) {
                    id
                    path
                    title
                    description
                    tags
                    updatedAt
                }
            }
        }
        """

        variables = {'tags': tags} if tags else {}
        result = self.query(query, variables)

        return result.get('data', {}).get('pages', {}).get('list', [])

    def get_page_content(self, page_id: int) -> Optional[Dict]:
        """Get full page content by ID"""
        query = """
        query ($id: Int!) {
            pages {
                single(id: $id) {
                    id
                    path
                    title
                    description
                    content
                    tags
                    updatedAt
                }
            }
        }
        """

        result = self.query(query, {'id': page_id})
        return result.get('data', {}).get('pages', {}).get('single')

    def search_pages(self, search_query: str) -> List[Dict]:
        """Search pages by query"""
        query = """
        query ($query: String!) {
            pages {
                search(query: $query) {
                    results {
                        id
                        title
                        path
                        description
                    }
                }
            }
        }
        """

        result = self.query(query, {'query': search_query})
        return result.get('data', {}).get('pages', {}).get('search', {}).get('results', [])

# ============================================================================
# Content Processing
# ============================================================================

class ContentProcessor:
    """Process Wiki.js content into sophistication levels"""

    @staticmethod
    def extract_by_heading(content: str, heading: str) -> Optional[str]:
        """Extract content under a specific heading"""
        lines = content.split('\n')
        capturing = False
        captured = []

        for line in lines:
            # Check if this is the target heading
            if line.strip().startswith('#') and heading.lower() in line.lower():
                capturing = True
                continue

            # Stop at next heading of same or higher level
            if capturing and line.strip().startswith('#'):
                # Check heading level
                target_level = heading.count('#')
                current_level = len(line) - len(line.lstrip('#'))
                if current_level <= target_level:
                    break

            if capturing:
                captured.append(line)

        return '\n'.join(captured).strip() if captured else None

    @staticmethod
    def extract_sophistication_content(page_content: Dict) -> Dict[str, str]:
        """
        Extract simple, medium, and detailed explanations from Wiki.js page

        Expected structure in Wiki.js:
        ## Simple Explanation
        [content]

        ## Detailed Explanation
        [content]

        ## Technical Explanation
        [content]
        """
        content = page_content.get('content', '')

        return {
            'simple': ContentProcessor.extract_by_heading(content, '## Simple Explanation') or
                     ContentProcessor.extract_by_heading(content, '## Basic') or '',
            'medium': ContentProcessor.extract_by_heading(content, '## Detailed Explanation') or
                     ContentProcessor.extract_by_heading(content, '## Overview') or
                     content,  # Default to full content
            'detailed': ContentProcessor.extract_by_heading(content, '## Technical Explanation') or
                       ContentProcessor.extract_by_heading(content, '## Advanced') or ''
        }

    @staticmethod
    def extract_region_from_tags(tags: List[str]) -> Optional[str]:
        """Extract region from tags like 'region:District-5'"""
        for tag in tags:
            if tag.startswith('region:'):
                return tag.split(':', 1)[1]
        return None

# ============================================================================
# Cache Management
# ============================================================================

class CacheManager:
    """Manage Wiki.js content cache in database"""

    @staticmethod
    def cache_page(page_data: Dict):
        """Cache a Wiki.js page in database"""
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                # Extract sophistication levels
                content_levels = ContentProcessor.extract_sophistication_content(page_data)
                region = ContentProcessor.extract_region_from_tags(page_data.get('tags', []))

                # Set expiration
                expires_at = datetime.now() + timedelta(hours=config.CACHE_TTL_HOURS)

                cursor.execute("""
                    INSERT INTO chatbot_wikijs_cache
                    (page_id, page_path, page_title, content_simple, content_medium,
                     content_detailed, tags, region, expires_at, version)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 1)
                    ON DUPLICATE KEY UPDATE
                    page_path = VALUES(page_path),
                    page_title = VALUES(page_title),
                    content_simple = VALUES(content_simple),
                    content_medium = VALUES(content_medium),
                    content_detailed = VALUES(content_detailed),
                    tags = VALUES(tags),
                    region = VALUES(region),
                    last_fetched = CURRENT_TIMESTAMP,
                    expires_at = VALUES(expires_at),
                    version = version + 1
                """, (
                    page_data['id'],
                    page_data['path'],
                    page_data['title'],
                    content_levels['simple'],
                    content_levels['medium'],
                    content_levels['detailed'],
                    json.dumps(page_data.get('tags', [])),
                    region,
                    expires_at
                ))

                conn.commit()

    @staticmethod
    def get_cached_page(page_id: int) -> Optional[Dict]:
        """Get cached page if not expired"""
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT * FROM chatbot_wikijs_cache
                    WHERE page_id = %s
                    AND (expires_at IS NULL OR expires_at > NOW())
                """, (page_id,))

                return cursor.fetchone()

    @staticmethod
    def search_cache(query: str, sophistication: str = 'medium') -> List[Dict]:
        """Search cached content"""
        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                content_column = f'content_{sophistication}'

                cursor.execute(f"""
                    SELECT page_id, page_path, page_title, {content_column} as content, tags
                    FROM chatbot_wikijs_cache
                    WHERE (expires_at IS NULL OR expires_at > NOW())
                    AND (
                        page_title LIKE %s OR
                        page_path LIKE %s OR
                        {content_column} LIKE %s
                    )
                    LIMIT 10
                """, (f'%{query}%', f'%{query}%', f'%{query}%'))

                return cursor.fetchall()

# ============================================================================
# API Routes
# ============================================================================

@app.route('/health', methods=['GET'])
def health():
    """Health check"""
    return jsonify({
        'status': 'healthy',
        'service': 'Wiki.js Connector',
        'wikijs_configured': bool(config.WIKIJS_API_KEY)
    })

@app.route('/api/sync', methods=['POST'])
def sync_all():
    """Sync all policy pages from Wiki.js"""
    try:
        client = WikiJSClient()

        # Fetch policy pages
        policy_tags = ['policy-priority', 'policy']
        pages = client.list_pages(tags=policy_tags)

        synced_count = 0
        for page in pages:
            # Fetch full content
            page_content = client.get_page_content(page['id'])
            if page_content:
                CacheManager.cache_page(page_content)
                synced_count += 1

        return jsonify({
            'status': 'success',
            'pages_synced': synced_count
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/page/<int:page_id>', methods=['GET'])
def get_page(page_id: int):
    """Get page content by ID (from cache or fetch from Wiki.js)"""
    try:
        sophistication = request.args.get('sophistication', 'medium')

        # Check cache first
        cached = CacheManager.get_cached_page(page_id)
        if cached:
            content_key = f'content_{sophistication}'
            return jsonify({
                'page_id': cached['page_id'],
                'title': cached['page_title'],
                'path': cached['page_path'],
                'content': cached.get(content_key, ''),
                'tags': json.loads(cached['tags']) if cached['tags'] else [],
                'cached': True
            })

        # Fetch from Wiki.js
        client = WikiJSClient()
        page_content = client.get_page_content(page_id)

        if not page_content:
            return jsonify({'error': 'Page not found'}), 404

        # Cache it
        CacheManager.cache_page(page_content)

        # Extract requested sophistication level
        content_levels = ContentProcessor.extract_sophistication_content(page_content)

        return jsonify({
            'page_id': page_content['id'],
            'title': page_content['title'],
            'path': page_content['path'],
            'content': content_levels.get(sophistication, content_levels['medium']),
            'tags': page_content.get('tags', []),
            'cached': False
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/search', methods=['GET'])
def search():
    """Search for policy content"""
    try:
        query = request.args.get('q', '').strip()
        sophistication = request.args.get('sophistication', 'medium')

        if not query:
            return jsonify({'error': 'Query parameter required'}), 400

        # Search cache first
        results = CacheManager.search_cache(query, sophistication)

        if results:
            return jsonify({
                'results': [
                    {
                        'page_id': r['page_id'],
                        'title': r['page_title'],
                        'path': r['page_path'],
                        'excerpt': r['content'][:200] + '...' if len(r['content']) > 200 else r['content'],
                        'tags': json.loads(r['tags']) if r['tags'] else []
                    }
                    for r in results
                ],
                'source': 'cache'
            })

        # Fall back to live Wiki.js search
        client = WikiJSClient()
        search_results = client.search_pages(query)

        return jsonify({
            'results': [
                {
                    'page_id': r['id'],
                    'title': r['title'],
                    'path': r['path'],
                    'excerpt': r.get('description', '')
                }
                for r in search_results
            ],
            'source': 'live'
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/invalidate-cache', methods=['POST'])
def invalidate_cache():
    """Invalidate entire cache or specific page"""
    try:
        page_id = request.json.get('page_id') if request.json else None

        with get_db_connection() as conn:
            with conn.cursor() as cursor:
                if page_id:
                    cursor.execute("DELETE FROM chatbot_wikijs_cache WHERE page_id = %s", (page_id,))
                else:
                    cursor.execute("DELETE FROM chatbot_wikijs_cache")

                conn.commit()
                deleted = cursor.rowcount

        return jsonify({'status': 'success', 'pages_invalidated': deleted})

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ============================================================================
# Main
# ============================================================================

if __name__ == '__main__':
    port = int(os.getenv('WIKIJS_CONNECTOR_PORT', 5002))
    app.run(host='0.0.0.0', port=port, debug=False)
