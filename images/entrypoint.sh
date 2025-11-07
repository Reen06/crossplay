#!/bin/bash
# Generic entrypoint script for crossplay services
# Logs environment and starts the service command

set -e

# Log environment information
echo "=== Crossplay Service Starting ==="
echo "Host: $(hostname)"
echo "User: $(whoami)"
echo "Working Directory: $(pwd)"
echo "Python Version: $(python3 --version 2>&1 || echo 'N/A')"

# Log environment variables (filter sensitive ones)
echo "Environment Variables:"
env | grep -E "^(CROSSPLAY|VIDEO|ROS|NLP|COMPOSE)" | sort || true

# Check for GPU
if command -v nvidia-smi &> /dev/null; then
    echo "GPU Information:"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader || true
fi

echo "================================"

# Execute the command passed as arguments
# If no command is provided, use the default CMD
if [ $# -eq 0 ]; then
    echo "No command provided, using default"
    exec python3 -m http.server 8000
else
    echo "Executing: $@"
    exec "$@"
fi

