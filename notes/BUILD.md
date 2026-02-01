# Building the ObsidianQuickLaunch Installer

This document describes how to build the MSI installer for ObsidianQuickLaunch using WiX Toolset 3.x.

## Prerequisites

### Required Software

1. **WiX Toolset v3.x**
   - Download from: https://wixtoolset.org/releases/
   - Recommended version: v3.14
   - Must be installed (not portable) for the build scripts to find it

2. **PowerShell 5.1 or later**
   - Included with Windows 10/11
   - Verify version: `$PSVersionTable.PSVersion`

3. **Windows Operating System**
   - Windows 10 or later
   - Administrator privileges may be required for installation testing

## Build System Architecture

The build system follows the Microsoft PowerShell project's pattern of using PowerShell scripts to dynamically generate WiX installers.

### Directory Structure

```
ObsidianQuickLaunch/
├── tools/
│   ├── build/
│   │   ├── build.bat            # Build wrapper (handles PowerShell permissions)
│   │   └── Build-Installer.ps1  # Main build script
│   └── packaging/
│       ├── packaging.psd1       # PowerShell module manifest
│       ├── packaging.psm1       # Packaging functions
│       └── wix/
│           └── Product.wxs      # WiX source file
├── src/
│   └── scripts/                 # Scripts packaged in installer
│       ├── register-vault-final.ps1
│       ├── install-context-menu.ps1
│       └── uninstall-context-menu.ps1
└── dist/                        # Build output (created)
    └── ObsidianQuickLaunch-{version}.msi
```

## Building the Installer

### Quick Start

```cmd
# Rebuild (clean + build) - Most common, recommended
.\tools\build\build.bat rebuild

# Build only (fails if MSI already exists)
.\tools\build\build.bat build

# Clean only (remove artifacts without building)
.\tools\build\build.bat clean

# Rebuild with specific version
.\tools\build\build.bat rebuild 1.2.3

# Default action is rebuild if no action specified
.\tools\build\build.bat
```

Note: `build.bat` wraps `Build-Installer.ps1` with proper PowerShell execution policy settings to avoid permission issues.

### Build Actions

- **`rebuild`** - Clean and build (default, recommended for most cases)
- **`build`** - Build only, fails if MSI already exists (safety check)
- **`clean`** - Remove build artifacts without building

### Build Process

The `tools/build/Build-Installer.ps1` script performs these steps:

1. **Version Detection**
   - Reads version from `.github/release-please/.release-please-manifest.json`
   - Or accepts version via `-Version` parameter

2. **Staging**
   - Creates `tools/packaging/staging/` directory
   - Copies PowerShell scripts from `src/scripts/`
   - Includes documentation files

3. **WiX Compilation**
   - Uses `heat.exe` to harvest files (generate file manifest)
   - Uses `candle.exe` to compile `.wxs` files to `.wixobj`
   - Uses `light.exe` to link objects into final MSI

4. **Output**
   - Creates MSI in `dist/ObsidianQuickLaunch-{version}.msi`
   - Creates debug symbols in `dist/ObsidianQuickLaunch-{version}.wixpdb`

## Packaging Module (`tools/packaging/packaging.psm1`)

### Functions

#### `Get-WixPath`
Locates WiX Toolset installation on the system.

```powershell
$wixPath = Get-WixPath
# Returns: @{ wixCandleExePath, wixLightExePath, wixHeatExePath, wixPath }
```

#### `New-MSIPackage`
Main function to build the MSI installer.

```powershell
New-MSIPackage -ProductVersion "1.0.0" -ProductSourcePath ".\staging" -OutputPath ".\dist"
```

Parameters:
- `ProductVersion`: Version in format `Major.Minor.Patch`
- `ProductSourcePath`: Directory containing files to package
- `ProductWxsPath`: Path to Product.wxs file (defaults to `tools/packaging/wix/Product.wxs`)
- `OutputPath`: Where to write the MSI (defaults to `dist/`)
- `Force`: Overwrite existing MSI

#### `Start-MsiBuild`
Compiles WiX source files into an MSI.

#### `New-MsiArgsArray`
Converts hashtable to WiX preprocessor arguments.

## WiX Source File (`tools/packaging/wix/Product.wxs`)

The Product.wxs file defines:

### Product Information
- Product Name: ObsidianQuickLaunch
- Manufacturer: Scott Kirvan
- UpgradeCode: `A7F8B9C0-1D2E-4F5A-8B7C-9D6E5F4A3B2C` (must remain constant)

