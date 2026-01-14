$ErrorActionPreference = "Stop"

$GitHubApi = "https://api.github.com/repos/inkandswitch/patchwork-godot-plugin/releases/latest"

# Current patchwork version is written to .patchwork_version
$VersionFile = ".patchwork_version"

$GodotOutputDir   = "./godot_editor"
$PluginOutputDir  = "./addons/patchwork"

# Temporary paths
$TempDir = Join-Path $env:TEMP "patchwork_update"
$GodotZipPath  = Join-Path $TempDir "godot.zip"
$PluginZipPath = Join-Path $TempDir "plugin.zip"

# Ensures a directory is empty and exists
function Ensure-EmptyDirectory($Path) {
    if (Test-Path $Path) {
        Remove-Item $Path -Recurse -Force
    }
    New-Item -ItemType Directory -Path $Path | Out-Null
}

if (Test-Path $VersionFile) {
    $CurrentVersion = Get-Content $VersionFile -Raw
} else {
    $CurrentVersion = ""
}

Write-Host "Current Patchwork version: $CurrentVersion"
Write-Host "Querying GitHub for latest release..."

$Headers = @{
    "Accept"     = "application/vnd.github+json"
    "User-Agent" = "patchwork-updater"
}

$Release = Invoke-RestMethod -Uri $GitHubApi -Headers $Headers

$LatestVersion = $Release.tag_name
Write-Host "Latest Patchwork version: $LatestVersion"

if ($CurrentVersion -eq $LatestVersion) {
    Write-Host "Patchwork is already up to date. Exiting."
    exit 0
}

# Find the artifacts
$GodotAsset = $Release.assets | Where-Object {
    $_.name -like "*godot-with-patchwork-windows*"
}

$PluginAsset = $Release.assets | Where-Object {
    $_.name -like "*patchwork-godot-plugin*"
}

if (-not $GodotAsset -or -not $PluginAsset) {
    throw "Required release assets not found."
}

# Download the artifacts
Ensure-EmptyDirectory $TempDir

Write-Host "Downloading Godot editor..."
Invoke-WebRequest -Uri $GodotAsset.browser_download_url -OutFile $GodotZipPath -Headers $Headers

Write-Host "Downloading Patchwork plugin..."
Invoke-WebRequest -Uri $PluginAsset.browser_download_url -OutFile $PluginZipPath -Headers $Headers

# Unzip the artifacts
Write-Host "Extracting Godot editor..."
Ensure-EmptyDirectory $GodotOutputDir
Expand-Archive -Path $GodotZipPath -DestinationPath $GodotOutputDir

# Unzip Patchwork
Write-Host "Extracting Patchwork plugin..."
Ensure-EmptyDirectory $PluginOutputDir
Expand-Archive -Path $PluginZipPath -DestinationPath $PluginOutputDir

# Write version
Write-Host "Writing version file..."
$LatestVersion | Set-Content $VersionFile -NoNewline

# Remove temp
Remove-Item $TempDir -Recurse -Force

Write-Host "Patchwork update complete."