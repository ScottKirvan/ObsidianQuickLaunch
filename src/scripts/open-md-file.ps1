# Open a .md file by registering its parent folder as an Obsidian vault
# Used for .md file association (opt-in feature)

param([string]$FilePath)

if (-not $FilePath) {
    Write-Host "ERROR: No file path specified" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $FilePath)) {
    Write-Host "ERROR: File does not exist: $FilePath" -ForegroundColor Red
    exit 1
}

$FilePath = (Resolve-Path -Path $FilePath).Path

# Use the immediate parent folder as the vault root
$vaultPath = Split-Path -Parent $FilePath

if (-not (Test-Path $vaultPath)) {
    Write-Host "ERROR: Parent directory does not exist: $vaultPath" -ForegroundColor Red
    exit 1
}

# Delegate to the main registration script
$registerScript = Join-Path $PSScriptRoot "register-vault-final.ps1"

if (-not (Test-Path $registerScript)) {
    Write-Host "ERROR: Could not find register-vault-final.ps1" -ForegroundColor Red
    Write-Host "Expected location: $registerScript" -ForegroundColor Gray
    exit 1
}

& $registerScript -VaultPath $vaultPath