### Features
1. **ProductFiles**: PowerShell scripts and documentation
2. **ContextMenuRegistration**: Windows Explorer registry entries
3. **StartMenuShortcuts**: Uninstall and manual install/uninstall shortcuts

### Registry Configuration

The installer creates these registry keys:

#### Context Menu (Right-click ON folder)
```
HKCR\Directory\shell\ObsidianQuickLaunch
├── (Default) = "Open as Obsidian Vault"
├── Icon = [Obsidian.exe path from registry]
└── command\
    └── (Default) = powershell.exe -NoProfile -WindowStyle Hidden ...
```

#### Context Menu (Right-click IN folder)
```
HKCR\Directory\Background\shell\ObsidianQuickLaunch
├── (Default) = "Open as Obsidian Vault"
├── Icon = [Obsidian.exe path from registry]
└── command\
    └── (Default) = powershell.exe -NoProfile -WindowStyle Hidden ...
```

#### Installation Tracking
```
HKLM\Software\Scott Kirvan\ObsidianQuickLaunch
├── InstallPath = [Installation directory]
└── Version = [Product version]
```

## Testing the Installer

### Installation

```powershell
# Install MSI (requires elevation)
msiexec /i "dist\ObsidianQuickLaunch-1.0.0.msi"

# Silent install
msiexec /i "dist\ObsidianQuickLaunch-1.0.0.msi" /quiet

# Install with logging
msiexec /i "dist\ObsidianQuickLaunch-1.0.0.msi" /l*v install.log
```

### Verification

1. Check **Add/Remove Programs** for "ObsidianQuickLaunch"
2. Verify installation directory: `C:\Program Files\ObsidianQuickLaunch\`
3. Right-click any folder → Should see "Open as Obsidian Vault"
4. Check Start Menu → ObsidianQuickLaunch folder

### Uninstallation

```powershell
# Uninstall via Add/Remove Programs
# OR
msiexec /x "dist\ObsidianQuickLaunch-1.0.0.msi"
```

Uninstallation removes:
- All installed files
- Registry entries (context menus)
- Start menu shortcuts

## Troubleshooting

### "WiX Toolset not found"
- Install WiX Toolset v3.x from https://wixtoolset.org/releases/
- Ensure installation path is added to system PATH
- Restart PowerShell after installation

### "Package already exists"
- Use `-Force` parameter to overwrite
- Or manually delete files in `dist/` folder

### "candle.exe failed" or "light.exe failed"
- Check Product.wxs syntax
- Review error messages for specific WiX errors
- Ensure all referenced files exist in staging directory

### Registry entries not created
- Ensure installer ran with administrator privileges
- Check Windows Event Viewer for MSI errors
- Review install log: `msiexec /i package.msi /l*v install.log`

## Advanced Usage

### Customizing the Build

#### Modify Files to Package
Edit `tools/build/Build-Installer.ps1` around line 120:

```powershell
$sourceScripts = @(
    "register-vault-final.ps1",
    "install-context-menu.ps1",
    "uninstall-context-menu.ps1",
    "your-new-script.ps1"  # Add here
)
```

#### Change Installation Directory
Edit `Product.wxs`:

```xml
<Directory Id="INSTALLFOLDER" Name="$(var.ProductName)">
```

#### Modify Context Menu Text
Edit `Product.wxs`:

```xml
<RegistryValue Type="string" Name="(Default)" Value="Your Custom Text" />
```

### Creating a Bundle (EXE Installer)
WiX v3 supports creating EXE bundles that can include prerequisites. This would require:
1. Creating a `Bundle.wxs` file
2. Using `burn` bootstrapper
3. Potentially bundling .NET runtime or other dependencies

(Not currently implemented)

## CI/CD Integration

The build system is designed for GitHub Actions integration:

```yaml
- name: Build Installer
  run: .\tools\build\build.bat rebuild
  shell: cmd

- name: Upload MSI
  uses: actions/upload-artifact@v3
  with:
    name: installer
    path: dist/*.msi
```

See `.github/workflows/` for implementation examples.

## References

- [WiX Toolset Documentation](https://wixtoolset.org/documentation/)
- [WiX Tutorial](https://www.firegiant.com/wix/tutorial/)
- [Microsoft PowerShell Packaging](https://github.com/PowerShell/PowerShell/tree/master/tools/packaging)
- [Windows Installer (MSI) Guidelines](https://docs.microsoft.com/windows/win32/msi/windows-installer-portal)

## License

The build system follows the same license as ObsidianQuickLaunch (see LICENSE.md).
