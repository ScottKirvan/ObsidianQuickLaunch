# Test launching Obsidian.exe directly with a vault path

$vaultPath = "d:\1\GitRepos\ScottKirvan\ObsidianQuickLaunch\vaulttest"
$obsidianExe = "D:\bin\Obsidian\Obsidian.exe"

Write-Host "Testing direct Obsidian.exe launch..." -ForegroundColor Cyan
Write-Host "Vault: $vaultPath" -ForegroundColor Yellow
Write-Host ""

# Test 1: Launch with quoted path as argument
Write-Host "Method 1: Obsidian.exe with vault path as argument" -ForegroundColor Green
try {
    Start-Process $obsidianExe -ArgumentList "`"$vaultPath`""
    Write-Host "Launched!" -ForegroundColor Green
} catch {
    Write-Host "Failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Did this:" -ForegroundColor Cyan
Write-Host "  a) Open a new Obsidian window with vaulttest?" -ForegroundColor Yellow
Write-Host "  b) Switch existing window to vaulttest?" -ForegroundColor Yellow
Write-Host "  c) Do nothing / show error?" -ForegroundColor Yellow
Write-Host "  d) Just open Obsidian without a specific vault?" -ForegroundColor Yellow
