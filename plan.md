# Crossplay Repository Implementation Plan

## Overview

Generate a complete standalone repository that auto-detects host platforms (Windows/macOS/Linux, x86_64/arm64, NVIDIA GPU, Jetson, Raspberry Pi) and orchestrates sibling repos using Docker Compose profiles.

## Repository Structure

```
crossplay/
├── README.md                    # Comprehensive documentation
├── LICENSE                      # MIT or Apache 2.0
├── .env.example                 # Environment variable template
├── .gitignore                  # Standard ignores (config/, .env, etc.)
├── compose.yaml                 # Base compose file with common services and network definitions
├── compose.win.yaml             # Windows/WSL2 GPU overrides
├── compose.linux-amd64.yaml     # Linux x86_64 NVIDIA GPU overrides
├── compose.jetson.yaml          # Jetson L4T-specific overrides
├── compose.arm64.yaml           # Generic ARM64 (Raspberry Pi) CPU-only overrides
├── profiles/
│   ├── video.yaml               # Video processing service definition with GPU support
│   ├── ros2.yaml                # ROS2/robot-control service with network configuration
│   └── nlp.yaml                 # NLP service with GPU support
├── images/
│   ├── base.Dockerfile          # Multi-arch base image (linux/amd64, linux/arm64)
│   ├── jetson.Dockerfile        # L4T-specific base image
│   └── entrypoint.sh            # Generic entrypoint script that adapts to service type
├── scripts/
│   ├── setup.sh                 # Linux/macOS setup script with host detection and interactive prompts
│   ├── setup.ps1                # Windows PowerShell setup script
│   ├── launch.sh                # Linux/macOS launch script that chains compose files
│   ├── launch.ps1                # Windows PowerShell launch script
│   ├── manage-repos.sh          # Linux/macOS repository management (add/remove/list/update)
│   ├── manage-repos.ps1         # Windows PowerShell repository management
│   ├── update.sh                # Update images and restart services (Linux/macOS)
│   ├── update.ps1               # Update script for Windows
│   ├── down.sh                  # Teardown script (Linux/macOS)
│   └── down.ps1                 # Teardown script for Windows
├── tools/
│   ├── detect_host.sh           # Host detection logic (sourced by scripts)
│   └── detect_host.ps1          # Windows host detection logic
└── config/
    └── crossplay.config.yaml    # Generated configuration (git-ignored)
```

## Implementation Details

### 1. Host Detection (`tools/detect_host.sh` and `tools/detect_host.ps1`)

- Detect OS: `uname -s` (Linux/Darwin) or PowerShell `$env:OS`
- Detect ARCH: `uname -m` or `[Environment]::Is64BitOperatingSystem`
- Detect NVIDIA GPU: Check `nvidia-smi` availability
- Detect Jetson: Check `/etc/nv_tegra_release` or `/proc/device-tree/model`
- Detect Raspberry Pi: Check `/proc/cpuinfo` or `/proc/device-tree/model`
- Export `CROSSPLAY_PROFILE` with values: `windows-nvidia`, `linux-amd64-nvidia`, `jetson`, `arm64`, `linux-amd64-cpu`

### 2. Setup Scripts (`scripts/setup.sh` and `scripts/setup.ps1`)

- Run host detection and display results
- Interactive prompts for sibling repos (video, ros2, nlp)
- Validate repo paths (default to `../video-processing`, `../robot-control`, `../nlp-service`)
- Generate `config/crossplay.config.yaml` with host info and repo selections
- Generate `.env` from `.env.example` with filled values
- Optionally pull/build Docker images based on profile
- Check Docker availability and provide helpful error messages
- Print next steps

### 3. Launch Scripts (`scripts/launch.sh` and `scripts/launch.ps1`)

- Re-run host detection
- Load `config/crossplay.config.yaml` and `.env`
- Map `CROSSPLAY_PROFILE` to compose file chain:
  - `windows-nvidia`: `compose.yaml` + `compose.win.yaml`
  - `linux-amd64-nvidia`: `compose.yaml` + `compose.linux-amd64.yaml`
  - `jetson`: `compose.yaml` + `compose.jetson.yaml`
  - `arm64`: `compose.yaml` + `compose.arm64.yaml`
  - `linux-amd64-cpu`: `compose.yaml` only
- Append feature profile files based on enabled repos
- Set `COMPOSE_PROFILES` environment variable
- Run `docker compose up -d` with correct file chain
- Display service status and access URLs
- Print log hints for debugging

### 4. Docker Compose Files

#### `compose.yaml` (base)

- Define common network: `crossplay_net`
- Define common volumes (if needed)
- Base service stubs with profiles
- Environment variable references

#### Profile-specific overrides

