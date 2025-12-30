# ObsidianQuickLaunch - Claude Code Project Rules

## Project Overview
ObsidianQuickLaunch is a Windows utility that adds Windows Explorer context menu integration for quickly opening folders as Obsidian vaults. Right-click any folder (or within a folder) to register and open it as an Obsidian vault.

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

### CI/CD & Testing (Future)
- Implement unit tests as project matures
- Use GitHub Actions for build automation
- Integrate testing into release cycle
- PowerShell Pester tests for script validation

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
- [x] Installer and uninstaller scripts
- [x] Auto-detect Obsidian installation path from registry
- [x] Use Obsidian's icon in context menu

### Phase 2: Template System (TODO)
- [ ] Add template vault support
- [ ] Allow users to apply pre-configured vault templates
- [ ] Templates should include: plugins, settings, folder structure, template notes

## Technical Architecture

### Key Files
- `src/scripts/register-vault-final.ps1` - Main vault registration script
- `src/scripts/install-context-menu.ps1` - Windows registry installer (requires Admin)
- `src/scripts/uninstall-context-menu.ps1` - Removes context menu (requires Admin)
- `tests/` - Test scripts for development

### How It Works
1. **Vault Registration**: Obsidian tracks vaults in `%APPDATA%\obsidian\obsidian.json`
2. **Workspace State**: Each vault stores its state in `.obsidian\workspace.json`
3. **Opening Vaults**: Uses `obsidian://open?path=...` URI protocol
4. **Critical Limitation**: Obsidian must be closed before modifying `obsidian.json`, or changes will be overwritten

### Registry Integration
- Obsidian path detected from: `HKEY_CLASSES_ROOT\obsidian\shell\open\command`
- Context menu entries in: `HKEY_CLASSES_ROOT\Directory\shell\ObsidianQuickLaunch`
- Background menu in: `HKEY_CLASSES_ROOT\Directory\Background\shell\ObsidianQuickLaunch`

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
- Package as executable for easier distribution
- Template vault system with pre-configured settings
- Support for different Obsidian installation methods (portable, etc.)
- Option to open vault without closing other vaults (if possible)

## Development Status
**Current State**: Phase 1 complete and functional. Context menu integration working with icon support.
**Next Steps**: Test thoroughly, prepare for open source release, consider Phase 2 template system.

## Important Notes for Claude Code
- Always read files before editing them
- When modifying PowerShell scripts, watch for encoding issues (UTF-8 without BOM)
- Test changes don't break the context menu functionality
- Keep the README.md in sync with actual functionality
- Preserve the user's custom Obsidian installation path detection
