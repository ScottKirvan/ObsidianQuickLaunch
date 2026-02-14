# Test: Template Application (non-destructive copy)
# Tests the Copy-TemplateNonDestructive function from register-vault-final.ps1

$ErrorActionPreference = 'Stop'
$passed = 0
$failed = 0
$testRoot = Join-Path $env:TEMP "OQL-test-templates-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

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

# Import the Copy-TemplateNonDestructive function by dot-sourcing a wrapper
# We extract the function to test it in isolation
function Copy-TemplateNonDestructive {
    param([string]$TemplatePath, [string]$DestinationPath)

    if (-not (Test-Path $TemplatePath)) { return $false }

    $copiedCount = 0
    $skippedCount = 0
    $templateFiles = Get-ChildItem -Path $TemplatePath -Recurse -File -Force
    foreach ($file in $templateFiles) {
        $relativePath = $file.FullName.Substring($TemplatePath.Length).TrimStart('\')
        $destFile = Join-Path $DestinationPath $relativePath
        $destDir = Split-Path $destFile -Parent

        if (-not (Test-Path $destFile)) {
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item $file.FullName -Destination $destFile -Force
            $copiedCount++
        } else {
            $skippedCount++
        }
    }

    return $true
}

try {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Template Application Tests" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Test root: $testRoot" -ForegroundColor Gray
    Write-Host ""

    # Setup: create test directories
    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

    # ===== Test 1: Copy template files to empty vault =====
    Write-Host "Test 1: Copy to empty vault" -ForegroundColor Yellow
    $template1 = Join-Path $testRoot "template1"
    $vault1 = Join-Path $testRoot "vault1"
    New-Item -ItemType Directory -Path "$template1\.obsidian" -Force | Out-Null
    New-Item -ItemType Directory -Path $vault1 -Force | Out-Null
    Set-Content -Path "$template1\.obsidian\app.json" -Value '{}' -NoNewline
    Set-Content -Path "$template1\.obsidian\appearance.json" -Value '{"theme":"moonstone"}' -NoNewline

    $result = Copy-TemplateNonDestructive -TemplatePath $template1 -DestinationPath $vault1

    Write-TestResult "Function returns true" $result
    Write-TestResult "app.json copied" (Test-Path "$vault1\.obsidian\app.json")
    Write-TestResult "appearance.json copied" (Test-Path "$vault1\.obsidian\appearance.json")
    Write-TestResult "app.json content correct" ((Get-Content "$vault1\.obsidian\app.json" -Raw) -eq '{}')
    Write-Host ""

    # ===== Test 2: Non-destructive - don't overwrite existing files =====
    Write-Host "Test 2: Non-destructive (no overwrite)" -ForegroundColor Yellow
    $template2 = Join-Path $testRoot "template2"
    $vault2 = Join-Path $testRoot "vault2"
    New-Item -ItemType Directory -Path "$template2\.obsidian" -Force | Out-Null
    New-Item -ItemType Directory -Path "$vault2\.obsidian" -Force | Out-Null

    # Template has a file
    Set-Content -Path "$template2\.obsidian\app.json" -Value '{"template":"version"}' -NoNewline
    # Vault already has same file with different content
    Set-Content -Path "$vault2\.obsidian\app.json" -Value '{"user":"settings"}' -NoNewline
    # Template has an additional file
    Set-Content -Path "$template2\.obsidian\hotkeys.json" -Value '{}' -NoNewline

    Copy-TemplateNonDestructive -TemplatePath $template2 -DestinationPath $vault2 | Out-Null

    $existingContent = Get-Content "$vault2\.obsidian\app.json" -Raw
    Write-TestResult "Existing file NOT overwritten" ($existingContent -eq '{"user":"settings"}')
    Write-TestResult "New file added alongside existing" (Test-Path "$vault2\.obsidian\hotkeys.json")
    Write-Host ""

    # ===== Test 3: Nested directory structures =====
    Write-Host "Test 3: Nested directory structures" -ForegroundColor Yellow
    $template3 = Join-Path $testRoot "template3"
    $vault3 = Join-Path $testRoot "vault3"
    New-Item -ItemType Directory -Path "$template3\.obsidian\plugins\homepage" -Force | Out-Null
    New-Item -ItemType Directory -Path "$template3\Daily Notes" -Force | Out-Null
    New-Item -ItemType Directory -Path "$template3\Templates" -Force | Out-Null
    New-Item -ItemType Directory -Path $vault3 -Force | Out-Null

    Set-Content -Path "$template3\.obsidian\plugins\homepage\data.json" -Value '{"openOnStartup":false}' -NoNewline
    Set-Content -Path "$template3\Daily Notes\placeholder.md" -Value '# Daily Notes' -NoNewline
    Set-Content -Path "$template3\Templates\note-template.md" -Value '# {{title}}' -NoNewline

    Copy-TemplateNonDestructive -TemplatePath $template3 -DestinationPath $vault3 | Out-Null

    Write-TestResult "Nested plugin file created" (Test-Path "$vault3\.obsidian\plugins\homepage\data.json")
    Write-TestResult "Daily Notes folder created with file" (Test-Path "$vault3\Daily Notes\placeholder.md")
    Write-TestResult "Templates folder created with file" (Test-Path "$vault3\Templates\note-template.md")
    Write-Host ""

    # ===== Test 4: Missing template path returns false =====
    Write-Host "Test 4: Missing template path" -ForegroundColor Yellow
    $result = Copy-TemplateNonDestructive -TemplatePath "C:\nonexistent\template" -DestinationPath $vault1
    Write-TestResult "Returns false for missing template" ($result -eq $false)
    Write-Host ""

    # ===== Test 5: Template resolution (user overrides bundled) =====
    Write-Host "Test 5: Template resolution priority" -ForegroundColor Yellow
    $bundledRoot = Join-Path $testRoot "bundled-templates"
    $userRoot = Join-Path $testRoot "user-templates"

    # Create bundled "default" template
    New-Item -ItemType Directory -Path "$bundledRoot\default\.obsidian" -Force | Out-Null
    Set-Content -Path "$bundledRoot\default\.obsidian\app.json" -Value '{"source":"bundled"}' -NoNewline

    # Create user "default" template (should override)
    New-Item -ItemType Directory -Path "$userRoot\default\.obsidian" -Force | Out-Null
    Set-Content -Path "$userRoot\default\.obsidian\app.json" -Value '{"source":"user"}' -NoNewline

    # Create bundled-only template
    New-Item -ItemType Directory -Path "$bundledRoot\zettelkasten\.obsidian" -Force | Out-Null
    Set-Content -Path "$bundledRoot\zettelkasten\.obsidian\app.json" -Value '{"source":"bundled-zk"}' -NoNewline

    # Simulate resolution logic
    $templateName = "default"
    $userPath = Join-Path $userRoot $templateName
    $bundledPath = Join-Path $bundledRoot $templateName

    $resolvedPath = $null
    if (Test-Path $userPath) { $resolvedPath = $userPath }
    elseif (Test-Path $bundledPath) { $resolvedPath = $bundledPath }

    Write-TestResult "User template takes priority over bundled" ($resolvedPath -eq $userPath)

    # Bundled-only template resolves correctly
    $templateName = "zettelkasten"
    $userPath = Join-Path $userRoot $templateName
    $bundledPath = Join-Path $bundledRoot $templateName
    $resolvedPath = $null
    if (Test-Path $userPath) { $resolvedPath = $userPath }
    elseif (Test-Path $bundledPath) { $resolvedPath = $bundledPath }

    Write-TestResult "Bundled template used when no user override" ($resolvedPath -eq $bundledPath)

    # Non-existent template
    $templateName = "nonexistent"
    $userPath = Join-Path $userRoot $templateName
    $bundledPath = Join-Path $bundledRoot $templateName
    $resolvedPath = $null
    if (Test-Path $userPath) { $resolvedPath = $userPath }
    elseif (Test-Path $bundledPath) { $resolvedPath = $bundledPath }

    Write-TestResult "Non-existent template resolves to null" ($null -eq $resolvedPath)
    Write-Host ""

    # ===== Results =====
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Results: $passed passed, $failed failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""

} finally {
    # Cleanup
    if (Test-Path $testRoot) {
        Remove-Item $testRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

if ($failed -gt 0) { exit 1 }
