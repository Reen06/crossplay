# Crossplay

A multi-platform Docker Compose orchestration system that auto-detects host platforms and manages sibling repositories for video processing, ROS2, NLP, and other services.

## Overview

Crossplay automatically detects your host platform (Windows/macOS/Linux, x86_64/arm64, NVIDIA GPU, Jetson, Raspberry Pi) and orchestrates multiple sibling repositories using Docker Compose profiles. It provides a unified interface for managing and deploying services across different hardware configurations.

## Features

- **Automatic Host Detection**: Detects OS, architecture, GPU, and special hardware (Jetson, Raspberry Pi)
- **Multi-Platform Support**: Works on Windows (WSL2), macOS, Linux (x86_64/arm64)
- **GPU Support**: Automatic NVIDIA GPU detection and configuration
- **Jetson Support**: Specialized support for NVIDIA Jetson devices with L4T runtime
- **Repository Management**: Add, remove, list, and update sibling repositories dynamically
- **Profile-Based Configuration**: Platform-specific and service-specific compose files
- **Easy Setup**: Interactive setup script guides you through configuration

## Prerequisites

### All Platforms
- Docker Engine 20.10+ or Docker Desktop
- Docker Compose v2

### Windows
- Windows 10/11 with WSL2
- Docker Desktop for Windows
- NVIDIA drivers (for GPU support)

### Linux
- Docker and Docker Compose installed
- NVIDIA drivers and nvidia-container-toolkit (for GPU support)

### Jetson
- JetPack 5.0+ installed
- Docker and Docker Compose installed
- NVIDIA L4T runtime

### macOS
- Docker Desktop for Mac
- Note: No GPU support on macOS

## Quick Start

### 1. Initial Setup

Run the setup script to configure crossplay:

**Linux/macOS:**
```bash
./scripts/setup.sh
```

**Windows:**
```powershell
.\scripts\setup.ps1
```

The setup script will:
- Detect your host platform
- Prompt for sibling repository paths
- Generate configuration files
- Create `.env` file from template

### 2. Launch Services

Start all configured services:

**Linux/macOS:**
```bash
./scripts/launch.sh
```

**Windows:**
```powershell
.\scripts\launch.ps1
```

### 3. Manage Repositories

Add a new repository:
```bash
./scripts/manage-repos.sh add video /path/to/video-processing
```

List all repositories:
```bash
./scripts/manage-repos.sh list
```

Remove a repository:
```bash
./scripts/manage-repos.sh remove video
```

Update a repository path:
```bash
./scripts/manage-repos.sh update video /new/path/to/video-processing
```

## Repository Structure

```
crossplay/
├── README.md                    # This file
├── LICENSE                       # MIT License
├── .env.example                  # Environment variable template
├── compose.yaml                  # Base compose file
├── compose.*.yaml                # Platform-specific overrides
├── profiles/                     # Service profile definitions
│   ├── video.yaml               # Video processing service
│   ├── ros2.yaml                # ROS2/robot-control service
│   └── nlp.yaml                 # NLP service
├── images/                       # Dockerfiles
│   ├── base.Dockerfile          # Multi-arch base image
│   ├── jetson.Dockerfile        # Jetson-specific image
│   └── entrypoint.sh            # Generic entrypoint
├── scripts/                      # Management scripts
│   ├── setup.sh/ps1             # Initial setup
│   ├── launch.sh/ps1            # Start services
│   ├── manage-repos.sh/ps1      # Repository management
│   ├── update.sh/ps1            # Update images
│   └── down.sh/ps1               # Stop services
├── tools/                        # Utility scripts
│   ├── detect_host.sh           # Host detection (bash)
│   └── detect_host.ps1          # Host detection (PowerShell)
└── config/                       # Generated configuration
    └── crossplay.config.yaml    # Runtime configuration
```

## Profiles

Crossplay uses profiles to determine which compose files to use:

- `windows-nvidia`: Windows/WSL2 with NVIDIA GPU
- `linux-amd64-nvidia`: Linux x86_64 with NVIDIA GPU
- `jetson`: NVIDIA Jetson devices
- `arm64`: Generic ARM64 (Raspberry Pi, etc.)
- `linux-amd64-cpu`: Linux x86_64 CPU-only

