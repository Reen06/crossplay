#!/bin/bash
# Crossplay launch script for Linux/macOS
# Loads configuration and starts Docker Compose services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source host detection
source "$PROJECT_ROOT/tools/detect_host.sh"

echo "=== Crossplay Launch ==="
echo "Profile: $CROSSPLAY_PROFILE"
echo ""

# Check Docker availability
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed or not in PATH"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running"
    exit 1
fi

# Load .env file
if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
else
    echo "WARNING: .env file not found. Using defaults."
fi

# Load config
CONFIG_FILE="$PROJECT_ROOT/config/crossplay.config.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    echo "Please run ./scripts/setup.sh first"
    exit 1
fi

# Build compose file list
COMPOSE_FILES=("-f" "$PROJECT_ROOT/compose.yaml")

# Add platform-specific compose file based on profile
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
    linux-amd64-cpu)
        # Base compose only
        ;;
    *)
        echo "WARNING: Unknown profile $CROSSPLAY_PROFILE, using base compose only"
        ;;
esac

# Add feature profile files based on enabled repos
# Simple YAML parsing to check enabled repos
if grep -q "enabled: true" "$CONFIG_FILE" 2>/dev/null; then
    if grep -A 3 "video:" "$CONFIG_FILE" | grep -q "enabled: true"; then
        COMPOSE_FILES+=("-f" "$PROJECT_ROOT/profiles/video.yaml")
        echo "  + Video service enabled"
    fi
    
    if grep -A 3 "ros2:" "$CONFIG_FILE" | grep -q "enabled: true"; then
        COMPOSE_FILES+=("-f" "$PROJECT_ROOT/profiles/ros2.yaml")
        echo "  + ROS2 service enabled"
    fi
    
    if grep -A 3 "nlp:" "$CONFIG_FILE" | grep -q "enabled: true"; then
        COMPOSE_FILES+=("-f" "$PROJECT_ROOT/profiles/nlp.yaml")
        echo "  + NLP service enabled"
    fi
fi

echo ""
echo "Starting services with compose files:"
for file in "${COMPOSE_FILES[@]}"; do
    if [[ "$file" != "-f" ]]; then
        echo "  - $file"
    fi
done
echo ""

# Set COMPOSE_PROFILES environment variable
export COMPOSE_PROFILES="$CROSSPLAY_PROFILE"

# Launch services
cd "$PROJECT_ROOT"
docker compose "${COMPOSE_FILES[@]}" up -d

echo ""
echo "=== Services Started ==="
echo ""

# Show service status
docker compose "${COMPOSE_FILES[@]}" ps

echo ""
echo "To view logs:"
echo "  docker compose ${COMPOSE_FILES[*]} logs -f"
echo ""
echo "To stop services:"
echo "  ./scripts/down.sh"
echo ""

