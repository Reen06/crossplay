# Teardown script for crossplay (PowerShell)
# Stops and removes containers

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

. "$ProjectRoot\tools\detect_host.ps1"

Write-Host "=== Crossplay Teardown ===" -ForegroundColor Cyan
Write-Host ""

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
    # Ask about volumes
    $RemoveVolumes = Read-Host "Remove volumes? [y/N]"
    $VolumeFlag = ""
    if ($RemoveVolumes -match "^[Yy]$") {
        $VolumeFlag = "-v"
        Write-Host "Volumes will be removed" -ForegroundColor Yellow
    }
    
    # Stop and remove
    Write-Host "Stopping and removing containers..." -ForegroundColor Cyan
    $DownArgs = $ComposeArgs + @("down")
    if ($VolumeFlag) {
        $DownArgs += $VolumeFlag
    }
    docker compose @DownArgs
    
    Write-Host ""
    Write-Host "=== Teardown Complete ===" -ForegroundColor Green
} finally {
    Pop-Location
}

