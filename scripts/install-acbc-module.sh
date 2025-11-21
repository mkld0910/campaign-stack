#!/bin/bash

################################################################################
# Campaign Stack - ACBC Voter Intelligence Module Installer
# Version: 1.0
# Purpose: Install ACBC module for voter analytics and personalization
# Usage: bash scripts/install-acbc-module.sh
################################################################################

set -e

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

# Main Installation
print_header "ACBC Voter Intelligence Module Installer v1.0"
echo "This will install advanced voter analytics and personalization"
echo "Estimated time: 10-15 minutes"
echo ""

# Check if running from correct directory
if [ ! -f "compose.yaml" ]; then
    print_error "Must run from campaign-stack directory"
    echo "   cd /srv/campaign-stack && bash scripts/install-acbc-module.sh"
    exit 1
fi

# Check if base stack is running
if ! docker compose ps | grep -q "wordpress_app.*Up"; then
    print_error "Base Campaign Stack not running"
    echo "   Run: docker compose up -d"
    exit 1
fi

# Prerequisites Check
print_header "Step 1/8: Prerequisites Check"

# Check for compose-acbc.yaml
if [ ! -f "compose-acbc.yaml" ]; then
    print_error "compose-acbc.yaml not found"
    print_info "Pull latest from repository: git pull origin master"
    exit 1
fi
print_success "compose-acbc.yaml found"

# Check for ACBC module directory
if [ ! -d "acbc-module" ]; then
    print_error "acbc-module directory not found"
    print_info "Pull latest from repository: git pull origin master"
    exit 1
fi
print_success "ACBC module directory found"

# Configuration
print_header "Step 2/8: ACBC Module Configuration"

# Check if .env exists
if [ ! -f ".env" ]; then
    print_error ".env file not found"
    echo "   Have you run the main installer?"
    exit 1
fi

# Add ACBC configuration to .env if not present
if ! grep -q "LIMESURVEY_DB_PASSWORD" .env; then
    print_info "Adding ACBC configuration to .env..."

    LIMESURVEY_DB_PASS=$(openssl rand -base64 12)
    ACBC_DB_ROOT_PASS=$(openssl rand -base64 12)
    LIMESURVEY_ADMIN_PASS=$(openssl rand -base64 16)

    cat >> .env << EOF

# ============================================================================
# ACBC MODULE CONFIGURATION
# ============================================================================
# LimeSurvey Database
LIMESURVEY_DB_PASSWORD=${LIMESURVEY_DB_PASS}
ACBC_DB_ROOT_PASSWORD=${ACBC_DB_ROOT_PASS}
LIMESURVEY_ADMIN_PASSWORD=${LIMESURVEY_ADMIN_PASS}

# ACBC Features
ACBC_ENABLED=true
ACBC_AUTO_SEGMENT=true
ACBC_CIVICRM_SYNC=true
EOF

    print_success "ACBC configuration added to .env"

    # Save credentials
    # Determine admin domain for credentials file
    CRED_DOMAIN=$(grep ^BACKEND_DOMAIN .env | cut -d '=' -f2)
    if [ -z "$CRED_DOMAIN" ]; then
        CRED_DOMAIN="$DOMAIN"
    fi

    cat >> CREDENTIALS_BACKUP.txt << EOF

=== ACBC MODULE CREDENTIALS ===
LimeSurvey Admin:
  URL: https://survey.${CRED_DOMAIN}/admin
  Username: admin
  Password: ${LIMESURVEY_ADMIN_PASS}

ACBC Dashboard:
  URL: https://acbc.${CRED_DOMAIN}
  (Uses WordPress/CiviCRM authentication)

Database Passwords:
  LimeSurvey DB: ${LIMESURVEY_DB_PASS}
  ACBC Root DB: ${ACBC_DB_ROOT_PASS}

SAVE THESE CREDENTIALS SECURELY!
EOF

    print_warning "Credentials saved to CREDENTIALS_BACKUP.txt"
else
    print_info "ACBC configuration already exists in .env"
fi

# Build Analytics Engine
print_header "Step 3/8: Building Analytics Engine"

if [ ! -f "acbc-module/analytics-engine/Dockerfile" ]; then
    print_info "Creating Analytics Engine Dockerfile..."
    mkdir -p acbc-module/analytics-engine

    cat > acbc-module/analytics-engine/Dockerfile << 'DOCKER_EOF'
FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
DOCKER_EOF

    # Create requirements.txt
    cat > acbc-module/analytics-engine/requirements.txt << 'REQ_EOF'
flask==3.0.0
flask-cors==4.0.0
pymysql==1.1.0
pandas==2.1.4
numpy==1.26.2
scikit-learn==1.3.2
cryptography==41.0.7
python-dotenv==1.0.0
REQ_EOF

    # Create basic app.py
    cat > acbc-module/analytics-engine/app.py << 'APP_EOF'
from flask import Flask, jsonify, request
from flask_cors import CORS
import os

app = Flask(__name__)
CORS(app)

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'service': 'ACBC Analytics Engine'})

@app.route('/api/utilities/calculate', methods=['POST'])
def calculate_utilities():
    data = request.json
    # Placeholder for utility calculation logic
    return jsonify({'status': 'calculated', 'data': data})

@app.route('/api/segments/update', methods=['POST'])
def update_segments():
    # Placeholder for segment update logic
    return jsonify({'status': 'updated'})

