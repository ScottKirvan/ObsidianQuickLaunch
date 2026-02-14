## Installer
- [x] Reset key enables the installation of the .md file association feature, which should be opt-in by default.
  - **Status:** This is standard WixUI_Mondo behavior. Level=2 means excluded from Typical but included in Complete. "Reset" resets to the install type defaults. Added clarifying description. Use Typical install to exclude .md association.

## Context Menu
- [x] Change the context menu to "QuickLaunch Obsidian here"
  - **Status:** Fixed in Product.wxs and install-context-menu.ps1. Template chooser is "QuickLaunch Obsidian here (choose template)..."
- [x] The context menu is missing its icon, which should be the Obsidian icon.
  - **Status:** Fixed. Added VBScript custom action in Product.wxs to parse Obsidian exe path from registry and set Icon registry values on all 4 context menu entries.

## Execution
- [x] when the vault opens, there's an app.json file in the vault root as well as the .obsidian folder -- this should just be in the .obsidian folder.
  - **Status:** Source templates and staging verified correct. Added path normalization safety in Copy-TemplateNonDestructive. If issue persists after fresh MSI install, needs further investigation.
- [x] The shift key isn't doing anything.
  - **Status:** Fixed by removing `Extended` registry entries entirely. Windows 11's modern context menu doesn't support `Extended`. Template chooser is now always visible as a second context menu entry.

---
**All bugs addressed as of 2026-02-14. Rebuild and test with fresh MSI install.**
