# ObsidianQuickLaunch - Claude Code Project Rules

## Project Overview
ObsidianQuickLaunch is a Windows utility that adds Windows Explorer context menu integration for quickly opening folders as Obsidian vaults. Right-click any folder (or within a folder) to register and open it as an Obsidian vault, with optional template application and .md file association.

## Repository Structure & Documentation Guidelines

This project uses Scott Kirvan's GitHub template structure:
- **./README.md**: Repository documentation with minimal user-facing content (directs users to ./notes/)
- **./notes/README.md**: Comprehensive user documentation, installation, usage guides
- **./notes/CHANGELOG.md**: Maintained by Release-Please
- **./notes/TODO.md**: Project roadmap and task tracking
- **./notes/VERSION.md**: Current version (maintained by Release-Please)

## Development Workflow

### Code Check-ins
- **All code check-ins are performed by the user (Scott)**
- Claude Code assists with code development but does not commit changes
- Use conventional commit messages for Release-Please automation

### Release Management
- Uses **Release-Please** for automated versioning and changelog generation
- Conventional Commits format (feat:, fix:, feat!:, etc.)
- Version managed in `.github/release-please/.release-please-manifest.json`
- CHANGELOG maintained automatically in `notes/CHANGELOG.md`

### Build & Packaging
- **Build System**: WiX Toolset 3.x-based MSI installer
- **Build Pattern**: Follows Microsoft PowerShell project's approach (PowerShell scripts generate WiX installers)
- **Build Script**: `tools/build/build.bat` (wrapper) and `tools/build/Build-Installer.ps1` orchestrate the build process
- **Packaging Module**: `tools/packaging/packaging.psm1` contains WiX build functions
- **Output**: MSI installer in `dist/ObsidianQuickLaunch-{version}.msi`

### CI/CD & Testing (Future)
- Implement unit tests as project matures
- Use GitHub Actions for automated MSI builds on releases
- Integrate testing into release cycle
- PowerShell Pester tests for script validation
- Automated installer testing

### Documentation Responsibilities
**Claude Code will:**
- Create, maintain, and update all project documentation
- Keep ./README.md focused on repository overview
- Maintain comprehensive user docs in ./notes/README.md
- Update documentation as features are added/changed
- Keep .claude/CLAUDE.md file current with project directives
- Maintain notes/DEV_NOTES.md with technical decisions and rationale

## Project Goals

### Phase 1: Core Vault Opening (COMPLETE ✅)
- [x] Register folders as Obsidian vaults in `%APPDATA%\obsidian\obsidian.json`
- [x] Open vaults using the `obsidian://` URI protocol
- [x] Preserve all currently open vaults when opening new ones
- [x] Restore workspace state (open notes, tabs, sidebar layout)
- [x] Windows Explorer context menu integration (right-click on folder AND in folder background)
- [x] Manual installer and uninstaller PowerShell scripts
- [x] Auto-detect Obsidian installation path from registry
- [x] Use Obsidian's icon in context menu
- [x] WiX-based MSI installer for automated installation/uninstallation

### Phase 2: Template System & File Association (COMPLETE ✅)
- [x] **Default template**: Plain folder copied non-destructively on vault creation
  - Templates stored in `%APPDATA%\ObsidianQuickLaunch\templates\` (user) and bundled with installer
  - File-level existence checks — never overwrite existing files
  - Default template applied silently on every context menu action
- [x] **Template chooser**: Always-visible second context menu entry with dialog
  - "QuickLaunch Obsidian here (choose template)..." entry (always visible, no Shift required)
  - Simple Windows Forms listbox dialog (only shown if >1 template exists)
  - 3 bundled example templates (default, zettelkasten, project-docs)
- [x] **.md file association** (opt-in): Double-click .md opens parent folder as vault
  - Opt-in feature in MSI installer (Level=2, excluded from Typical, included in Complete)
  - `open-md-file.ps1` script wrapping vault registration logic

## Technical Architecture

### Key Files

**Source Scripts:**
- `src/scripts/register-vault-final.ps1` - Main vault registration + template application
- `src/scripts/choose-template.ps1` - Template chooser dialog (Windows Forms)
- `src/scripts/open-md-file.ps1` - .md file handler (opens parent folder as vault)
- `src/scripts/install-context-menu.ps1` - Windows registry installer (requires Admin)
- `src/scripts/uninstall-context-menu.ps1` - Removes context menu (requires Admin)

**Templates:**
- `src/templates/default/` - Minimal default template (`.obsidian/app.json`)
- `src/templates/zettelkasten/` - Zettelkasten template (Daily Notes, Templates folders)
- `src/templates/project-docs/` - Project docs template (docs folder, starter README)

**Build System:**
- `tools/build/build.bat` - Build wrapper (handles PowerShell execution policy)
- `tools/build/Build-Installer.ps1` - Main build script for creating MSI installer
- `tools/packaging/packaging.psm1` - PowerShell module for WiX build automation
- `tools/packaging/wix/Product.wxs` - WiX source file defining installer structure
- `notes/BUILD.md` - Build system documentation

**Testing:**
- `tests/test-template-application.ps1` - Template copy logic tests (13 tests)
- `tests/test-template-chooser.ps1` - Template chooser dialog tests (9 tests)
- `tests/test-md-file-open.ps1` - .md file handler tests (7 tests)
- `tests/` - Additional test scripts for development

### How It Works
1. **Vault Registration**: Obsidian tracks vaults in `%APPDATA%\obsidian\obsidian.json`
2. **Template Application**: Template files copied non-destructively (file-level check, never overwrite)
3. **Template Resolution**: User templates (`%APPDATA%\ObsidianQuickLaunch\templates\`) override bundled templates
4. **Workspace State**: Each vault stores its state in `.obsidian\workspace.json`
5. **Opening Vaults**: Uses `obsidian://open?path=...` URI protocol
6. **Critical Limitation**: Obsidian must be closed before modifying `obsidian.json`, or changes will be overwritten

