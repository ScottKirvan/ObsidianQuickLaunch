# ObsidianQuickLaunch

**Windows Explorer context menu integration for Obsidian vault management**

[![License](https://img.shields.io/github/license/ScottKirvan/ObsidianQuickLaunch.svg)](LICENSE.md)
[![Issues](https://img.shields.io/github/issues/ScottKirvan/ObsidianQuickLaunch)](https://github.com/ScottKirvan/ObsidianQuickLaunch/issues)
[![Stars](https://img.shields.io/github/stars/ScottKirvan/ObsidianQuickLaunch)](https://github.com/ScottKirvan/ObsidianQuickLaunch/stargazers)

## Overview

ObsidianQuickLaunch adds Windows Explorer context menu entries that allow you to quickly open any folder as an Obsidian vault. Right-click on a folder or within a folder and select "Open as Obsidian Vault" to instantly register and launch it in Obsidian.

**Key Features:**
- One-click vault creation and opening from Windows Explorer
- Preserves all currently open vaults and workspaces
- Automatic Obsidian installation detection
- Obsidian icon in context menu

## Quick Start

For complete installation and usage instructions, see **[User Documentation](notes/README.md)**.

**TL;DR:**
1. Run `.\src\scripts\install-context-menu.ps1` as Administrator
2. Right-click any folder → "Open as Obsidian Vault"

## Repository Structure

```
ObsidianQuickLaunch/
├── src/scripts/          # Production PowerShell scripts
├── tests/                # Development test scripts
├── notes/                # User documentation and project notes
├── .github/              # GitHub workflows and templates
└── README.md             # This file
```

## Development

This project uses:
- **PowerShell scripts** for Windows integration
- **Release-Please** for automated versioning
- **Conventional Commits** for changelog generation
- **GitHub Actions** for CI/CD (planned)

### Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Testing

Test scripts are located in `/tests/` directory for development use.

## Project Status

**Current Version:** See [VERSION.md](notes/VERSION.md)
**Phase 1:** ✅ Complete - Core functionality and context menu integration
**Phase 2:** 🚧 Planned - Template vault system

See [CHANGELOG.md](notes/CHANGELOG.md) for release history.

## Documentation

- **[User Guide](notes/README.md)** - Installation, usage, and troubleshooting
- **[TODO](notes/TODO.md)** - Project roadmap
- **[CHANGELOG](notes/CHANGELOG.md)** - Release history

## License

[MIT License](LICENSE.md) - Copyright (c) 2025 Scott Kirvan

## Contact

- **Issues**: [GitHub Issues](https://github.com/ScottKirvan/ObsidianQuickLaunch/issues)
- **LinkedIn**: [Scott Kirvan](https://www.linkedin.com/in/scottkirvan/)
- **Discord**: [cptvideo](https://discord.gg/TSKHvVFYxB)

---

Project Link: [github.com/ScottKirvan/ObsidianQuickLaunch](https://github.com/ScottKirvan/ObsidianQuickLaunch)
