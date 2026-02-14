# Test: Template Chooser (enumeration and merging logic)
# Tests the template discovery logic used by choose-template.ps1
# Note: Dialog visual test requires manual interaction (pass -ShowDialog to test)

param([switch]$ShowDialog)

$ErrorActionPreference = 'Stop'
$passed = 0
$failed = 0
$testRoot = Join-Path $env:TEMP "OQL-test-chooser-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

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

# Replicate the enumeration logic from choose-template.ps1
function Get-TemplateList {
    param([string]$BundledRoot, [string]$UserRoot)

    $templates = [ordered]@{}

    if (Test-Path $BundledRoot) {
        Get-ChildItem -Path $BundledRoot -Directory -Force | ForEach-Object {
            $templates[$_.Name] = $_.FullName
        }
    }

    if (Test-Path $UserRoot) {
        Get-ChildItem -Path $UserRoot -Directory -Force | ForEach-Object {
            $templates[$_.Name] = $_.FullName
        }
    }

    return $templates
}

try {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Template Chooser Tests" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "  Test root: $testRoot" -ForegroundColor Gray
    Write-Host ""

    New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

    # ===== Test 1: Bundled templates only =====
    Write-Host "Test 1: Bundled templates only" -ForegroundColor Yellow
    $bundled = Join-Path $testRoot "bundled1"
    $user = Join-Path $testRoot "user1"  # doesn't exist

    New-Item -ItemType Directory -Path "$bundled\default\.obsidian" -Force | Out-Null
    New-Item -ItemType Directory -Path "$bundled\zettelkasten\.obsidian" -Force | Out-Null
    Set-Content -Path "$bundled\default\.obsidian\app.json" -Value '{}' -NoNewline
    Set-Content -Path "$bundled\zettelkasten\.obsidian\app.json" -Value '{}' -NoNewline

    $result = Get-TemplateList -BundledRoot $bundled -UserRoot $user
    Write-TestResult "Found 2 bundled templates" ($result.Count -eq 2)
    Write-TestResult "Contains 'default'" ($result.Contains("default"))
    Write-TestResult "Contains 'zettelkasten'" ($result.Contains("zettelkasten"))
    Write-Host ""

    # ===== Test 2: User overrides bundled =====
    Write-Host "Test 2: User templates override bundled" -ForegroundColor Yellow
    $bundled2 = Join-Path $testRoot "bundled2"
    $user2 = Join-Path $testRoot "user2"

    New-Item -ItemType Directory -Path "$bundled2\default\.obsidian" -Force | Out-Null
    New-Item -ItemType Directory -Path "$bundled2\zettelkasten\.obsidian" -Force | Out-Null
    New-Item -ItemType Directory -Path "$user2\default\.obsidian" -Force | Out-Null
    New-Item -ItemType Directory -Path "$user2\my-custom\.obsidian" -Force | Out-Null
    Set-Content -Path "$bundled2\default\.obsidian\app.json" -Value '{}' -NoNewline
    Set-Content -Path "$bundled2\zettelkasten\.obsidian\app.json" -Value '{}' -NoNewline
    Set-Content -Path "$user2\default\.obsidian\app.json" -Value '{}' -NoNewline
    Set-Content -Path "$user2\my-custom\.obsidian\app.json" -Value '{}' -NoNewline

    $result2 = Get-TemplateList -BundledRoot $bundled2 -UserRoot $user2

    Write-TestResult "Found 3 templates (merged)" ($result2.Count -eq 3)
    Write-TestResult "'default' points to user path" ($result2["default"] -eq "$user2\default")
    Write-TestResult "'zettelkasten' points to bundled path" ($result2["zettelkasten"] -eq "$bundled2\zettelkasten")
    Write-TestResult "'my-custom' is user-only template" ($result2["my-custom"] -eq "$user2\my-custom")
    Write-Host ""

    # ===== Test 3: Empty directories =====
    Write-Host "Test 3: No templates exist" -ForegroundColor Yellow
    $bundled3 = Join-Path $testRoot "bundled3-empty"
    $user3 = Join-Path $testRoot "user3-nonexistent"
    New-Item -ItemType Directory -Path $bundled3 -Force | Out-Null

    $result3 = Get-TemplateList -BundledRoot $bundled3 -UserRoot $user3
    Write-TestResult "Returns 0 templates" ($result3.Count -eq 0)
    Write-Host ""

    # ===== Test 4: Single template (dialog should be skipped) =====
    Write-Host "Test 4: Single template (dialog skip logic)" -ForegroundColor Yellow
    $bundled4 = Join-Path $testRoot "bundled4"
    $user4 = Join-Path $testRoot "user4-nonexistent"
    New-Item -ItemType Directory -Path "$bundled4\default\.obsidian" -Force | Out-Null
    Set-Content -Path "$bundled4\default\.obsidian\app.json" -Value '{}' -NoNewline

    $result4 = Get-TemplateList -BundledRoot $bundled4 -UserRoot $user4
    Write-TestResult "Single template: dialog should be skipped" ($result4.Count -le 1)
    Write-Host ""

    # ===== Optional: Visual dialog test =====
    if ($ShowDialog) {
        Write-Host "Test 5: Visual dialog test (manual)" -ForegroundColor Yellow
        Write-Host "  Launching dialog with test templates..." -ForegroundColor Gray

        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        $form = New-Object System.Windows.Forms.Form
        $form.Text = "ObsidianQuickLaunch - Choose Template (TEST)"
        $form.Size = New-Object System.Drawing.Size(350, 300)
        $form.StartPosition = "CenterScreen"
        $form.FormBorderStyle = "FixedDialog"
        $form.MaximizeBox = $false
        $form.MinimizeBox = $false
        $form.TopMost = $true

        $label = New-Object System.Windows.Forms.Label
        $label.Text = "Select a template for the new vault:"
        $label.Location = New-Object System.Drawing.Point(10, 15)
        $label.Size = New-Object System.Drawing.Size(320, 20)
        $form.Controls.Add($label)

        $listBox = New-Object System.Windows.Forms.ListBox
        $listBox.Location = New-Object System.Drawing.Point(10, 40)
        $listBox.Size = New-Object System.Drawing.Size(310, 160)
        foreach ($name in $result2.Keys) {
            $listBox.Items.Add($name) | Out-Null
        }
        $listBox.SelectedIndex = 0
        $form.Controls.Add($listBox)

        $okButton = New-Object System.Windows.Forms.Button
        $okButton.Text = "OK"
        $okButton.Size = New-Object System.Drawing.Size(75, 28)
        $okButton.Location = New-Object System.Drawing.Point(160, 220)
        $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.AcceptButton = $okButton
        $form.Controls.Add($okButton)

        $cancelButton = New-Object System.Windows.Forms.Button
        $cancelButton.Text = "Cancel"
        $cancelButton.Size = New-Object System.Drawing.Size(75, 28)
        $cancelButton.Location = New-Object System.Drawing.Point(245, 220)
        $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.CancelButton = $cancelButton
        $form.Controls.Add($cancelButton)

        $dialogResult = $form.ShowDialog()

        if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
            Write-Host "  Selected: $($listBox.SelectedItem)" -ForegroundColor Green
        } else {
            Write-Host "  Cancelled" -ForegroundColor Yellow
        }
        Write-Host ""
    }

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
