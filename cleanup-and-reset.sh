#!/bin/bash

################################################################################
# Campaign Stack - Fast Cleanup & Reset
# Purpose: Clean up failed installations without wiping the entire VPS
# Usage: bash cleanup-and-reset.sh
#
# This script will:
# - Stop all Docker containers
# - Remove all containers, images, volumes, networks
# - Delete the campaign-stack directory
# - Clean up Docker system
#
# This is 100x faster than reinstalling Ubuntu!
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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_header "Campaign Stack - Fast Cleanup & Reset"

echo "This will remove ALL Docker containers, images, volumes, and networks"
echo "The campaign-stack directory will also be deleted from /srv"
echo ""
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    print_info "Cleanup cancelled"
    exit 0
fi

print_header "Step 1/5: Stopping All Docker Containers"

# Stop all running containers
if [ "$(docker ps -q)" ]; then
    print_info "Stopping running containers..."
    docker stop $(docker ps -q) 2>/dev/null || true
    print_success "All containers stopped"
else
    print_info "No running containers to stop"
fi

print_header "Step 2/5: Removing All Docker Containers"

# Remove all containers (running and stopped)
if [ "$(docker ps -aq)" ]; then
    print_info "Removing all containers..."
    docker rm -f $(docker ps -aq) 2>/dev/null || true
    print_success "All containers removed"
else
    print_info "No containers to remove"
fi

print_header "Step 3/5: Removing All Docker Images"

# Remove all images
if [ "$(docker images -q)" ]; then
    print_info "Removing all Docker images..."
    docker rmi -f $(docker images -q) 2>/dev/null || true
    print_success "All images removed"
else
    print_info "No images to remove"
fi

print_header "Step 4/5: Removing All Docker Volumes & Networks"

# Remove all volumes
print_info "Removing all volumes..."
docker volume prune -f 2>/dev/null || true
print_success "All volumes removed"

# Remove all networks (except default ones)
print_info "Removing all custom networks..."
docker network prune -f 2>/dev/null || true
print_success "All custom networks removed"

# Full Docker system prune
print_info "Running full Docker system prune..."
docker system prune -af --volumes 2>/dev/null || true
print_success "Docker system cleaned"

print_header "Step 5/5: Removing Campaign Stack Directory"

# Remove the campaign-stack directory if it exists
if [ -d "/srv/campaign-stack" ]; then
    print_info "Removing /srv/campaign-stack directory..."
    rm -rf /srv/campaign-stack
    print_success "Directory removed"
else
    print_info "Directory /srv/campaign-stack does not exist"
fi

# Also check current directory
if [ -d "$(pwd)" ] && [[ "$(pwd)" == *"campaign-stack"* ]]; then
    print_warning "You are currently in a campaign-stack directory"
    print_info "Consider running: cd /srv && rm -rf campaign-stack"
fi

print_header "Cleanup Complete!"

echo ""
echo -e "${GREEN}Your VPS is now clean and ready for a fresh installation${NC}"
echo ""
echo "Docker status:"
docker ps -a
echo ""
echo "Docker images:"
docker images
echo ""
echo "Docker volumes:"
docker volume ls
echo ""
echo -e "${BLUE}To reinstall:${NC}"
echo "  cd /srv"
echo "  git clone https://github.com/mkld0910/campaign-stack.git"
echo "  cd campaign-stack"
echo "  bash install-campaign-stack.sh"
echo ""
print_success "Ready for fresh installation!"
