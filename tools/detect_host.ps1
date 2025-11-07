# Host detection script for crossplay (PowerShell)
# Detects OS, architecture, GPU, and special hardware (Jetson, Raspberry Pi)

$ErrorActionPreference = "Stop"

# Initialize variables
$OS = ""
$ARCH = ""
$HAS_GPU = $false
$IS_JETSON = $false
$IS_RASPBERRY_PI = $false
$CROSSPLAY_PROFILE = ""

# Detect OS
if ($IsWindows -or $env:OS -like "*Windows*") {
    $OS = "windows"
} elseif ($IsLinux) {
    $OS = "linux"
} elseif ($IsMacOS) {
    $OS = "darwin"
} else {
    $OS = "unknown"
}

# Detect Architecture
if ([Environment]::Is64BitOperatingSystem) {
    $ARCH = "amd64"
} else {
    $ARCH = "arm"
}

# Check for ARM64 specifically (PowerShell 7+)
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $procArch = (Get-CimInstance Win32_Processor).Architecture
    if ($procArch -eq 12) {  # ARM64
        $ARCH = "arm64"
    }
}

# Detect NVIDIA GPU (via WSL2 or native Windows)
try {
    $nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
    if ($nvidiaSmi) {
        $gpuCheck = & nvidia-smi 2>&1
        if ($LASTEXITCODE -eq 0) {
            $HAS_GPU = $true
        }
    }
} catch {
    # GPU not available
}

# Detect Jetson (only relevant in WSL2 or if running on Jetson hardware)
if (Test-Path "/etc/nv_tegra_release" -ErrorAction SilentlyContinue) {
    $IS_JETSON = $true
} elseif (Test-Path "/proc/device-tree/model" -ErrorAction SilentlyContinue) {
    $model = Get-Content "/proc/device-tree/model" -ErrorAction SilentlyContinue
    if ($model -match "jetson|tegra") {
        $IS_JETSON = $true
    }
}

# Detect Raspberry Pi (only relevant in WSL2 or if running on Pi hardware)
if (Test-Path "/proc/cpuinfo" -ErrorAction SilentlyContinue) {
    $cpuinfo = Get-Content "/proc/cpuinfo" -ErrorAction SilentlyContinue
    if ($cpuinfo -match "Raspberry Pi") {
        $IS_RASPBERRY_PI = $true
    }
} elseif (Test-Path "/proc/device-tree/model" -ErrorAction SilentlyContinue) {
    $model = Get-Content "/proc/device-tree/model" -ErrorAction SilentlyContinue
    if ($model -match "raspberry" -CaseSensitive:$false) {
        $IS_RASPBERRY_PI = $true
    }
}

# Determine CROSSPLAY_PROFILE
if ($IS_JETSON) {
    $CROSSPLAY_PROFILE = "jetson"
} elseif ($IS_RASPBERRY_PI -or ($OS -eq "linux" -and $ARCH -eq "arm64")) {
    $CROSSPLAY_PROFILE = "arm64"
} elseif ($OS -eq "windows" -and $HAS_GPU) {
    $CROSSPLAY_PROFILE = "windows-nvidia"
} elseif ($OS -eq "linux" -and $ARCH -eq "amd64" -and $HAS_GPU) {
    $CROSSPLAY_PROFILE = "linux-amd64-nvidia"
} elseif ($OS -eq "linux" -and $ARCH -eq "amd64") {
    $CROSSPLAY_PROFILE = "linux-amd64-cpu"
} else {
    $CROSSPLAY_PROFILE = "linux-amd64-cpu"  # Default fallback
}

# Export as environment variable
$env:OS = $OS
$env:ARCH = $ARCH
$env:HAS_GPU = $HAS_GPU.ToString().ToLower()
$env:IS_JETSON = $IS_JETSON.ToString().ToLower()
$env:IS_RASPBERRY_PI = $IS_RASPBERRY_PI.ToString().ToLower()
$env:CROSSPLAY_PROFILE = $CROSSPLAY_PROFILE

# Print detection results (if run directly)
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "Host Detection Results:"
    Write-Host "  OS: $OS"
    Write-Host "  Architecture: $ARCH"
    Write-Host "  Has GPU: $HAS_GPU"
    Write-Host "  Is Jetson: $IS_JETSON"
    Write-Host "  Is Raspberry Pi: $IS_RASPBERRY_PI"
    Write-Host "  Profile: $CROSSPLAY_PROFILE"
}

