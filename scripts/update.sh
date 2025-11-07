#!/bin/bash
# Update script for crossplay
# Pulls latest images and optionally rebuilds

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source host detection
source "$PROJECT_ROOT/tools/detect_host.sh"

echo "=== Crossplay Update ==="
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    exit 1
fi

# Load .env
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# Build compose file list (same as launch script)
COMPOSE_FILES=("-f" "$PROJECT_ROOT/compose.yaml")

case "$CROSSPLAY_PROFILE" in
    windows-nvidia)
        COMPOSE_FILES+=("-f" "$PROJECT_ROOT/compose.win.yaml")
        ;;
    linux-amd64-nvidia)
        COMPOSE_FILES+=("-f" "$PROJECT_ROOT/compose.linux-amd64.yaml")
        ;;
    jetson)
        COMPOSE_FILES+=("-f" "$PROJECT_ROOT/compose.jetson.yaml")
        ;;
    arm64)
        COMPOSE_FILES+=("-f" "$PROJECT_ROOT/compose.arm64.yaml")
        ;;
esac

# Add feature profiles
CONFIG_FILE="$PROJECT_ROOT/config/crossplay.config.yaml"
if [ -f "$CONFIG_FILE" ]; then
    if grep -A 3 "video:" "$CONFIG_FILE" | grep -q "enabled: true"; then
        COMPOSE_FILES+=("-f" "$PROJECT_ROOT/profiles/video.yaml")
    fi
    if grep -A 3 "ros2:" "$CONFIG_FILE" | grep -q "enabled: true"; then
        COMPOSE_FILES+=("-f" "$PROJECT_ROOT/profiles/ros2.yaml")
    fi
    if grep -A 3 "nlp:" "$CONFIG_FILE" | grep -q "enabled: true"; then
        COMPOSE_FILES+=("-f" "$PROJECT_ROOT/profiles/nlp.yaml")
    fi
fi

cd "$PROJECT_ROOT"

# Pull latest images
echo "Pulling latest images..."
docker compose "${COMPOSE_FILES[@]}" pull

# Ask about rebuild
read -p "Rebuild images? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebuilding images..."
    docker compose "${COMPOSE_FILES[@]}" build --pull
fi

# Restart services
echo "Restarting services..."
docker compose "${COMPOSE_FILES[@]}" up -d

echo ""
echo "=== Update Complete ==="
docker compose "${COMPOSE_FILES[@]}" ps