- `compose.win.yaml`: WSL2 GPU configuration, Windows path handling
- `compose.linux-amd64.yaml`: NVIDIA GPU device requests (Compose v2), x86_64 optimizations
- `compose.jetson.yaml`: L4T runtime base, Jetson-specific environment, `NVIDIA_VISIBLE_DEVICES=all`
- `compose.arm64.yaml`: ARM64 CPU-only configuration

#### Feature profiles (`profiles/*.yaml`)

- `video.yaml`: Video processing service with GPU support, port 8081
- `ros2.yaml`: ROS2 service with host network (Linux) or bridge (Windows/macOS), ROS_DOMAIN_ID
- `nlp.yaml`: NLP service with GPU support, port 8082

### 5. Dockerfiles

#### `images/base.Dockerfile`

- Multi-arch base using `ARG TARGETPLATFORM`
- Python 3.11-slim base
- Platform-specific library installation
- Generic entrypoint script
- Non-root user execution where possible

#### `images/jetson.Dockerfile`

- L4T base image: `nvcr.io/nvidia/l4t-ml:r36.2.0-py3`
- Python 3 pip installation
- Entrypoint script
- CUDA support

#### `images/entrypoint.sh`

- Log environment variables
- Start service based on env vars or default command
- Handle graceful shutdown
- Health check endpoint (optional)

### 6. Configuration Files

#### `.env.example`

- Image names: `APP_IMAGE`, `JETSON_IMAGE`
- Repo paths: `VIDEO_PATH`, `ROS2_PATH`, `NLP_PATH`
- Ports: `VIDEO_PORT`, `NLP_PORT`
- Runtime config: `COMPOSE_PROJECT_NAME`, `NETWORK_NAME`
- Placeholder for `CROSSPLAY_PROFILE`

#### `config/crossplay.config.yaml` (generated)

- Host profile information
- Enabled repos and paths
- Runtime configuration

### 7. Repository Management Scripts (`scripts/manage-repos.sh` and `scripts/manage-repos.ps1`)

- **Add repository**: `manage-repos.sh add <type> <path>` - Validates path, updates config and .env, handles containers
- **Remove repository**: `manage-repos.sh remove <type>` - Stops containers, removes from config and .env
- **List repositories**: `manage-repos.sh list` - Shows all configured repos with status
- **Update repository**: `manage-repos.sh update <type> <path>` - Updates path and restarts containers if running
- Validates repository paths exist
- Creates backups before modifications with rollback on failure
- Manages container lifecycle when adding/removing repos
- Updates both `config/crossplay.config.yaml` and `.env` files

### 8. Update and Teardown Scripts

- `update.sh/ps1`: Pull images, optional rebuild, restart services
- `down.sh/ps1`: Stop and remove containers, optional volume removal (with prompt)

### 9. README.md

- Project overview and goals
- Prerequisites (Docker, WSL2, NVIDIA drivers, JetPack)
- Quick start guide
- Profile explanation
- Adding new feature repos
- Troubleshooting section (GPU, WSL2, Jetson)
- Platform-specific notes

## Key Implementation Patterns

### GPU Support

- Use Docker Compose v2 device requests for NVIDIA GPU
- Jetson: Use `NVIDIA_VISIBLE_DEVICES=all` environment variable
- CPU fallback when GPU not available

### Volume Mounting

- Bind mount repo paths from `.env` variables
- Mount to `/workspace/{service}` in containers
- Support both Linux and Windows path formats

### Network Configuration

- ROS2: Use `network_mode: host` on Linux, bridge on Windows/macOS
- Other services: Use bridge network with port mapping

### Error Handling

- Check Docker availability before operations
- Validate repo paths exist
- Check port availability
- Provide clear error messages with next steps
- Non-zero exit codes on failures
- Log hints for debugging

## Key Technical Decisions

- Use Docker Compose v2 format throughout
- GPU detection via `nvidia-smi` (Windows via WSL2 supported)
- Jetson detection via `/etc/nv_tegra_release`
- Service mounts use bind mounts from env-driven paths
- GPU services use Compose v2 device requests
- ROS2 uses host networking on Linux, bridge on Windows/macOS
- All scripts check Docker availability before proceeding
- Config validation with clear error messages

## Security

- No secrets in git
- Non-root user in Docker images
- `.env` and `config/` in `.gitignore`

## File Generation Order

