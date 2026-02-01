@echo off
REM ============================================================================
REM Build wrapper for ObsidianQuickLaunch
REM
REM This batch file runs Build-Installer.ps1 with proper PowerShell execution
REM policy settings to avoid permission issues.
REM
REM Usage:
REM   build.bat                    - Rebuild (clean + build, default)
REM   build.bat rebuild            - Same as above
REM   build.bat build              - Build only (fails if MSI exists)
REM   build.bat clean              - Remove build artifacts only
REM   build.bat rebuild 1.2.3      - Rebuild with specific version
REM   build.bat build 1.2.3        - Build with specific version
REM ============================================================================

setlocal EnableDelayedExpansion

REM Get the directory where this script is located
set "SCRIPT_DIR=%~dp0"

REM Build the PowerShell arguments
set "PS_ARGS="

REM First argument is the action (build, rebuild, clean)
if not "%~1"=="" (
    set "PS_ARGS=%~1"
)

REM Second argument is the version (optional)
if not "%~2"=="" (
    set "PS_ARGS=!PS_ARGS! -Version %~2"
)

REM Run the PowerShell script with Bypass execution policy
REM -NoProfile: Faster startup, avoids profile conflicts
REM -ExecutionPolicy Bypass: Allows scripts to run without policy restrictions
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Build-Installer.ps1" %PS_ARGS%

REM Capture the exit code from PowerShell
set "EXIT_CODE=%ERRORLEVEL%"

REM Exit with the same code as PowerShell
exit /b %EXIT_CODE%
