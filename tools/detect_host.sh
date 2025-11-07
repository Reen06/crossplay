#!/bin/bash
# Host detection script for crossplay
# Detects OS, architecture, GPU, and special hardware (Jetson, Raspberry Pi)

set -e

# Initialize variables
OS=""
ARCH=""
HAS_GPU=false
IS_JETSON=false
IS_RASPBERRY_PI=false
CROSSPLAY_PROFILE=""

# Detect OS
case "$(uname -s)" in
    Linux*)
        OS="linux"
        ;;
    Darwin*)
        OS="darwin"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        OS="windows"
        ;;
    *)
        OS="unknown"
        ;;
esac

# Detect Architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64|amd64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    armv7l|armv6l)
        ARCH="arm"
        ;;
    *)
        ARCH="unknown"
        ;;
esac

# Detect NVIDIA GPU
if command -v nvidia-smi &> /dev/null; then
    if nvidia-smi &> /dev/null; then
        HAS_GPU=true
    fi
fi

# Detect Jetson
if [ -f /etc/nv_tegra_release ] || [ -f /proc/device-tree/model ] && grep -q "jetson\|tegra" /proc/device-tree/model 2>/dev/null; then
    IS_JETSON=true
fi

# Detect Raspberry Pi
if [ -f /proc/cpuinfo ] && grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    IS_RASPBERRY_PI=true
elif [ -f /proc/device-tree/model ] && grep -qi "raspberry" /proc/device-tree/model 2>/dev/null; then
    IS_RASPBERRY_PI=true
fi

# Determine CROSSPLAY_PROFILE
if [ "$IS_JETSON" = true ]; then
    CROSSPLAY_PROFILE="jetson"
elif [ "$IS_RASPBERRY_PI" = true ] || ([ "$OS" = "linux" ] && [ "$ARCH" = "arm64" ]); then
    CROSSPLAY_PROFILE="arm64"
elif [ "$OS" = "windows" ] && [ "$HAS_GPU" = true ]; then
    CROSSPLAY_PROFILE="windows-nvidia"
elif [ "$OS" = "linux" ] && [ "$ARCH" = "amd64" ] && [ "$HAS_GPU" = true ]; then
    CROSSPLAY_PROFILE="linux-amd64-nvidia"
elif [ "$OS" = "linux" ] && [ "$ARCH" = "amd64" ]; then
    CROSSPLAY_PROFILE="linux-amd64-cpu"
else
    CROSSPLAY_PROFILE="linux-amd64-cpu"  # Default fallback
fi

# Export variables
export OS
export ARCH
export HAS_GPU
export IS_JETSON
export IS_RASPBERRY_PI
export CROSSPLAY_PROFILE

# Print detection results (if not sourced)
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "Host Detection Results:"
    echo "  OS: $OS"
    echo "  Architecture: $ARCH"
    echo "  Has GPU: $HAS_GPU"
    echo "  Is Jetson: $IS_JETSON"
    echo "  Is Raspberry Pi: $IS_RASPBERRY_PI"
    echo "  Profile: $CROSSPLAY_PROFILE"
fi

