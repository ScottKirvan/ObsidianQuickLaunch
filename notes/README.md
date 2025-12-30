# ObsidianQuickLaunch

Windows context menu integration for quickly opening folders as Obsidian vaults.

## Features

- Right-click any folder in Windows Explorer to open it as an Obsidian vault
- Automatically registers new vaults with Obsidian
- Preserves all currently open vaults and workspaces when opening new vaults
- Restores previous workspace state (open notes, tabs, sidebar layout)

## Current Status

**Phase 1: ✅ COMPLETE**
- ✅ Register vaults in Obsidian's config
- ✅ Open vaults using the `obsidian://` URI protocol
- ✅ Preserve open vaults when opening new ones
- ✅ Workspace restoration (tabs, notes, layout)
- ✅ Windows Explorer context menu integration
- ✅ Obsidian icon in context menu
- ✅ Auto-detect Obsidian installation

**Phase 2: 🚧 PLANNED**
- Template vault system
- Packaging and distribution
- CI/CD and testing

## Usage

### Manual Usage

```powershell
.\src\scripts\register-vault-final.ps1 "C:\path\to\folder"
```

This will:
1. Close Obsidian (required to safely modify config)
2. Register the folder as an Obsidian vault
3. Reopen all previously open vaults
4. Open the new vault

### Context Menu (Installed)

After running the installer:
1. Right-click ON any folder, OR
2. Right-click IN a folder (empty space)
3. Click "Open as Obsidian Vault"

See Installation section below for setup instructions.

## Installation

### Context Menu Installation

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

To remove the context menu:
```powershell
.\uninstall-context-menu.ps1
```
(Also run as Administrator)

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
2. **Workspace State**: Each vault stores its state in `.obsidian\workspace.json`
3. **Opening Vaults**: Uses the `obsidian://open?path=...` URI protocol
4. **Critical Limitation**: Obsidian must be closed before modifying `obsidian.json`, or changes will be overwritten

## Technical Details

- Obsidian does NOT hot-reload vault list changes
- Config modifications while Obsidian is running will be lost when Obsidian closes
- The script must close Obsidian, modify config, then reopen
- Each vault's workspace is automatically restored by Obsidian

## Requirements

- Windows 10/11
- Obsidian installed
- PowerShell 5.1 or later

## Project Structure

```
ObsidianQuickLaunch/
├── src/
│   └── scripts/
│       ├── register-vault-final.ps1  - Main vault registration script
│       ├── install-context-menu.ps1   - Installer (run as Admin)
│       └── uninstall-context-menu.ps1 - Uninstaller (run as Admin)
├── tests/
│   ├── test-vault-opening.ps1        - Test URI protocol methods
│   ├── test-multi-window.ps1         - Test multi-window behavior
│   ├── test-hot-reload.ps1           - Test config hot-reloading
│   └── test-direct-launch.ps1        - Test direct executable launch
└── README.md
```

## Roadmap

See [TODO.md](TODO.md) for the complete project roadmap.

**Phase 1: ✅ COMPLETE**
- Core vault registration and opening
- Windows Explorer context menu integration
- Obsidian icon support

**Phase 2: 🚧 PLANNED**
- Template vault system
- Packaging and distribution
- CI/CD and automated testing

## License

[MIT License](../LICENSE.md) - Copyright (c) 2025 Scott Kirvan

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

Issues and pull requests are welcome!
