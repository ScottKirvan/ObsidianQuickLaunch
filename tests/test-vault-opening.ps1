# Test script for opening Obsidian vaults
# This will test various methods to open an Obsidian vault

$vaultPath = "d:\1\GitRepos\ScottKirvan\ObsidianQuickLaunch\vaulttest"

Write-Host "Testing Obsidian vault opening methods..." -ForegroundColor Cyan
Write-Host "Vault path: $vaultPath" -ForegroundColor Yellow
Write-Host ""

# Method 1: Obsidian URI Protocol
Write-Host "Method 1: Testing obsidian:// URI protocol" -ForegroundColor Green
$encodedPath = [System.Uri]::EscapeDataString($vaultPath)
$uri = "obsidian://open?path=$encodedPath"
Write-Host "URI: $uri" -ForegroundColor Gray
try {
    Start-Process $uri
    Write-Host "URI protocol launched successfully" -ForegroundColor Green
} catch {
    Write-Host "URI protocol failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press any key to test Method 2..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Method 2: Direct executable with path argument
Write-Host ""
Write-Host "Method 2: Testing direct executable launch" -ForegroundColor Green

# Common Obsidian installation locations
$possiblePaths = @(
    "D:\bin\Obsidian\Obsidian.exe",
    "$env:LOCALAPPDATA\Obsidian\Obsidian.exe",
    "$env:LOCALAPPDATA\Programs\Obsidian\Obsidian.exe",
    "$env:PROGRAMFILES\Obsidian\Obsidian.exe",
    "${env:PROGRAMFILES(x86)}\Obsidian\Obsidian.exe"
)

$obsidianExe = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $obsidianExe = $path
        Write-Host "Found Obsidian at: $path" -ForegroundColor Yellow
        break
    }
}

if ($obsidianExe) {
    Write-Host "Launching: $obsidianExe with argument $vaultPath" -ForegroundColor Gray
    try {
        Start-Process $obsidianExe -ArgumentList "`"$vaultPath`""
        Write-Host "Direct executable launched successfully" -ForegroundColor Green
    } catch {
        Write-Host "Direct executable failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "Could not find Obsidian.exe in common locations" -ForegroundColor Red
    Write-Host "  Searched:" -ForegroundColor Gray
    foreach ($path in $possiblePaths) {
        Write-Host "    - $path" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "Press any key to test Method 3..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Method 3: Check registry for obsidian:// protocol handler
Write-Host ""
Write-Host "Method 3: Checking Windows registry for obsidian:// handler" -ForegroundColor Green
try {
    $regPath = "HKCU:\SOFTWARE\Classes\obsidian"
    if (Test-Path $regPath) {
        $command = (Get-ItemProperty -Path "$regPath\shell\open\command" -ErrorAction SilentlyContinue).'(default)'
        Write-Host "Registry entry found: $command" -ForegroundColor Green
    } else {
        Write-Host "No registry entry for obsidian:// protocol" -ForegroundColor Red
    }
} catch {
    Write-Host "Registry check failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test complete! Which method worked for you?" -ForegroundColor Cyan