if __name__ == '__main__':
    port = int(os.environ.get('API_PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
APP_EOF

    print_success "Analytics Engine created"
fi

# Build Dashboard
print_header "Step 4/8: Building Admin Dashboard"

if [ ! -f "acbc-module/admin-dashboard/Dockerfile" ]; then
    print_info "Creating Admin Dashboard..."
    mkdir -p acbc-module/admin-dashboard/public

    cat > acbc-module/admin-dashboard/Dockerfile << 'DASH_EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3001

CMD ["npm", "start"]
DASH_EOF

    cat > acbc-module/admin-dashboard/package.json << 'PKG_EOF'
{
  "name": "acbc-dashboard",
  "version": "1.0.0",
  "description": "ACBC Module Admin Dashboard",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "axios": "^1.6.2"
  }
}
PKG_EOF

    cat > acbc-module/admin-dashboard/server.js << 'SRV_EOF'
const express = require('express');
const axios = require('axios');
const path = require('path');

const app = express();
const port = process.env.DASHBOARD_PORT || 3001;

app.use(express.json());
app.use(express.static('public'));

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'ACBC Dashboard' });
});

app.listen(port, '0.0.0.0', () => {
    console.log(`ACBC Dashboard running on port ${port}`);
});
SRV_EOF

    cat > acbc-module/admin-dashboard/public/index.html << 'HTML_EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ACBC Voter Intelligence Dashboard</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; }
        h1 { color: #333; }
        .status { padding: 20px; background: #e8f5e9; border-radius: 4px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎯 ACBC Voter Intelligence Dashboard</h1>
        <div class="status">
            <h2>✓ System Active</h2>
            <p>ACBC module is installed and running.</p>
            <p><strong>Next Steps:</strong></p>
            <ul>
                <li>Access LimeSurvey: <a href="/admin" target="_blank">Survey Admin</a></li>
                <li>Configure CiviCRM integration</li>
                <li>Create ACBC surveys</li>
                <li>View segment analytics</li>
            </ul>
        </div>
    </div>
</body>
</html>
HTML_EOF

    print_success "Admin Dashboard created"
fi

# Deploy ACBC Services
print_header "Step 5/8: Deploying ACBC Services"

print_info "Pulling Docker images (this may take a few minutes)..."
docker compose -f compose.yaml -f compose-acbc.yaml pull

print_info "Starting ACBC services..."
docker compose -f compose.yaml -f compose-acbc.yaml up -d

print_info "Waiting for services to initialize..."
sleep 30

# Verify Deployment
print_header "Step 6/8: Verifying ACBC Deployment"

if docker compose -f compose.yaml -f compose-acbc.yaml ps | grep -q "limesurvey.*Up"; then
    print_success "LimeSurvey running"
else
    print_warning "LimeSurvey may still be starting"
fi

if docker compose -f compose.yaml -f compose-acbc.yaml ps | grep -q "acbc_analytics.*Up"; then
    print_success "Analytics Engine running"
else
    print_warning "Analytics Engine may still be starting"
fi

if docker compose -f compose.yaml -f compose-acbc.yaml ps | grep -q "acbc_dashboard.*Up"; then
    print_success "Admin Dashboard running"
else
    print_warning "Admin Dashboard may still be starting"
fi

# CiviCRM Integration
print_header "Step 7/8: CiviCRM Integration Setup"

print_info "Creating CiviCRM custom fields for ACBC data..."
print_warning "Manual step required: Configure CiviCRM custom fields"
print_info "See: acbc-module/docs/CIVICRM_INTEGRATION.md"

# Final Instructions
print_header "Step 8/8: Installation Complete!"

DOMAIN=$(grep ^DOMAIN .env | cut -d '=' -f2 || echo "yourdomain.com")
BACKEND_DOMAIN=$(grep ^BACKEND_DOMAIN .env | cut -d '=' -f2)

# Use BACKEND_DOMAIN for admin interfaces if configured, otherwise fall back to DOMAIN
if [ -n "$BACKEND_DOMAIN" ]; then
    ADMIN_DOMAIN="$BACKEND_DOMAIN"
    print_info "Dual domain configuration detected: Admin on ${BACKEND_DOMAIN}"
else
    ADMIN_DOMAIN="$DOMAIN"
    print_info "Single domain configuration: All services on ${DOMAIN}"
fi

echo -e "${GREEN}ACBC Voter Intelligence Module is now installed!${NC}"
echo ""
echo -e "${GREEN}Access Points:${NC}"
echo "  LimeSurvey Admin: https://survey.${ADMIN_DOMAIN}/admin"
echo "  ACBC Dashboard: https://acbc.${ADMIN_DOMAIN}"
echo "  Analytics API: https://acbc-api.${ADMIN_DOMAIN}"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Log into LimeSurvey admin (credentials in CREDENTIALS_BACKUP.txt)"
echo "  2. Install ACBC plugin for LimeSurvey"
echo "  3. Create your first ACBC survey"
echo "  4. Configure CiviCRM custom fields"
echo "  5. Test the complete workflow"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "  Setup Guide: acbc-module/docs/SETUP.md"
echo "  CiviCRM Integration: acbc-module/docs/CIVICRM_INTEGRATION.md"
echo "  API Reference: acbc-module/docs/API.md"
echo ""
echo -e "${YELLOW}IMPORTANT:${NC}"
echo "  ✓ Save CREDENTIALS_BACKUP.txt to password manager"
echo "  ✓ Delete file after saving: rm CREDENTIALS_BACKUP.txt"
echo "  ✓ Configure voter file integration"
echo "  ✓ Test with sample surveys before going live"
echo ""

print_success "ACBC Module installation completed successfully!"
