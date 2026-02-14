<#
.SYNOPSIS
    Builds the ObsidianQuickLaunch MSI installer

.DESCRIPTION
    This script uses WiX Toolset 3.x to create an MSI installer for ObsidianQuickLaunch.
    The installer packages PowerShell scripts and configures Windows Explorer context menus.

.PARAMETER Action
    The build action to perform:
    - build: Build the MSI (fails if already exists)
    - rebuild: Clean and build (recommended)
    - clean: Remove build artifacts only

.PARAMETER Version
    Version number for the installer (e.g., "1.0.0")
    If not specified, reads from .github/release-please/.release-please-manifest.json

.EXAMPLE
    .\Build-Installer.ps1 rebuild
    Cleans and builds fresh installer (most common)

.EXAMPLE
    .\Build-Installer.ps1 build
    Builds installer (fails if MSI already exists)

.EXAMPLE
    .\Build-Installer.ps1 clean
    Removes build artifacts only

.EXAMPLE
    .\Build-Installer.ps1 rebuild -Version "1.2.3"
    Builds version 1.2.3 with clean rebuild

.NOTES
    Requires:
    - WiX Toolset v3.x (https://wixtoolset.org/releases/)
    - PowerShell 5.1 or later
    - Windows OS
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('build', 'rebuild', 'clean')]
    [string]$Action = 'rebuild',

    [Parameter()]
    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version
)

$ErrorActionPreference = 'Stop'

# Get repository root (script is in tools/build/, so go up two levels)
$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$PackagingRoot = Join-Path $RepoRoot "tools\packaging"
$DistPath = Join-Path $RepoRoot "dist"
$StagingPath = Join-Path $PackagingRoot "staging"

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  ObsidianQuickLaunch Installer Builder" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

#region Clean Build Artifacts
if ($Action -eq 'clean' -or $Action -eq 'rebuild') {
    Write-Host "Cleaning build artifacts..." -ForegroundColor Yellow
    if (Test-Path $DistPath) {
        Remove-Item $DistPath -Recurse -Force
        Write-Host "  Removed: $DistPath" -ForegroundColor Gray
    }
    if (Test-Path $StagingPath) {
        Remove-Item $StagingPath -Recurse -Force
        Write-Host "  Removed: $StagingPath" -ForegroundColor Gray
    }
    Write-Host "Clean complete.`n" -ForegroundColor Green

    # If action is only clean, exit here
    if ($Action -eq 'clean') {
        Write-Host "Clean-only operation complete." -ForegroundColor Green
        exit 0
    }
}
#endregion

#region Determine Version
if (-not $Version) {
    # Read version from release-please manifest
    $manifestPath = Join-Path $RepoRoot ".github\release-please\.release-please-manifest.json"
    if (Test-Path $manifestPath) {
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
        $Version = $manifest.'.'
        Write-Host "Version from manifest: $Version" -ForegroundColor Green
    }
    else {
        Write-Error "Version not specified and manifest not found: $manifestPath"
    }
}
else {
    Write-Host "Version specified: $Version" -ForegroundColor Green
}
Write-Host ""
#endregion

#region Prepare Staging Directory
Write-Host "Preparing staging directory..." -ForegroundColor Cyan

# Create staging directory
if (Test-Path $StagingPath) {
    Remove-Item $StagingPath -Recurse -Force
}
New-Item -ItemType Directory -Path $StagingPath -Force | Out-Null

# Copy source files to staging
$stagingScriptsPath = Join-Path $StagingPath "scripts"
New-Item -ItemType Directory -Path $stagingScriptsPath -Force | Out-Null

$sourceScripts = @(
    "register-vault-final.ps1",
    "install-context-menu.ps1",
    "uninstall-context-menu.ps1",
    "choose-template.ps1",
    "open-md-file.ps1"
)

foreach ($script in $sourceScripts) {
    $sourcePath = Join-Path $RepoRoot "src\scripts\$script"
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath -Destination $stagingScriptsPath -Force
        Write-Host "  Copied: $script" -ForegroundColor Gray
    }
    else {
        Write-Warning "  Script not found: $sourcePath"
    }
}

