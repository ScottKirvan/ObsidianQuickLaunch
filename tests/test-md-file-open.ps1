# Test: .md File Handler (open-md-file.ps1 path resolution)
# Tests that the script correctly resolves parent folders from .md file paths
# Note: Does NOT actually open Obsidian - only tests path resolution logic

$ErrorActionPreference = 'Stop'
$passed = 0
$failed = 0
$testRoot = Join-Path $env:TEMP "OQL-test-mdfile-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

function Write-TestResult {
    param([string]$Name, [bool]$Success, [string]$Detail = "")
    if ($Success) {
        Write-Host "  PASS: $Name" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  FAIL: $Name - $Detail" -ForegroundColor Red
        $script:failed++
    }
}

try {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  .md File Handler Tests" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Test root: $testRoot" -ForegroundColor Gray
    Write-Host ""

    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

    # ===== Test 1: Basic parent folder resolution =====
    Write-Host "Test 1: Basic parent folder resolution" -ForegroundColor Yellow
    $testDir1 = Join-Path $testRoot "project1"
    New-Item -ItemType Directory -Path $testDir1 -Force | Out-Null
    $testFile1 = Join-Path $testDir1 "notes.md"
    Set-Content -Path $testFile1 -Value "# Test Notes"

    $resolvedPath = Split-Path -Parent (Resolve-Path -Path $testFile1).Path
    Write-TestResult "Parent resolved to project folder" ($resolvedPath -eq $testDir1)
    Write-Host ""

    # ===== Test 2: Nested file =====
    Write-Host "Test 2: Nested file resolution" -ForegroundColor Yellow
    $testDir2 = Join-Path $testRoot "project2\docs\api"
    New-Item -ItemType Directory -Path $testDir2 -Force | Out-Null
    $testFile2 = Join-Path $testDir2 "endpoints.md"
    Set-Content -Path $testFile2 -Value "# API Endpoints"

    $resolvedPath2 = Split-Path -Parent (Resolve-Path -Path $testFile2).Path
    Write-TestResult "Parent is immediate containing folder" ($resolvedPath2 -eq $testDir2)
    Write-Host ""

    # ===== Test 3: Path with spaces =====
    Write-Host "Test 3: Path with spaces" -ForegroundColor Yellow
    $testDir3 = Join-Path $testRoot "My Project Files\sub folder"
    New-Item -ItemType Directory -Path $testDir3 -Force | Out-Null
    $testFile3 = Join-Path $testDir3 "my notes.md"
    Set-Content -Path $testFile3 -Value "# Notes with spaces"

    $resolvedPath3 = Split-Path -Parent (Resolve-Path -Path $testFile3).Path
    Write-TestResult "Handles spaces in path" ($resolvedPath3 -eq $testDir3)
    Write-Host ""

    # ===== Test 4: Validate the script exists and has correct structure =====
    Write-Host "Test 4: Script validation" -ForegroundColor Yellow
    $scriptPath = Join-Path $PSScriptRoot "..\src\scripts\open-md-file.ps1"
    if (-not (Test-Path $scriptPath)) {
        # Try from repo root
        $scriptPath = Join-Path (Split-Path -Parent $PSScriptRoot) "src\scripts\open-md-file.ps1"
    }

    $scriptExists = Test-Path $scriptPath
    Write-TestResult "open-md-file.ps1 exists" $scriptExists

    if ($scriptExists) {
        $content = Get-Content $scriptPath -Raw
        Write-TestResult "Script accepts FilePath parameter" ($content -match 'param.*\$FilePath')
        Write-TestResult "Script calls register-vault-final.ps1" ($content -match 'register-vault-final\.ps1')
        Write-TestResult "Script uses Split-Path -Parent" ($content -match 'Split-Path.*-Parent')
    }
    Write-Host ""

    # ===== Results =====
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

} finally {
    if (Test-Path $testRoot) {
        Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($failed -gt 0) { exit 1 }
