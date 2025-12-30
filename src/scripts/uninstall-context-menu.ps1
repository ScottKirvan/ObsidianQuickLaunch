# Uninstall ObsidianQuickLaunch Windows Explorer Context Menu
# Run this script as Administrator

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "ObsidianQuickLaunch Context Menu Uninstaller" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Registry paths for the context menu
$regPathDirectory = "Registry::HKEY_CLASSES_ROOT\Directory\shell\ObsidianQuickLaunch"
$regPathBackground = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\ObsidianQuickLaunch"

Write-Host "Checking for installed context menu..." -ForegroundColor Cyan

$found = $false

# Remove folder context menu
if (Test-Path $regPathDirectory) {
    Write-Host "Found folder context menu" -ForegroundColor Yellow
    try {
        Remove-Item -Path $regPathDirectory -Recurse -Force
        Write-Host "  Removed folder context menu" -ForegroundColor Green
        $found = $true
    } catch {
        Write-Host "  ERROR: Failed to remove folder context menu" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Remove background context menu
if (Test-Path $regPathBackground) {
    Write-Host "Found background context menu" -ForegroundColor Yellow
    try {
        Remove-Item -Path $regPathBackground -Recurse -Force
        Write-Host "  Removed background context menu" -ForegroundColor Green
        $found = $true
    } catch {
        Write-Host "  ERROR: Failed to remove background context menu" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
    }
}

if ($found) {
    Write-Host ""
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The context menu has been removed." -ForegroundColor White
    Write-Host "You may need to restart Explorer or log out/in for changes to take effect." -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "Context menu is not installed." -ForegroundColor Yellow
    Write-Host ""
}