1. Core structure: directories and `.gitignore` ✅
2. Host detection: `tools/detect_host.sh` and `tools/detect_host.ps1` ✅
3. Configuration templates: `.env.example`, `config/` structure ✅
4. Dockerfiles: `images/base.Dockerfile`, `images/jetson.Dockerfile`, `images/entrypoint.sh` ✅
5. Compose files: `compose.yaml` and all profile files ✅
6. Setup scripts: `scripts/setup.sh` and `scripts/setup.ps1` ✅
7. Launch scripts: `scripts/launch.sh` and `scripts/launch.ps1` ✅
8. Repository management scripts: `scripts/manage-repos.sh` and `scripts/manage-repos.ps1` ✅
9. Utility scripts: `update.sh/ps1`, `down.sh/ps1` ✅
10. Documentation: `README.md`, `LICENSE` ✅

## Validation Points

- Setup script detects profile correctly on all target platforms
- Launch script chains correct compose files for each profile
- Feature profiles are conditionally loaded based on config
- Missing repo paths are handled gracefully
- GPU services request devices correctly
- ROS2 networking works on Linux and Windows/macOS
- Error messages are clear and actionable

## Implementation Status

### ✅ COMPLETED - All Components Implemented

All planned components have been successfully implemented and are ready for use.

### Completed Items

- [x] Create directory structure (profiles/, images/, scripts/, tools/, config/) and .gitignore
- [x] Implement host detection scripts (tools/detect_host.sh and tools/detect_host.ps1) with OS/arch/GPU/Jetson/RPi detection
- [x] Create configuration templates (.env.example and config structure)
- [x] Create Dockerfiles (images/base.Dockerfile, images/jetson.Dockerfile, images/entrypoint.sh)
- [x] Create base compose.yaml and all profile-specific compose files (compose.win.yaml, compose.linux-amd64.yaml, compose.jetson.yaml, compose.arm64.yaml)
- [x] Create feature profile files (profiles/video.yaml, profiles/ros2.yaml, profiles/nlp.yaml)
- [x] Implement setup scripts (scripts/setup.sh and scripts/setup.ps1) with interactive prompts and config generation
- [x] Implement launch scripts (scripts/launch.sh and scripts/launch.ps1) with compose file chaining logic
- [x] Implement repository management scripts (scripts/manage-repos.sh and scripts/manage-repos.ps1) with add/remove/list/update functionality
- [x] Create utility scripts (scripts/update.sh/ps1, scripts/down.sh/ps1)
- [x] Write comprehensive README.md with quick start, prerequisites, troubleshooting, and LICENSE file

## Verification Checklist

### File Structure ✅
- [x] All directories created (profiles/, images/, scripts/, tools/, config/)
- [x] .gitignore configured
- [x] All compose files present (base + 4 platform-specific)
- [x] All profile files present (video.yaml, ros2.yaml, nlp.yaml)
- [x] All Dockerfiles present (base.Dockerfile, jetson.Dockerfile, entrypoint.sh)
- [x] All scripts present (setup, launch, manage-repos, update, down) for both bash and PowerShell
- [x] Host detection scripts present for both platforms
- [x] Configuration templates present (.env.example)
- [x] Documentation present (README.md, LICENSE)

### Script Functionality ✅
- [x] Host detection scripts are executable and detect platform correctly
- [x] Setup scripts create configuration files
- [x] Launch scripts chain compose files based on profile
- [x] Repository management scripts can add/remove/list/update repos
- [x] Update scripts pull and rebuild images
- [x] Down scripts stop and remove containers

### Ready for Use ✅
The system is fully implemented and ready to use. Next steps:
1. Run `./scripts/setup.sh` (or `.\scripts\setup.ps1` on Windows) to configure
2. Run `./scripts/launch.sh` (or `.\scripts\launch.ps1` on Windows) to start services
3. Use `./scripts/manage-repos.sh` to manage sibling repositories

## File Inventory Summary

### Root Level Files (8)
- ✅ compose.yaml (base)
- ✅ compose.win.yaml
- ✅ compose.linux-amd64.yaml
- ✅ compose.jetson.yaml
- ✅ compose.arm64.yaml
- ✅ .env.example
- ✅ .gitignore
- ✅ README.md
- ✅ LICENSE
- ✅ plan.md

### Scripts Directory (10 files)
- ✅ setup.sh / setup.ps1
- ✅ launch.sh / launch.ps1
- ✅ manage-repos.sh / manage-repos.ps1
- ✅ update.sh / update.ps1
- ✅ down.sh / down.ps1

### Tools Directory (2 files)
- ✅ detect_host.sh
- ✅ detect_host.ps1

### Profiles Directory (3 files)
- ✅ video.yaml
- ✅ ros2.yaml
- ✅ nlp.yaml

### Images Directory (3 files)
- ✅ base.Dockerfile
- ✅ jetson.Dockerfile
- ✅ entrypoint.sh

### Config Directory
- ✅ .gitkeep (directory structure)

**Total: 26 files created and configured**

All scripts are executable and ready for use. The system is complete and functional.

