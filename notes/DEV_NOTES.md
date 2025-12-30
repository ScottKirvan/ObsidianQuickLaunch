# Development Notes - ObsidianQuickLaunch

This document captures key technical decisions, challenges solved, and the rationale behind implementation choices during development.

## Session History: Initial Development (Dec 12-16, 2024)

### Project Genesis

**Goal**: Create a Windows Explorer context menu integration to quickly open folders as Obsidian vaults.

**User Requirements**:
- Power user workflow with multiple small vaults
- Right-click context menu (both ON folders and IN folders)
- Preserve existing open vaults when opening new ones
- Minimal disruption to existing workflow

---

## Technical Challenges & Solutions

### Challenge 1: How to Open Obsidian Vaults

**Investigation**: Tested multiple approaches to determine the best method.

**Approaches Tested**:
1. ✅ **`obsidian://` URI Protocol** - WORKS
   - Uses `obsidian://open?path=<encoded_path>`
   - Officially supported by Obsidian
   - Requires vault to be registered in `obsidian.json`

2. ❌ **Direct Executable with Arguments** - DOESN'T WORK
   - Tried: `Obsidian.exe "C:\path\to\vault"`
   - Result: Opens Obsidian but ignores the path argument
   - Conclusion: Obsidian doesn't accept command-line vault paths

3. ❌ **Alternative URI Formats** - DOESN'T WORK
   - Tried: `obsidian://vault/<path>`
   - Tried: `obsidian://open?vault=<path>`
   - Result: "Vault not found" errors for unregistered vaults

**Decision**: Use `obsidian://` URI protocol with vault registration in `obsidian.json`.

**Files**: `tests/test-vault-opening.ps1`, `tests/test-direct-launch.ps1`

---

### Challenge 2: Vault Registration Without Restart

**Problem**: Obsidian doesn't hot-reload its vault list.

**Investigation**:
- Modified `obsidian.json` while Obsidian was running
- Attempted to open the newly added vault
- Result: "Vault not found" error

**Critical Discovery**: Obsidian writes to `obsidian.json` on exit, **overwriting** any changes made while it was running.

**Implications**:
- MUST close Obsidian before modifying `obsidian.json`
- Cannot add vaults without interrupting the user's workflow

**Decision**:
1. Save which vaults are currently open
2. Close Obsidian
3. Modify `obsidian.json` safely
4. Reopen all previously open vaults + new vault

**Files**: `tests/test-hot-reload.ps1`, `src/scripts/register-vault-final.ps1`

---

### Challenge 3: Preserving User Workspace

**Problem**: User has multiple vaults open simultaneously. How to avoid losing their workspace?

**Solution**:
1. Before closing Obsidian, parse `obsidian.json` to find vaults with `"open": true`
2. Store list of open vault paths
3. After registration, reopen all previously open vaults
4. Open new vault LAST (so it appears on top/in focus)

**Workspace Restoration**:
- Each vault's state is stored in `.obsidian/workspace.json`
- Obsidian automatically restores workspace when vault opens
- Includes: open notes, tabs, active file, sidebar state, pane layout

**Additional Consideration**: When Obsidian isn't running, skip the close/reopen cycle entirely.

**Files**: `src/scripts/register-vault-final.ps1:36-69`

---

### Challenge 4: Homepage Plugin Conflict

**Issue**: User reported that vaults were opening to homepage instead of previous tabs.

**Investigation**:
- Examined user's vault `D:\1\GitRepos\ScottKirvan\Vaults\sk\.obsidian\plugins/homepage/data.json`
- Found: `"openOnStartup": true` and `"openMode": "Replace all open notes"`

**Root Cause**: The homepage plugin was overriding workspace restoration by replacing all tabs on startup.

**Solution**: Documented the conflict with two options:
1. Set `"openOnStartup": false` (recommended)
2. Set `"openMode": "Keep open notes"` (keeps homepage but restores tabs too)

**Decision**: Not a bug in our tool, but a plugin configuration issue. Documented in README and script comments.

**Files**: `src/scripts/register-vault-final.ps1:3-17`, `notes/README.md:75-94`

---

### Challenge 5: Finding Obsidian Installation

**Problem**: Obsidian can be installed in various locations. How to find the executable for the context menu icon?

**Initial Approach**: Hardcoded common paths:
```powershell
$obsidianIconPaths = @(
    "D:\bin\Obsidian\Obsidian.exe",
    "$env:LOCALAPPDATA\Obsidian\Obsidian.exe",
    "$env:LOCALAPPDATA\Programs\Obsidian\Obsidian.exe"
)
```

**User Request**: "Can we find the obsidian path from the registry rather than hard-coding it?"

**Better Solution**: Query the registry where the `obsidian://` protocol is registered:
```powershell
$regKey = Get-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\obsidian\shell\open\command"
$command = $regKey.'(default)'  # e.g., "D:\bin\Obsidian\Obsidian.exe" "%1"
```

**Benefits**:
- Works with any installation location
- Uses the same path that Obsidian itself registered
- Automatic fallback to common paths if registry lookup fails

**Files**: `src/scripts/install-context-menu.ps1:51-87`

---

### Challenge 6: Multi-Window Behavior

**Investigation**: Does Obsidian support multiple vault windows simultaneously?

**Test**: Attempted to open multiple vaults via URI while one was already open.

**Result**:
- Obsidian DOES support multiple windows (one per vault)
- Each vault window is independent
- Each restores its own workspace state

**Implication**: Our approach of reopening all previously open vaults works correctly - each opens in its own window.

**Files**: `tests/test-multi-window.ps1`

---

## Design Decisions

### Why PowerShell Scripts Instead of Compiled Executable?

