# Changelog

All notable changes to mTTCleaner will be documented in this file.

## [2.0.0] - 2025-12-16

### Major Changes - Cross-Platform Support

This release represents a complete refactoring of mTTCleaner to support Windows, macOS, and Linux using PowerShell 7+.

### Added

- **Cross-Platform Support**: Full support for Windows, macOS, and Linux
- **Platform Detection**: Automatic detection of operating system using `$IsWindows`, `$IsMacOS`, `$IsLinux`
- **Cross-Platform Path Resolution**: New `Get-PlatformPath` function that resolves platform-specific paths:
  - Windows: `%LOCALAPPDATA%`, `%APPDATA%`, `%TEMP%`
  - macOS: `~/Library/Caches`, `~/Library/Application Support`, `~/Library/Preferences`
  - Linux: `$XDG_CACHE_HOME`, `$XDG_CONFIG_HOME`, `~/.cache`, `~/.config`
- **Cross-Platform Browser Paths**: New `Get-BrowserPath` function with platform-specific browser profile locations for all 15 supported browsers
- **Cross-Platform Privilege Detection**: New `Test-IsElevated` function that works on all platforms
- **Self-Contained Logging**: Replaced external GitHub-based logging module with built-in cross-platform logging
- **-WhatIf Support**: Added `SupportsShouldProcess` to all cleanup functions for safe testing
- **Progress Indicators**: Added browser processing progress (e.g., "Processing Chrome (1 of 15)...")
- **Platform Information Display**: Shows current platform and elevation status in user interface and logs
- **Cross-Platform SQLite Support**: Detects and uses `sqlite3` command on all platforms with helpful installation instructions

### Changed

- **PowerShell Version Requirement**: Updated from 5.1 to 7.0 (PowerShell Core/7+)
- **Removed Windows-Only Requirement**: Removed `#Requires -RunAsAdministrator` directive
- **Script Version**: Updated to 2.0.0 to reflect major cross-platform changes
- **Browser Definitions**: All 15 browser definitions now use `Get-BrowserPath` instead of hardcoded paths:
  - Chromium-based: Chrome, Edge, Brave, Vivaldi, Opera, OperaGX, Chromium, Ungoogled Chromium, Midori, Min
  - Firefox-based: Firefox, LibreWolf, Waterfox, Tor Browser, Pale Moon
- **Process Names**: Updated browser process names to include platform-specific variants (e.g., 'firefox-bin' for Linux)
- **Path Separators**: Changed from backslash to forward slash for cross-platform compatibility
- **Shortcut Creation**: Now Windows-only with informative messages for other platforms
- **Scheduled Task Creation**: Now Windows-only with informative messages for other platforms (suggests cron for Linux, launchd for macOS)
- **PowerShell Executable**: Changed from `powershell.exe` to `pwsh.exe` in shortcuts and scheduled tasks

### Fixed

- **Variable Reference Syntax**: Fixed error messages with colons followed by `$_` using `${}` delimiter
- **Error Handling**: Improved error handling in all cleanup functions
- **Verbose Output**: Added comprehensive verbose logging throughout the script

### Technical Details

#### Platform-Specific Paths

**Windows:**
- Install: `%LOCALAPPDATA%\myTech.Today\mTTCleaner`
- Logs: `%LOCALAPPDATA%\myTech.Today\mTTCleaner\logs`
- Cache: `%LOCALAPPDATA%\Temp`

**macOS:**
- Install: `~/Library/Application Support/myTech.Today/mTTCleaner`
- Logs: `~/Library/Logs/myTech.Today/mTTCleaner`
- Cache: `~/Library/Caches`

**Linux:**
- Install: `~/.local/share/myTech.Today/mTTCleaner`
- Logs: `~/.local/state/myTech.Today/mTTCleaner/logs`
- Cache: `~/.cache`

#### Browser Support by Platform

All 15 browsers are now supported across platforms where they are available:
- **Windows**: All browsers supported
- **macOS**: Chrome, Edge, Brave, Firefox, Opera, Vivaldi, Chromium, LibreWolf, Waterfox, Tor Browser
- **Linux**: Chrome, Chromium, Firefox, Brave, Opera, Vivaldi, LibreWolf, Waterfox, Tor Browser, Pale Moon

#### Prerequisites

- **PowerShell 7.0 or higher** (cross-platform)
- **SQLite3** (optional, for database compaction):
  - Windows: Download from https://www.sqlite.org/download.html
  - macOS: `brew install sqlite3`
  - Linux: `sudo apt install sqlite3` (Debian/Ubuntu) or `sudo yum install sqlite` (RHEL/CentOS)

### Migration Notes

If upgrading from v1.x:
1. Install PowerShell 7+ if not already installed
2. The script will automatically migrate to the new install location
3. Existing shortcuts and scheduled tasks will continue to work but should be recreated to use `pwsh.exe`
4. Log files will be in the new platform-specific location

### Known Limitations

- Shortcut creation only supported on Windows
- Scheduled task creation only supported on Windows (use cron on Linux, launchd on macOS)
- Some browsers may have different profile locations on different Linux distributions

## [1.0.0] - Previous Release

Initial Windows-only release with PowerShell 5.1 support.

