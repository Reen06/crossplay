# Crossplay launch script for Windows PowerShell
# Loads configuration and starts Docker Compose services

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# Source host detection
. "$ProjectRoot\tools\detect_host.ps1"

Write-Host "=== Crossplay Launch ===" -ForegroundColor Cyan
Write-Host "Profile: $CROSSPLAY_PROFILE"
Write-Host ""

# Check Docker availability
try {
    docker info | Out-Null
} catch {
    Write-Host "ERROR: Docker is not available or not running" -ForegroundColor Red
    exit 1
}

# Load .env file
$EnvFile = Join-Path $ProjectRoot ".env"
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)\s*$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
} else {
    Write-Host "WARNING: .env file not found. Using defaults." -ForegroundColor Yellow
}

# Load config
$ConfigFile = Join-Path $ProjectRoot "config\crossplay.config.yaml"
if (-not (Test-Path $ConfigFile)) {
    Write-Host "ERROR: Configuration file not found: $ConfigFile" -ForegroundColor Red
    Write-Host "Please run .\scripts\setup.ps1 first"
    exit 1
}

# Build compose file list
$ComposeFiles = @("compose.yaml")

# Add platform-specific compose file based on profile
switch ($CROSSPLAY_PROFILE) {
    "windows-nvidia" {
        $ComposeFiles += "compose.win.yaml"
    }
    "linux-amd64-nvidia" {
        $ComposeFiles += "compose.linux-amd64.yaml"
    }
    "jetson" {
        $ComposeFiles += "compose.jetson.yaml"
    }
    "arm64" {
        $ComposeFiles += "compose.arm64.yaml"
    }
    "linux-amd64-cpu" {
        # Base compose only
    }
    default {
        Write-Host "WARNING: Unknown profile $CROSSPLAY_PROFILE, using base compose only" -ForegroundColor Yellow
    }
}

# Add feature profile files based on enabled repos
$ConfigContent = Get-Content $ConfigFile -Raw
if ($ConfigContent -match "enabled:\s*true") {
    if ($ConfigContent -match "video:[\s\S]*?enabled:\s*true") {
        $ComposeFiles += "profiles\video.yaml"
        Write-Host "  + Video service enabled" -ForegroundColor Green
    }
    
    if ($ConfigContent -match "ros2:[\s\S]*?enabled:\s*true") {
        $ComposeFiles += "profiles\ros2.yaml"
        Write-Host "  + ROS2 service enabled" -ForegroundColor Green
    }
    
    if ($ConfigContent -match "nlp:[\s\S]*?enabled:\s*true") {
        $ComposeFiles += "profiles\nlp.yaml"
        Write-Host "  + NLP service enabled" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Starting services with compose files:" -ForegroundColor Cyan
foreach ($file in $ComposeFiles) {
    Write-Host "  - $file"
}
Write-Host ""

# Set COMPOSE_PROFILES environment variable
$env:COMPOSE_PROFILES = $CROSSPLAY_PROFILE

# Build docker compose command
$ComposeArgs = @()
foreach ($file in $ComposeFiles) {
    $ComposeArgs += "-f"
    $ComposeArgs += $file
}
$ComposeArgs += "up"
$ComposeArgs += "-d"

# Launch services
Push-Location $ProjectRoot
try {
    docker compose @ComposeArgs
    
    Write-Host ""
    Write-Host "=== Services Started ===" -ForegroundColor Green
    Write-Host ""
    
    # Show service status
    docker compose @ComposeArgs[0..($ComposeArgs.Length-3)] ps
    
    Write-Host ""
    Write-Host "To view logs:" -ForegroundColor Cyan
    Write-Host "  docker compose $($ComposeArgs[0..($ComposeArgs.Length-3)] -join ' ') logs -f"
    Write-Host ""
    Write-Host "To stop services:" -ForegroundColor Cyan
    Write-Host "  .\scripts\down.ps1"
    Write-Host ""
} finally {
    Pop-Location
}