**Pros**:
- Easy to read and modify
- No compilation step
- Users can inspect the code (open source transparency)
- Fast iteration during development
- Native Windows integration

**Cons**:
- Requires PowerShell (built into Windows 10/11)
- Execution policy considerations
- Less "polished" than compiled app

**Decision**: Start with PowerShell, consider compiled packaging later (Phase 2).

---

### Why Registry Modification Instead of Obsidian Plugin?

**Registry Approach**:
- ✅ Works outside of Obsidian
- ✅ System-wide context menu
- ✅ No dependency on Obsidian plugin API
- ❌ Requires administrator privileges

**Plugin Approach**:
- ✅ No admin privileges needed
- ❌ Only works from within Obsidian
- ❌ Doesn't provide context menu in Explorer

**Decision**: Registry integration for Windows Explorer context menu. Plugin approach wouldn't meet the requirement of "right-click any folder in Explorer."

---

### Context Menu: Two Entry Points

**Requirement**: User wanted to open vaults in two scenarios:
1. Right-click ON a folder (from parent directory)
2. Right-click IN a folder (inside the folder to be vaulted)

**Implementation**:
- `HKEY_CLASSES_ROOT\Directory\shell\ObsidianQuickLaunch` - Right-click ON folder
- `HKEY_CLASSES_ROOT\Directory\Background\shell\ObsidianQuickLaunch` - Right-click IN folder

Both use `%V` to get the folder path and call the same script.

**Files**: `src/scripts/install-context-menu.ps1:31-80`

---

## JSON Manipulation Gotchas

### UTF-8 BOM Issues

**Problem**: When using PowerShell's `ConvertTo-Json | Set-Content`, it was adding a UTF-8 BOM that corrupted the file.

**Solution**: Use explicit UTF-8 encoding without BOM:
```powershell
[System.IO.File]::WriteAllText($path, $json, [System.Text.UTF8Encoding]::new($false))
```

**Files**: `src/scripts/register-vault-final.ps1:60`

---

### String Escaping in JSON

**Problem**: Windows paths need double backslashes in JSON:
```
D:\path\to\vault  →  D:\\path\\to\\vault
```

**Solution**:
```powershell
$normalizedPath = $VaultPath -replace '\\', '\\\\'
```

**Files**: `src/scripts/register-vault-final.ps1:71`

---

### Backup Strategy

**Decision**: Always backup `obsidian.json` before modification with timestamp:
```powershell
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupPath = "$obsidianConfigPath.$timestamp.bak"
Copy-Item $obsidianConfigPath $backupPath -Force
```

**Rationale**: User's vault list is critical data. If modification fails, they can restore from backup.

**Files**: `src/scripts/register-vault-final.ps1:76-78`

---

## PowerShell Best Practices Applied

### 1. Error Handling
- Try/catch blocks with silent fallbacks
- Graceful degradation (e.g., icon fallback if Obsidian not found)
- User-friendly error messages

### 2. User Feedback
- Color-coded output (Green=success, Yellow=warning, Red=error, Gray=info)
- Progress indicators for multi-step operations
- Clear instructions in output

### 3. Admin Privilege Checks
```powershell
$isAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
```

### 4. Path Handling
- Always resolve relative paths to absolute
- Quote paths with spaces
- Use `Join-Path` for cross-platform compatibility

---

## Testing Methodology

### Test Scripts Created

All test scripts in `/tests/` directory:

1. **test-vault-opening.ps1** - Tests URI protocol methods
2. **test-multi-window.ps1** - Tests multiple vault windows
3. **test-hot-reload.ps1** - Tests config modification while running
4. **test-direct-launch.ps1** - Tests direct executable launch

**Purpose**: These scripts allowed rapid experimentation to determine what worked vs. what didn't, without writing production code.

---

## Future Considerations

### Phase 2: Template System

**Ideas to Explore**:
- Template vaults with pre-configured plugins, settings, themes
- Template structure: folder hierarchy, template files
- Template metadata: description, author, category
- Template selection UI (PowerShell dialog? Obsidian plugin?)

### Testing & CI/CD

**Planned**:
- PowerShell Pester unit tests
- GitHub Actions for automated testing
- Test matrix: Different Windows versions, Obsidian versions, install locations

### Distribution

**Options**:
- MSI installer (Windows Installer)
- Chocolatey package
- WinGet package
- Scoop manifest
- Self-extracting executable

---

## Lessons Learned

1. **Always test assumptions**: The assumption that `Obsidian.exe <path>` would work was wrong. Testing revealed the truth.

2. **Registry is powerful**: Windows registry provides a wealth of information about installed applications.

3. **User workflow matters**: The requirement to preserve open vaults fundamentally shaped the architecture.

4. **Documentation is critical**: Without the `.clinerules` file, future sessions would lose all this context.

5. **PowerShell gotchas**: BOM encoding, string escaping, and path quoting all caused issues during development.

---

## Key File Reference

### Production Scripts
- `src/scripts/register-vault-final.ps1` - Main vault registration logic
- `src/scripts/install-context-menu.ps1` - Registry installer
- `src/scripts/uninstall-context-menu.ps1` - Registry cleanup

### Test Scripts
- `tests/test-vault-opening.ps1` - URI protocol validation
- `tests/test-multi-window.ps1` - Multi-window behavior
- `tests/test-hot-reload.ps1` - Hot-reload investigation
- `tests/test-direct-launch.ps1` - Direct exe launch test

### Documentation
- `README.md` - Repository overview
- `notes/README.md` - User documentation
- `notes/TODO.md` - Project roadmap
- `notes/DEV_NOTES.md` - This file
- `.claude/CLAUDE.md` - Claude Code project rules

---

**Last Updated**: 2024-12-16
**Development Session**: Initial implementation (Phase 1 complete)
