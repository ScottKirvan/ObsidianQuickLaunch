# ObsidianQuickLaunch

Windows context menu integration for quickly opening folders as Obsidian vaults.

## Features

- Right-click any folder in Windows Explorer to open it as an Obsidian vault
- Automatically registers new vaults with Obsidian
- Preserves all currently open vaults and workspaces when opening new vaults
- Restores previous workspace state (open notes, tabs, sidebar layout)
- **Template system** — automatically apply vault templates on creation (non-destructive)
- **Template chooser** — pick from available templates via context menu
- **.md file association** (opt-in) — double-click `.md` files to open in Obsidian

## Current Status

**Phase 1: ✅ COMPLETE**
- ✅ Register vaults in Obsidian's config
- ✅ Open vaults using the `obsidian://` URI protocol
- ✅ Preserve open vaults when opening new ones
- ✅ Workspace restoration (tabs, notes, layout)
- ✅ Windows Explorer context menu integration
- ✅ Obsidian icon in context menu
- ✅ Auto-detect Obsidian installation

**Phase 2: ✅ COMPLETE**
- ✅ Template vault system (default + chooser)
- ✅ .md file association (opt-in)
- ✅ MSI installer with feature selection

## Usage

### Manual Usage

```powershell
.\src\scripts\register-vault-final.ps1 "C:\path\to\folder"
```

This will:
1. Close Obsidian (required to safely modify config)
2. Register the folder as an Obsidian vault
3. Apply the default template (non-destructive — won't overwrite existing files)
4. Reopen all previously open vaults
5. Open the new vault

To use a specific template:
```powershell
.\src\scripts\register-vault-final.ps1 "C:\path\to\folder" -TemplateName "zettelkasten"
```

### Context Menu (Installed)

After running the installer:

**"QuickLaunch Obsidian here"**
1. Right-click ON any folder, or right-click IN a folder (empty space)
2. Click "QuickLaunch Obsidian here"
3. The folder is registered as a vault and opened in Obsidian with the default template applied

**"QuickLaunch Obsidian here (choose template)..."**
1. Right-click ON any folder, or right-click IN a folder
2. Click "QuickLaunch Obsidian here (choose template)..."
3. If multiple templates exist, a chooser dialog appears
4. Select a template and click OK

### .md File Association (Opt-In)

If enabled during installation:
1. Double-click any `.md` file
2. The file's parent folder is registered and opened as an Obsidian vault

This adds ObsidianQuickLaunch to the "Open with" list for `.md` files — it does not replace your default `.md` editor.

## Templates

### How Templates Work

Templates are plain folder structures that get copied into new vaults. They can contain:
- `.obsidian/` folder with app settings, plugin configs, themes
- Any starter files or folder structure you want

Templates are applied **non-destructively** — they never overwrite existing files. If a vault already has a `.obsidian/app.json`, the template's version is skipped.

### Template Locations

**Bundled templates** ship with the installer:
- `default` — Minimal `.obsidian/` folder
- `zettelkasten` — Daily Notes and Templates folders
- `project-docs` — docs folder with starter README

**User templates** live in `%APPDATA%\ObsidianQuickLaunch\templates\`. Create a new folder there with your desired vault structure to add a custom template. User templates override bundled templates of the same name.

### Creating Custom Templates

1. Set up an Obsidian vault the way you want it (plugins, themes, folders, starter files)
2. Copy the vault folder to `%APPDATA%\ObsidianQuickLaunch\templates\YourTemplateName\`
3. The template will appear in the template chooser dialog

## Installation

### MSI Installer (Recommended)

1. Download `ObsidianQuickLaunch-{version}.msi`
2. Run the installer (requires Administrator)
3. Choose **Typical** for standard install, or **Custom** to enable .md file association
4. Done! Context menu entries are available immediately

**Note:** "Complete" install includes all features including .md file association. Use "Typical" if you don't want .md association.

### Manual Installation

1. **Open PowerShell as Administrator**
   - Right-click Start menu → "Terminal (Admin)" or "PowerShell (Admin)"

2. **Navigate to the scripts directory**
   ```powershell
   cd "path\to\ObsidianQuickLaunch\src\scripts"
   ```

3. **Run the installer**
   ```powershell
   .\install-context-menu.ps1
   ```

4. **Done!** The context menu is now available in Windows Explorer

### Uninstallation

**MSI:** Use Add/Remove Programs or run `msiexec /x {ProductCode}`

**Manual:**
```powershell
.\uninstall-context-menu.ps1
```
(Run as Administrator)

## Known Issues

### Homepage Plugin Conflict

If you use the "homepage" Obsidian plugin, it may interfere with workspace restoration.

**Problem**: Plugin opens homepage and replaces all tabs on startup.

**Solution**: Modify the plugin settings in `.obsidian/plugins/homepage/data.json`:

```json
{
  "openOnStartup": false,
  "openMode": "Keep open notes"
}
```

**Option 1** (Recommended): Set `"openOnStartup": false` to disable automatic homepage opening.

**Option 2**: Set `"openMode": "Keep open notes"` to keep the homepage but also restore your previous tabs.

## How It Works

1. **Vault Registration**: Obsidian tracks vaults in `%APPDATA%\obsidian\obsidian.json`
2. **Template Application**: Template files are copied non-destructively into the vault folder
3. **Workspace State**: Each vault stores its state in `.obsidian\workspace.json`
4. **Opening Vaults**: Uses the `obsidian://open?path=...` URI protocol
5. **Critical Limitation**: Obsidian must be closed before modifying `obsidian.json`, or changes will be overwritten

## Technical Details

- Obsidian does NOT hot-reload vault list changes
- Config modifications while Obsidian is running will be lost when Obsidian closes
- The script must close Obsidian, modify config, then reopen
- Each vault's workspace is automatically restored by Obsidian
- Templates are resolved in order: user templates → bundled templates

## Requirements

- Windows 10/11
- Obsidian installed
- PowerShell 5.1 or later

## Project Structure

```
ObsidianQuickLaunch/
├── src/
│   ├── scripts/
│   │   ├── register-vault-final.ps1  - Main vault registration + template
│   │   ├── choose-template.ps1       - Template chooser dialog
│   │   ├── open-md-file.ps1          - .md file handler
│   │   ├── install-context-menu.ps1  - Installer (run as Admin)
│   │   └── uninstall-context-menu.ps1 - Uninstaller (run as Admin)
│   └── templates/
│       ├── default/                  - Default template
│       ├── zettelkasten/             - Zettelkasten template
│       └── project-docs/            - Project documentation template
├── tools/
│   ├── build/                       - Build scripts
│   └── packaging/                   - WiX installer packaging
├── tests/                           - Development test scripts
└── README.md
```

## Roadmap

See [TODO.md](TODO.md) for the complete project roadmap.

**Phase 1: ✅ COMPLETE** — Core vault registration and context menu
**Phase 2: ✅ COMPLETE** — Templates, chooser, .md association

**Next:** Documentation, CI/CD, distribution (Chocolatey, WinGet, Scoop)

## License

[MIT License](../LICENSE.md) - Copyright (c) 2025 Scott Kirvan

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

Issues and pull requests are welcome!