### Registry Integration
- Obsidian path detected from: `HKEY_CLASSES_ROOT\obsidian\shell\open\command`
- Context menu entries in: `HKEY_CLASSES_ROOT\Directory\shell\ObsidianQuickLaunch`
- Background menu in: `HKEY_CLASSES_ROOT\Directory\Background\shell\ObsidianQuickLaunch`
- Template chooser: `HKEY_CLASSES_ROOT\Directory\shell\ObsidianQuickLaunchTemplate` (always visible)
- Template chooser background: `HKEY_CLASSES_ROOT\Directory\Background\shell\ObsidianQuickLaunchTemplate`
- .md file association (opt-in): `HKEY_CLASSES_ROOT\.md\OpenWithProgIds\ObsidianQuickLaunch.md`
- MSI icon detection: VBScript custom action parses OBSIDIANPATH → OBSIDIANICON property

### WiX Installer Features
- **MainFeature** (Level=1): Core scripts, context menus, templates, start menu shortcuts
- **MdFileAssociation** (Level=2): .md file association (opt-in in Typical, included in Complete)
- **UI**: WixUI_Mondo (Typical/Custom/Complete with feature selection and directory browsing)
- **ConfigurableDirectory**: INSTALLFOLDER on MainFeature enables Browse in Custom dialog

## Known Issues & Design Decisions

### Homepage Plugin Conflict
The "homepage" Obsidian plugin can interfere with workspace restoration if configured with:
- `"openOnStartup": true`
- `"openMode": "Replace all open notes"`

**Solution**: Documented in README and script comments. Users should set `"openOnStartup": false` or `"openMode": "Keep open notes"`.

### Obsidian Must Close for Registration
- Obsidian doesn't hot-reload its vault list from `obsidian.json`
- If Obsidian is running, it will overwrite config changes when it exits
- **Solution**: Script closes Obsidian, modifies config, then reopens all previously open vaults

### Vault Opening Order
- Previously open vaults open first
- New vault opens LAST (appears on top/in focus)

### Windows 11 Context Menu
- Windows 11's modern context menu does NOT support `Extended` registry entries
- Template chooser entries are always visible (not hidden behind Shift+right-click)
- Both entries have distinct labels for discoverability

### .md File Association with WixUI_Mondo
- Level=2 means: excluded from Typical install, included in Complete install
- "Complete" = install everything (standard WiX behavior)
- "Reset" in Custom dialog resets to install type defaults
- Users wanting Typical without .md should NOT use Complete install

## Development Guidelines

### PowerShell Style
- Use proper error handling with try/catch
- Provide verbose output with color coding (Green=success, Yellow=warning, Red=error, Gray=info)
- Always backup `obsidian.json` before modifying (with timestamps)
- Use UTF-8 encoding without BOM for JSON files
- Check for admin privileges when required

### Registry Keys
- Use full registry paths: `Registry::HKEY_CLASSES_ROOT\...`
- Extract Obsidian path from registry instead of hardcoding
- Fallback to common installation paths if registry lookup fails

### Testing
- Test scripts are in `tests/` folder
- Keep production scripts separate in `src/scripts/`
- Always test with Obsidian both running and not running
- 29 automated tests across 3 test files

## User's Environment
- Windows 10/11
- Obsidian installed at: `D:\bin\Obsidian\Obsidian.exe`
- Multiple vaults in use simultaneously
- Power user workflow - creates many small vaults for different projects

## Open Source Considerations
- This will be an open source project
- License: TBD (likely MIT)
- Target audience: Obsidian users who create many small vaults
- Should work with any Obsidian installation location

## Future Features (Wishlist)
- Add custom icon option
- ~~Package as executable for easier distribution~~ ✅ Done (MSI installer)
- ~~Template vault system with pre-configured settings~~ ✅ Done (Phase 2)
- Support for different Obsidian installation methods (portable, etc.)
- Option to open vault without closing other vaults (if possible)
- Code signing for MSI installer (requires certificate)
- Chocolatey package for easy installation
- Update license agreement in installer (currently placeholder text)

## Development Status
**Current State**: Phase 1 and Phase 2 complete. Context menu integration working with icon support, template system, template chooser, and .md file association. WiX-based MSI installer with feature selection (WixUI_Mondo). All 29 automated tests passing.
**Next Steps**: User testing of the fresh MSI build. Then: documentation polish, CI/CD pipeline, distribution packaging (Chocolatey, WinGet, Scoop). See `notes/DEV_NOTES.md` for full technical details and `notes/TODO.md` for task breakdown.

## Important Notes for Claude Code
- Always read files before editing them
- When modifying PowerShell scripts, watch for encoding issues (UTF-8 without BOM)
- Test changes don't break the context menu functionality
- Keep the README.md in sync with actual functionality
- Preserve the user's custom Obsidian installation path detection
- Follow Microsoft PowerShell's build patterns for WiX installer modifications
- Build artifacts (dist/, staging/) are gitignored - never commit them
- When running PowerShell from bash, `$` variables get eaten by bash - use script files or careful escaping
- Windows 11 does not support `Extended` registry entries in its modern context menu
