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
$regPathDirectoryTemplate = "Registry::HKEY_CLASSES_ROOT\Directory\shell\ObsidianQuickLaunchTemplate"
$regPathBackgroundTemplate = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\ObsidianQuickLaunchTemplate"

Write-Host "Checking for installed context menu..." -ForegroundColor Cyan

$found = $false

# Remove all context menu entries
$regPaths = @(
    @{ Path = $regPathDirectory;         Name = "folder context menu" },
    @{ Path = $regPathBackground;        Name = "background context menu" },
    @{ Path = $regPathDirectoryTemplate; Name = "folder template chooser menu" },
    @{ Path = $regPathBackgroundTemplate; Name = "background template chooser menu" }
)

foreach ($entry in $regPaths) {
    if (Test-Path $entry.Path) {
        Write-Host "Found $($entry.Name)" -ForegroundColor Yellow
        try {
            Remove-Item -Path $entry.Path -Recurse -Force
            Write-Host "  Removed $($entry.Name)" -ForegroundColor Green
            $found = $true
        } catch {
            Write-Host "  ERROR: Failed to remove $($entry.Name)" -ForegroundColor Red
            Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
        }
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