# Copy templates to staging
$sourceTemplatesPath = Join-Path $RepoRoot "src\templates"
if (Test-Path $sourceTemplatesPath) {
    $stagingTemplatesPath = Join-Path $StagingPath "templates"
    Copy-Item $sourceTemplatesPath -Destination $stagingTemplatesPath -Recurse -Force
    $templateCount = (Get-ChildItem $stagingTemplatesPath -Directory).Count
    Write-Host "  Copied: templates/ ($templateCount template(s))" -ForegroundColor Gray
} else {
    Write-Warning "  Templates directory not found: $sourceTemplatesPath"
}

# Copy README and LICENSE if they exist
$docsToInclude = @("README.md", "LICENSE.md", "notes\README.md")
foreach ($doc in $docsToInclude) {
    $sourcePath = Join-Path $RepoRoot $doc
    if (Test-Path $sourcePath) {
        $destName = Split-Path $doc -Leaf
        Copy-Item $sourcePath -Destination (Join-Path $StagingPath $destName) -Force
        Write-Host "  Copied: $destName" -ForegroundColor Gray
    }
}

Write-Host "Staging complete.`n" -ForegroundColor Green
#endregion

#region Import Packaging Module
Write-Host "Loading packaging module..." -ForegroundColor Cyan
$packagingModulePath = Join-Path $PackagingRoot "packaging.psd1"

if (-not (Test-Path $packagingModulePath)) {
    Write-Error "Packaging module not found: $packagingModulePath"
}

Import-Module $packagingModulePath -Force
Write-Host "Packaging module loaded.`n" -ForegroundColor Green
#endregion

#region Verify WiX Toolset
Write-Host "Checking for WiX Toolset..." -ForegroundColor Cyan
try {
    $wixPath = Get-WixPath
    Write-Host "WiX Toolset found: $($wixPath.wixPath)" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "ERROR: WiX Toolset v3.x not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install WiX Toolset v3.x from:" -ForegroundColor Yellow
    Write-Host "  https://wixtoolset.org/releases/" -ForegroundColor White
    Write-Host ""
    Write-Host "Recommended: WiX Toolset v3.14" -ForegroundColor Gray
    Write-Host ""
    exit 1
}
#endregion

#region Build MSI
Write-Host "Building MSI package..." -ForegroundColor Cyan
Write-Host ""

try {
    $buildParams = @{
        ProductVersion    = $Version
        ProductSourcePath = $StagingPath
        OutputPath        = $DistPath
    }

    # Rebuild action always forces overwrite (since we cleaned)
    if ($Action -eq 'rebuild') {
        $buildParams['Force'] = $true
    }

    $result = New-MSIPackage @buildParams

    Write-Host ""
    Write-Host "================================================" -ForegroundColor Green
    Write-Host "  BUILD SUCCESSFUL" -ForegroundColor Green
    Write-Host "================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Package Details:" -ForegroundColor White
    Write-Host "  Version:  $($result.Version)" -ForegroundColor Gray
    Write-Host "  MSI:      $($result.MSI)" -ForegroundColor Gray
    if ($result.PDB) {
        Write-Host "  Symbols:  $($result.PDB)" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Test the installer: msiexec /i `"$($result.MSI)`"" -ForegroundColor Gray
    Write-Host "  2. Check Add/Remove Programs for ObsidianQuickLaunch" -ForegroundColor Gray
    Write-Host "  3. Right-click any folder to see 'Open as Obsidian Vault'" -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Red
    Write-Host "  BUILD FAILED" -ForegroundColor Red
    Write-Host "================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    if ($_.Exception.InnerException) {
        Write-Host "Inner Exception: $($_.Exception.InnerException.Message)" -ForegroundColor Red
        Write-Host ""
    }
    Write-Host "Stack Trace:" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    Write-Host ""
    exit 1
}
#endregion
