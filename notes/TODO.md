# ObsidianQuickLaunch - Project Roadmap

## Phase 1: Core Functionality ✅ COMPLETE

### Done ✓
- [x] Register folders as Obsidian vaults in obsidian.json
- [x] Open vaults using obsidian:// URI protocol
- [x] Preserve currently open vaults when opening new ones
- [x] Restore workspace state (tabs, notes, layout)
- [x] Windows Explorer context menu integration
  - [x] Right-click ON folder
  - [x] Right-click IN folder (background)
- [x] Context menu installer (PowerShell script, requires Admin)
- [x] Context menu uninstaller
- [x] Auto-detect Obsidian installation from registry
- [x] Use Obsidian icon in context menu
- [x] Document Homepage plugin conflict workaround
- [x] Handle case when Obsidian is not running
- [x] Open new vault last (on top) when multiple vaults open
- [x] Project structure organization (src/, tests/, notes/)
- [x] WiX Toolset 3.x MSI installer
  - [x] PowerShell build system following Microsoft PowerShell project patterns
  - [x] Dynamic file harvesting with heat.exe
  - [x] Automatic registry configuration
  - [x] Start Menu shortcuts for uninstall and manual scripts
  - [x] Clean/Build/Rebuild actions
  - [x] Version auto-detection from release-please manifest

## Phase 2: Template System & File Association ✅ COMPLETE

Design details in [DEV_NOTES.md](DEV_NOTES.md#session-phase-2-design---templates--file-association-feb-13-2026).

### 2a. Default Template Support ✅
- [x] Design template system (plain folders, non-destructive copy)
- [x] Create template directory structure (`%APPDATA%\ObsidianQuickLaunch\templates\`)
- [x] Implement non-destructive file copy logic in `register-vault-final.ps1`
  - File-level existence checks (never overwrite existing files)
  - Copy template contents into target vault folder
- [x] Create default template (bundled in installer)
  - Basic `.obsidian/` with sensible defaults
- [x] Update MSI installer to deploy default template to templates directory
- [x] Test: new vault creation applies default template (13 tests passing)
- [x] Test: existing vault files are never overwritten

### 2b. Template Chooser ✅
- [x] Add template chooser context menu entries (always visible, no Extended/Shift requirement)
  - `HKCR\Directory\shell\ObsidianQuickLaunchTemplate`
  - `HKCR\Directory\Background\shell\ObsidianQuickLaunchTemplate`
- [x] Create template chooser dialog (Windows Forms listbox, OK/Cancel)
- [x] Pass selected template name to `register-vault-final.ps1`
- [x] Update MSI installer with new registry entries
- [x] Create bundled example templates:
  - [x] Zettelkasten (Daily Notes, Templates folders)
  - [x] Project Documentation (docs folder, starter README)
- [x] Test: template chooser dialog (9 tests passing)

### 2c. .md File Association (Opt-In) ✅
- [x] Create `open-md-file.ps1` script (wraps vault registration for parent folder)
- [x] Add opt-in feature to MSI installer (Level=2, excluded from Typical, included in Complete)
- [x] Register `.md` file association via WiX (`HKCR\.md\OpenWithProgIds`)
- [x] Test: double-click .md opens parent folder as vault in Obsidian (7 tests passing)
- [x] Test: does not interfere with other .md editors when not opted in

### Bug Fixes (Feb 14, 2026) ✅
- [x] Change context menu text to "QuickLaunch Obsidian here"
- [x] Add Obsidian icon to MSI-installed context menu entries (VBScript custom action)
- [x] Remove `Extended` registry entries (Windows 11 incompatible) — template chooser always visible
- [x] Fix template path normalization for non-destructive copy
- [x] Document .md feature Level=2 behavior with WixUI_Mondo Complete install

## Documentation & Quality

### In Progress
- [ ] Write comprehensive user guide
- [ ] Add screenshots/GIFs to documentation
- [ ] Create video walkthrough

### TODO
- [ ] Unit tests (PowerShell Pester framework)
- [ ] CI/CD pipeline with GitHub Actions
- [ ] Automated testing in pull requests
- [ ] Code coverage reporting
- [ ] Performance benchmarks

## Distribution & Packaging

### Done ✓
- [x] Create MSI installer package (WiX 3.x)

### TODO
- [ ] Update license agreement in installer (currently placeholder text)
- [ ] Code signing certificate for MSI
- [ ] GitHub Actions workflow for automated builds
- [ ] Chocolatey package
- [ ] WinGet package manifest
- [ ] Scoop manifest
- [ ] Automatic update mechanism

## Future Enhancements

### Nice to Have
- [ ] Custom icon option for context menu
- [ ] Multiple template support per vault
- [ ] Import existing vault as template
- [ ] Vault metadata (tags, categories, descriptions)
- [ ] Quick vault search/launcher
- [ ] Batch vault operations
- [ ] Vault cloning/duplication
- [ ] Portable mode (no registry modification)
- [ ] Support for Obsidian portable installations
- [ ] Multi-language support
- [ ] Settings/configuration UI

## Known Issues to Address

### TODO
- [ ] Test with various Obsidian installation locations
- [ ] Handle edge case: Obsidian installed but not configured
- [ ] Better error messages for common failures
- [ ] Graceful handling of insufficient permissions
- [ ] Support for long path names (>260 characters)

## Research & Investigation

### To Explore
- [ ] Alternative vault opening methods that don't require closing Obsidian
- [ ] Integration with Obsidian's plugin API
- [ ] Vault synchronization with cloud services
- [ ] Workspace templates (not just vault templates)

---

**Last Updated:** 2026-02-14
**Current Phase:** Phase 2 Complete — Testing & Polish
