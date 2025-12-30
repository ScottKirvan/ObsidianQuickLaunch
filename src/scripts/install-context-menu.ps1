# Install ObsidianQuickLaunch Windows Explorer Context Menu
# Run this script as Administrator

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "ObsidianQuickLaunch Context Menu Installer" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get the current script directory (src/scripts)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$scriptPath = Join-Path $scriptDir "register-vault-final.ps1"

# Verify the script exists
if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Could not find register-vault-final.ps1" -ForegroundColor Red
    Write-Host "Expected location: $scriptPath" -ForegroundColor Gray
    exit 1
}

Write-Host "Script location: $scriptPath" -ForegroundColor Green
Write-Host ""

# Registry paths for the context menu
# Directory: Right-click ON a folder
$regPathDirectory = "Registry::HKEY_CLASSES_ROOT\Directory\shell\ObsidianQuickLaunch"
$regCommandPathDirectory = "$regPathDirectory\command"

# Directory\Background: Right-click IN a folder (empty space)
$regPathBackground = "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\ObsidianQuickLaunch"
$regCommandPathBackground = "$regPathBackground\command"

Write-Host "Installing context menu..." -ForegroundColor Cyan

try {
    # ===== Option 1: Right-click ON a folder =====
    Write-Host "  Adding menu for folders..." -ForegroundColor Gray

    if (-not (Test-Path $regPathDirectory)) {
        New-Item -Path $regPathDirectory -Force | Out-Null
    }
    Set-ItemProperty -Path $regPathDirectory -Name "(Default)" -Value "Open as Obsidian Vault"

    # Try to find Obsidian executable from registry
    $obsidianExePath = $null
    try {
        $regKey = Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\obsidian\shell\open\command" -ErrorAction SilentlyContinue
        if ($regKey) {
            # Extract path from command (remove quotes and arguments)
            $command = $regKey.'(default)'
            if ($command -match '"([^"]+)"') {
                $obsidianExePath = $matches[1]
            }
        }
    } catch {
        # Silent fail, will fall back to common paths
    }

    # Fallback to common installation paths if registry lookup failed
    if (-not $obsidianExePath -or -not (Test-Path $obsidianExePath)) {
        $obsidianIconPaths = @(
            "$env:LOCALAPPDATA\Obsidian\Obsidian.exe",
            "$env:LOCALAPPDATA\Programs\Obsidian\Obsidian.exe",
            "$env:PROGRAMFILES\Obsidian\Obsidian.exe"
        )
        foreach ($path in $obsidianIconPaths) {
            if (Test-Path $path) {
                $obsidianExePath = $path
                break
            }
        }
    }

    # Set icon if we found Obsidian
    if ($obsidianExePath -and (Test-Path $obsidianExePath)) {
        Set-ItemProperty -Path $regPathDirectory -Name "Icon" -Value "$obsidianExePath,0"
        Write-Host "  Set icon from: $obsidianExePath" -ForegroundColor Gray
    } else {
        Write-Host "  Warning: Could not find Obsidian executable for icon" -ForegroundColor Yellow
    }

    if (-not (Test-Path $regCommandPathDirectory)) {
        New-Item -Path $regCommandPathDirectory -Force | Out-Null
    }
    # %V = Selected folder path
    $commandDirectory = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" `"%V`""
    Set-ItemProperty -Path $regCommandPathDirectory -Name "(Default)" -Value $commandDirectory

    Write-Host "  Created menu for folders (right-click ON folder)" -ForegroundColor Green

    # ===== Option 2: Right-click IN a folder (background) =====
    Write-Host "  Adding menu for folder backgrounds..." -ForegroundColor Gray

    if (-not (Test-Path $regPathBackground)) {
        New-Item -Path $regPathBackground -Force | Out-Null
    }
    Set-ItemProperty -Path $regPathBackground -Name "(Default)" -Value "Open as Obsidian Vault"

    # Set the same icon for background menu
    if ($obsidianExePath -and (Test-Path $obsidianExePath)) {
        Set-ItemProperty -Path $regPathBackground -Name "Icon" -Value "$obsidianExePath,0"
    }

    if (-not (Test-Path $regCommandPathBackground)) {
        New-Item -Path $regCommandPathBackground -Force | Out-Null
    }
    # %V = Current folder path (where you right-clicked)
    $commandBackground = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`" `"%V`""
    Set-ItemProperty -Path $regCommandPathBackground -Name "(Default)" -Value $commandBackground

    Write-Host "  Created menu for backgrounds (right-click IN folder)" -ForegroundColor Green

    Write-Host ""
    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The context menu has been installed." -ForegroundColor White
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  Option 1: Right-click ON any folder" -ForegroundColor Gray
    Write-Host "  Option 2: Right-click IN a folder (empty space)" -ForegroundColor Gray
    Write-Host "  Then click 'Open as Obsidian Vault'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "The folder will be registered and opened in Obsidian" -ForegroundColor White
    Write-Host ""
    Write-Host "To uninstall: Run uninstall-context-menu.ps1 as Administrator" -ForegroundColor Gray
    Write-Host ""

} catch {
    Write-Host "ERROR: Failed to install context menu" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
