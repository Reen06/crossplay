# Update script for crossplay (PowerShell)
# Pulls latest images and optionally rebuilds

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

. "$ProjectRoot\tools\detect_host.ps1"

Write-Host "=== Crossplay Update ===" -ForegroundColor Cyan
Write-Host ""

# Check Docker
try {
    docker info | Out-Null
} catch {
    Write-Host "ERROR: Docker is not available" -ForegroundColor Red
    exit 1
}

# Load .env
$EnvFile = Join-Path $ProjectRoot ".env"
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)\s*$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
}

# Build compose file list
$ComposeFiles = @("compose.yaml")

switch ($CROSSPLAY_PROFILE) {
    "windows-nvidia" { $ComposeFiles += "compose.win.yaml" }
    "linux-amd64-nvidia" { $ComposeFiles += "compose.linux-amd64.yaml" }
    "jetson" { $ComposeFiles += "compose.jetson.yaml" }
    "arm64" { $ComposeFiles += "compose.arm64.yaml" }
}

$ConfigFile = Join-Path $ProjectRoot "config\crossplay.config.yaml"
if (Test-Path $ConfigFile) {
    $ConfigContent = Get-Content $ConfigFile -Raw
    if ($ConfigContent -match "video:[\s\S]*?enabled:\s*true") {
        $ComposeFiles += "profiles\video.yaml"
    }
    if ($ConfigContent -match "ros2:[\s\S]*?enabled:\s*true") {
        $ComposeFiles += "profiles\ros2.yaml"
    }
    if ($ConfigContent -match "nlp:[\s\S]*?enabled:\s*true") {
        $ComposeFiles += "profiles\nlp.yaml"
    }
}

$ComposeArgs = @()
foreach ($file in $ComposeFiles) {
    $ComposeArgs += "-f"
    $ComposeArgs += $file
}

Push-Location $ProjectRoot
try {
    # Pull latest images
    Write-Host "Pulling latest images..." -ForegroundColor Cyan
    docker compose @ComposeArgs pull
    
    # Ask about rebuild
    $Rebuild = Read-Host "Rebuild images? [y/N]"
    if ($Rebuild -match "^[Yy]$") {
        Write-Host "Rebuilding images..." -ForegroundColor Cyan
        docker compose @ComposeArgs build --pull
    }
    
    # Restart services
    Write-Host "Restarting services..." -ForegroundColor Cyan
    $UpArgs = $ComposeArgs + @("up", "-d")
    docker compose @UpArgs
    
    Write-Host ""
    Write-Host "=== Update Complete ===" -ForegroundColor Green
    docker compose @ComposeArgs ps
} finally {
    Pop-Location
}

