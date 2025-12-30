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

## Phase 2: Template System 🚧 PLANNED

### TODO
- [ ] Design template vault structure
- [ ] Template vault configuration format
- [ ] Apply template on vault creation
- [ ] Built-in template examples:
  - [ ] Basic (minimal setup)
  - [ ] Zettelkasten
  - [ ] Personal Knowledge Management (PKM)
  - [ ] Project Documentation
- [ ] User-defined template support
- [ ] Template selection UI/dialog

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

### TODO
- [ ] Create installer package (MSI/EXE)
- [ ] Code signing certificate
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

**Last Updated:** 2025-12-16
**Current Phase:** Phase 1 Complete, Phase 2 Planning
