#!/bin/bash

################################################################################
# Quick Deploy Script - Run this on your Linux VPS
# This will clone the repo and start the installation
################################################################################

set -e

echo "Campaign Stack - Quick Deploy"
echo "=============================="
echo ""

# Navigate to /srv directory
cd /srv

# Clone the repository
echo "Cloning repository from GitHub..."
git clone https://github.com/mkld0910/campaign-stack.git

# Navigate into the repo
cd campaign-stack

echo ""
echo "Repository cloned successfully!"
echo "Current directory: $(pwd)"
echo ""
echo "To start installation, run:"
echo "  bash install-campaign-stack.sh"
echo ""
