# Test if Obsidian hot-reloads the vault list after we modify obsidian.json

$testVaultPath = "d:\1\GitRepos\ScottKirvan\ObsidianQuickLaunch\vaulttest"
$obsidianConfigPath = Join-Path $env:APPDATA "obsidian\obsidian.json"

Write-Host "This test will:" -ForegroundColor Cyan
Write-Host "1. Add a vault to obsidian.json while Obsidian is running" -ForegroundColor Yellow
Write-Host "2. Try to open it immediately" -ForegroundColor Yellow
Write-Host "3. See if Obsidian recognizes it without restarting" -ForegroundColor Yellow
Write-Host ""

# Read config
$configJson = Get-Content $obsidianConfigPath -Raw -Encoding UTF8

# Generate unique vault ID
$vaultId = -join ((1..16) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) })
$tsMillis = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$normalizedPath = $testVaultPath -replace '\\', '\\\\'

# Create new vault entry
$newVaultEntry = "`"$vaultId`":{`"path`":`"$normalizedPath`",`"ts`":$tsMillis}"

# Backup first
$backupPath = "$obsidianConfigPath.hotreload-test.bak"
Copy-Item $obsidianConfigPath $backupPath -Force
Write-Host "Backed up config to: $backupPath" -ForegroundColor Gray

# Modify config
$configJson = $configJson -replace '(\{"vaults":\{)', "`$1$newVaultEntry,"
[System.IO.File]::WriteAllText($obsidianConfigPath, $configJson, [System.Text.UTF8Encoding]::new($false))

Write-Host "Added vault with ID: $vaultId" -ForegroundColor Green
Write-Host ""
Write-Host "Waiting 2 seconds for Obsidian to potentially reload..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

# Try to open it
$encodedPath = [System.Uri]::EscapeDataString($testVaultPath)
$uri = "obsidian://open?path=$encodedPath"

Write-Host "Opening vault..." -ForegroundColor Cyan
Write-Host "URI: $uri" -ForegroundColor DarkGray
Start-Process $uri

Write-Host ""
Write-Host "Did it work? Or did you get 'Vault not found'?" -ForegroundColor Cyan
