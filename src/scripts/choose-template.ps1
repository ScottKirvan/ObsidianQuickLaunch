# Template chooser for ObsidianQuickLaunch
# Shows a dialog to select a template when multiple templates are available.
# Called via Shift+right-click context menu ("Open as Obsidian Vault (choose template)...")

param([string]$VaultPath)

if (-not $VaultPath -or -not (Test-Path $VaultPath)) {
    Write-Host "ERROR: Invalid vault path: $VaultPath" -ForegroundColor Red
    exit 1
}

# Enumerate templates from both bundled and user directories
$userTemplatesRoot = Join-Path $env:APPDATA "ObsidianQuickLaunch\templates"
$bundledTemplatesRoot = Join-Path $PSScriptRoot "..\templates"

$templates = [ordered]@{}

# Bundled templates first
if (Test-Path $bundledTemplatesRoot) {
    Get-ChildItem -Path $bundledTemplatesRoot -Directory -Force | ForEach-Object {
        $templates[$_.Name] = $_.FullName
    }
}

# User templates override bundled by name
if (Test-Path $userTemplatesRoot) {
    Get-ChildItem -Path $userTemplatesRoot -Directory -Force | ForEach-Object {
        $templates[$_.Name] = $_.FullName
    }
}

$registerScript = Join-Path $PSScriptRoot "register-vault-final.ps1"

# If 0 or 1 template, skip dialog and use default
if ($templates.Count -le 1) {
    & $registerScript -VaultPath $VaultPath -TemplateName "default"
    exit 0
}

# Show template chooser dialog
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "ObsidianQuickLaunch - Choose Template"
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
foreach ($name in $templates.Keys) {
    $listBox.Items.Add($name) | Out-Null
}

# Pre-select "default" if it exists, otherwise first item
$defaultIndex = $listBox.Items.IndexOf("default")
if ($defaultIndex -ge 0) { $listBox.SelectedIndex = $defaultIndex }
elseif ($listBox.Items.Count -gt 0) { $listBox.SelectedIndex = 0 }

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

# Double-click selects and confirms
$listBox.Add_DoubleClick({
    $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Close()
})

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK -and $listBox.SelectedItem) {
    $selectedTemplate = $listBox.SelectedItem.ToString()
    & $registerScript -VaultPath $VaultPath -TemplateName $selectedTemplate
} else {
    # User cancelled
    exit 0
}
