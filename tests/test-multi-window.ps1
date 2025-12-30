# Test if Obsidian supports opening multiple vault windows simultaneously

$vault1 = "D:\1\GitRepos\ScottKirvan\Vaults\sk"
$vault2 = "d:\1\GitRepos\ScottKirvan\ObsidianQuickLaunch\vaulttest"

Write-Host "Testing multiple vault windows..." -ForegroundColor Cyan

# Try opening vault 1
$uri1 = "obsidian://open?path=" + [System.Uri]::EscapeDataString($vault1)
Write-Host "Opening vault 1: $vault1" -ForegroundColor Yellow
Start-Process $uri1
Start-Sleep -Seconds 3

# Try opening vault 2 (should this open a second window?)
$uri2 = "obsidian://open?path=" + [System.Uri]::EscapeDataString($vault2)
Write-Host "Opening vault 2: $vault2" -ForegroundColor Yellow
Start-Process $uri2

Write-Host ""
Write-Host "Did Obsidian open two separate windows, or did it switch vaults?" -ForegroundColor Cyan
