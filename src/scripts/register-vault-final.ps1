# Register and open an Obsidian vault while preserving open vaults
#
# KNOWN ISSUE: Homepage Plugin Conflict
# --------------------------------------
# If you use the "homepage" plugin with these settings:
#   - "openOnStartup": true
#   - "openMode": "Replace all open notes"
#
# The plugin will override workspace restoration and replace all tabs with the homepage.
#
# To fix: In the vault's .obsidian/plugins/homepage/data.json, set:
#   - "openOnStartup": false (recommended)
#   OR
#   - "openMode": "Keep open notes" (keeps homepage but also restores tabs)
#
# This ensures vaults restore their previous workspace (open notes, tabs, etc.)
# when reopened by this script.

param([string]$VaultPath)

if (-not (Test-Path $VaultPath)) {
    Write-Host "ERROR: Path does not exist: $VaultPath" -ForegroundColor Red
    exit 1
}

$VaultPath = (Resolve-Path -Path $VaultPath).Path
Write-Host "Registering vault: $VaultPath" -ForegroundColor Cyan

$obsidianConfigPath = Join-Path $env:APPDATA "obsidian\obsidian.json"

if (-not (Test-Path $obsidianConfigPath)) {
    Write-Host "ERROR: Obsidian config not found" -ForegroundColor Red
    exit 1
}

# Check if Obsidian is actually running
$obsidianProcess = Get-Process -Name "Obsidian" -ErrorAction SilentlyContinue
$wasRunning = $null -ne $obsidianProcess

if ($wasRunning) {
    Write-Host "Obsidian is running" -ForegroundColor Yellow

    # Read current config to find open vaults
    $configJson = Get-Content $obsidianConfigPath -Raw -Encoding UTF8
    $config = $configJson | ConvertFrom-Json

    # Find all currently open vaults
    $openVaults = @()
    foreach ($vaultId in $config.vaults.PSObject.Properties.Name) {
        $vault = $config.vaults.$vaultId
        if ($vault.open -eq $true) {
            $openVaults += $vault.path
            Write-Host "  Found open vault: $($vault.path)" -ForegroundColor Gray
        }
    }

    # Close Obsidian (required to safely modify config)
    Write-Host "Closing Obsidian to register vault..." -ForegroundColor Yellow
    $obsidianProcess | Stop-Process -Force
    # Wait longer for Obsidian to save workspace files
    Write-Host "  Waiting for Obsidian to save workspace..." -ForegroundColor Gray
    Start-Sleep -Seconds 3
} else {
    Write-Host "Obsidian is not running" -ForegroundColor Gray
    $openVaults = @()

    # Still need to read config to check if vault exists
    $configJson = Get-Content $obsidianConfigPath -Raw -Encoding UTF8
}

# Check if vault already registered
$normalizedPath = $VaultPath -replace '\\', '\\\\'
$vaultExists = $configJson.Contains($normalizedPath)

if (-not $vaultExists) {
    Write-Host "Registering new vault..." -ForegroundColor Cyan

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "$obsidianConfigPath.$timestamp.bak"
    Copy-Item $obsidianConfigPath $backupPath -Force

    $vaultId = -join ((1..16) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) })
    $tsMillis = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

    $newEntry = '"' + $vaultId + '":{"path":"' + $normalizedPath + '","ts":' + $tsMillis + '}'
    $configJson = $configJson -replace '(\{"vaults":\{)', "`$1$newEntry,"
    [System.IO.File]::WriteAllText($obsidianConfigPath, $configJson, [System.Text.UTF8Encoding]::new($false))

    Write-Host "Vault registered!" -ForegroundColor Green
}

# Create .obsidian folder
$obsidianFolder = Join-Path $VaultPath ".obsidian"
if (-not (Test-Path $obsidianFolder)) {
    New-Item -ItemType Directory -Path $obsidianFolder | Out-Null
}

# Reopen all previously open vaults + the new one
Write-Host ""
Write-Host "Reopening vaults..." -ForegroundColor Cyan

# Open previously open vaults first
foreach ($vaultToOpen in $openVaults) {
    if ($vaultToOpen -ne $VaultPath) {
        $encodedPath = [System.Uri]::EscapeDataString($vaultToOpen)
        $uri = "obsidian://open?path=$encodedPath"
        Write-Host "  Opening: $vaultToOpen" -ForegroundColor Gray
        Start-Process $uri
        Start-Sleep -Milliseconds 500
    }
}

# Open the new vault LAST so it appears on top
$encodedPath = [System.Uri]::EscapeDataString($VaultPath)
$uri = "obsidian://open?path=$encodedPath"
Write-Host "  Opening (new): $VaultPath" -ForegroundColor Cyan
Start-Process $uri

Write-Host ""
Write-Host "Done! All vaults reopened." -ForegroundColor Green
Write-Host ""