## Adding New Feature Repositories

### Method 1: During Setup

The setup script will prompt you for repository paths during initial configuration.

### Method 2: Using manage-repos Script

```bash
./scripts/manage-repos.sh add <type> <path>
```

Example:
```bash
./scripts/manage-repos.sh add video ../video-processing
```

### Method 3: Manual Configuration

1. Edit `config/crossplay.config.yaml`:
```yaml
repositories:
  my-service:
    enabled: true
    path: /absolute/path/to/repo
    type: my-service
```

2. Add environment variable to `.env`:
```
MY_SERVICE_PATH=/absolute/path/to/repo
```

3. Create a profile file in `profiles/my-service.yaml` (optional, if you need custom compose configuration)

## Configuration Files

### `.env`

Environment variables for Docker Compose. Copy from `.env.example` and customize:
- `COMPOSE_PROJECT_NAME`: Docker Compose project name
- `NETWORK_NAME`: Docker network name
- `CROSSPLAY_PROFILE`: Auto-detected, but can be overridden
- `*_PATH`: Repository paths
- `*_PORT`: Service ports

### `config/crossplay.config.yaml`

Runtime configuration generated by setup script:
- Host detection results
- Enabled repositories and paths
- Service configuration

## Troubleshooting

### GPU Not Detected

**Linux:**
- Ensure NVIDIA drivers are installed: `nvidia-smi`
- Install nvidia-container-toolkit:
  ```bash
  sudo apt-get install nvidia-container-toolkit
  sudo systemctl restart docker
  ```

**Windows/WSL2:**
- Ensure WSL2 is updated: `wsl --update`
- Install NVIDIA drivers for WSL2
- Verify: `nvidia-smi` in WSL2

### Docker Not Running

**Linux:**
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

**Windows:**
- Start Docker Desktop
- Ensure WSL2 integration is enabled in Docker Desktop settings

### Jetson Issues

- Ensure JetPack is installed and up to date
- Verify L4T runtime: `cat /etc/nv_tegra_release`
- Check Docker version compatibility with L4T

### Port Conflicts

If a port is already in use:
1. Check what's using it: `lsof -i :8081` (Linux/macOS) or `netstat -ano | findstr :8081` (Windows)
2. Update port in `.env` file
3. Restart services: `./scripts/launch.sh`

### Repository Path Issues

- Use absolute paths or paths relative to the crossplay directory
- Ensure repository directories exist and are accessible
- Check permissions on repository directories

## Commands Reference

### Setup
```bash
./scripts/setup.sh          # Initial setup (Linux/macOS)
.\scripts\setup.ps1          # Initial setup (Windows)
```

### Launch
```bash
./scripts/launch.sh          # Start services (Linux/macOS)
.\scripts\launch.ps1         # Start services (Windows)
```

### Repository Management
```bash
./scripts/manage-repos.sh add <type> <path>      # Add repository
./scripts/manage-repos.sh remove <type>          # Remove repository
./scripts/manage-repos.sh list                   # List repositories
./scripts/manage-repos.sh update <type> <path>   # Update repository path
```

### Update
```bash
./scripts/update.sh          # Pull and update images (Linux/macOS)
.\scripts\update.ps1         # Pull and update images (Windows)
```

### Teardown
```bash
./scripts/down.sh            # Stop services (Linux/macOS)
.\scripts\down.ps1            # Stop services (Windows)
```

## Platform-Specific Notes

### Windows/WSL2
- GPU support requires NVIDIA drivers for WSL2
- Use forward slashes in paths or let scripts handle conversion
- Docker Desktop must have WSL2 backend enabled

### macOS
- No GPU support (CPU-only)
- Use Docker Desktop for Mac
- Paths use forward slashes

### Jetson
- Uses L4T ML runtime base images
- GPU support via `NVIDIA_VISIBLE_DEVICES=all`
- Optimized for ARM64 architecture

### Raspberry Pi
- CPU-only operation
- ARM64 architecture
- May have slower performance for GPU-intensive tasks

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on multiple platforms if possible
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For issues, questions, or contributions, please open an issue on the repository.

