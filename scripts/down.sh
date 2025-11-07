#!/bin/bash
# Teardown script for crossplay
# Stops and removes containers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source host detection
source "$PROJECT_ROOT/tools/detect_host.sh"

echo "=== Crossplay Teardown ==="
echo ""

# Load .env
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# Build compose file list
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

# Ask about volumes
read -p "Remove volumes? [y/N]: " -n 1 -r
echo
VOLUME_FLAG=""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    VOLUME_FLAG="-v"
    echo "Volumes will be removed"
fi

# Stop and remove
echo "Stopping and removing containers..."
docker compose "${COMPOSE_FILES[@]}" down $VOLUME_FLAG

echo ""
echo "=== Teardown Complete ==="

