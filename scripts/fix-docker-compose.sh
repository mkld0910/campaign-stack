#!/bin/bash
set -e

# Platform Detection
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    echo "Error: This script must run on Linux (Ubuntu/Debian/RHEL/CentOS)"
    echo "Please run this on your VPS or use WSL on Windows"
    exit 1
fi

echo "==================================="
echo "  Docker Compose Fix Script"
echo "==================================="

# Check if docker compose (V2) works
if docker compose version &>/dev/null; then
    echo "✓ Docker Compose V2 is already installed"

    # Create symlink so 'docker-compose' calls 'docker compose'
    echo "Creating docker-compose wrapper..."

    cat > /usr/local/bin/docker-compose << 'EOF'
#!/bin/bash
docker compose "$@"
EOF

    chmod +x /usr/local/bin/docker-compose

    echo "✓ docker-compose wrapper created"
    docker-compose version

else
    # Install Docker Compose V2 plugin
    echo "Installing Docker Compose V2..."

    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)

    # Install as Docker CLI plugin
    mkdir -p ~/.docker/cli-plugins/
    curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
        -o ~/.docker/cli-plugins/docker-compose

    chmod +x ~/.docker/cli-plugins/docker-compose

    echo "✓ Docker Compose ${COMPOSE_VERSION} installed"
    docker compose version
fi

echo ""
echo "✓ Fix complete! You can now re-run the installer."
echo ""
echo "Run this command to continue installation:"

# Get current directory dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "  cd $REPO_DIR && bash install-campaign-stack.sh"
