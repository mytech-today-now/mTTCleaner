# Changelog

All notable changes to mTTCleaner will be documented in this file.

## [2.2.0] - 2025-12-17

### Added

- **6 New Browser Support**: Extended browser support to 28 browsers total
  - **macOS-Exclusive Browsers**:
    - Orion Browser (Chromium-based)
    - Arc Browser (Chromium-based)
    - SigmaOS (Chromium-based)
    - iCab (WebKit-based)
  - **Linux-Specific Browsers**:
    - Epiphany/GNOME Web (WebKit-based)
    - Konqueror (KHTML-based)

### Technical Details

- Added browser definitions to `$script:BrowserDefinitions` hashtable
- Added platform-specific paths to `Get-BrowserPath` function
- Added browser detection entries to `$browserNames` (Windows), `$appNames` (macOS), and `$binaryNames` (Linux)
- All new browsers follow existing code patterns and standards
- Maintained backward compatibility with existing browser definitions

## [2.1.1] - 2025-12-16

### Added

- **Automatic SQLite3 Installation (Windows)**: New `Install-SQLite3` function automatically downloads and installs SQLite3 tools on Windows
  - Downloads latest SQLite3 precompiled binaries from sqlite.org
  - Extracts to script's install directory (`%LOCALAPPDATA%\myTech.Today\mTTCleaner\sqlite3\`)
  - Adds SQLite3 to PATH for current session
  - Eliminates manual SQLite3 installation requirement on Windows
  - Database compaction now works out-of-the-box on Windows

### Changed

- **Database Compaction**: Enhanced to automatically install SQLite3 on Windows if not found
- **Error Messages**: Improved SQLite3 not found messages (macOS/Linux only show package manager instructions)

### Improved

- **User Experience**: Zero-configuration database compaction on Windows
- **Self-Contained**: SQLite3 is now bundled automatically, making the tool fully self-contained on Windows

### Technical Details

- Added `Install-SQLite3` function (lines 222-301)
- Modified database compaction function to call `Install-SQLite3` before checking for sqlite3.exe (lines 1416-1440)
- SQLite3 download URL: https://www.sqlite.org/2024/sqlite-tools-win-x64-3460100.zip

## [2.1.0] - 2025-12-16

### Major Enhancements - Modern TUI, Enhanced Detection, and Enterprise Features

This release adds significant new features including modern UI, active browser detection, Windows Event Log integration, and full cross-platform shortcuts and scheduling.

### Added

- **22 Browser Support**: Added 7 new browsers:
  - Safari (macOS)
  - DuckDuckGo Browser
  - SRWare Iron
  - Maxthon Browser
  - SeaMonkey
  - Slimjet Browser
  - Falkon Browser
- **Modern TUI**: Interactive text-based user interface using PwshSpectreConsole (Spectre.Console)
  - Welcome banner with script information
  - Interactive browser selection menu with detected browsers
  - Operation type selection (Full Clean, Cache Only, Database Only, Metrics Only)
  - Graceful fallback to basic console output if Spectre.Console unavailable
- **Active Browser Detection**: New `Test-BrowserInstalled` function with platform-specific detection:
  - Windows: Registry queries (HKLM/HKCU Uninstall keys)
  - macOS: Application bundle detection in /Applications and ~/Applications
  - Linux: `which` command, flatpak list, snap list
- **Windows Event Log Integration**: Enhanced logging via myTech.Today Logging.ps1 module
  - Creates events under "Applications and Services Logs → myTech.Today → mTTCleaner"
  - Enhanced event messages with Problem/Context/Solution format
  - Monthly log archiving and cyclical logging (10MB limit)
  - Markdown table format for structured logging
- **Cross-Platform Shortcuts**: Enhanced `New-mTTCleanerShortcut` function
  - Windows: .lnk shortcuts on Desktop and Start Menu with "Run as Administrator" flag
  - macOS: Executable shell script wrapper on Desktop
  - Linux: .desktop files on Desktop and ~/.local/share/applications
- **Cross-Platform Task Scheduling**: Enhanced `Register-mTTCleanerTask` function
  - Windows: Task Scheduler under \myTech.Today\ folder
  - macOS: launchd plist in ~/Library/LaunchAgents/
  - Linux: cron entry via crontab
  - All platforms: Monthly execution on 15th at 1:00 PM
- **Parallel Processing Support**: Framework for parallel browser processing
  - New `-NoParallel` parameter to disable parallel processing
  - Automatic detection of PowerShell 7+ and browser count
  - Falls back to sequential processing for compatibility
- **Enhanced Browser Paths**: All new browsers have complete path definitions for Windows, macOS, and Linux
- **Enhanced Browser Profiles**: Updated `Get-BrowserProfiles` to handle Safari and Falkon profile structures

### Changed

- **Script Version**: Updated to 2.1.0
- **Help Documentation**: Comprehensive update with all new features and parameters
- **Browser Count**: Increased from 15 to 22 browsers
- **TUI Integration**: Interactive mode now shows browser selection menu instead of processing all browsers
- **Logging Module**: Downloads and integrates myTech.Today Logging.ps1 from GitHub with fallback to basic logging
- **Shortcut Creation**: Now fully cross-platform (previously Windows-only)
- **Task Scheduling**: Now fully cross-platform (previously Windows-only)

### Improved

- **Browser Detection**: More reliable detection using platform-specific methods
- **User Experience**: Modern interactive UI with better visual feedback
- **Enterprise Monitoring**: Windows Event Log integration for centralized monitoring
- **Documentation**: Updated README with all new features and examples
- **Error Handling**: Enhanced error messages and recovery throughout
- **Performance**: Framework for parallel processing (full implementation pending)

### Technical Details

#### New Functions

- `Initialize-SpectreConsole`: Checks for and installs PwshSpectreConsole module
- `Show-WelcomeBanner`: Displays branded welcome screen with script info
- `Show-BrowserSelection`: Interactive browser selection with detection
- `Show-OperationOptions`: Operation type selection menu
- `Test-BrowserInstalled`: Platform-specific browser detection

#### Enhanced Functions

- `New-mTTCleanerShortcut`: Now supports Windows, macOS, and Linux
- `Register-mTTCleanerTask`: Now supports Windows, macOS, and Linux
- `Get-BrowserProfiles`: Added support for Safari and Falkon profile structures
- `Get-BrowserPath`: Added paths for 7 new browsers across all platforms

#### Browser Definitions

All new browsers include complete definitions with:
- ProcessNames (platform-specific)
- CachePaths (Chromium/Firefox/Safari/Falkon patterns)
- DatabasePaths (browser-specific)
- MetricsPaths (telemetry file patterns)
- Type (Chromium/Firefox/Safari/Falkon)

#### Logging Enhancements

- Downloads myTech.Today Logging.ps1 module from GitHub
- Windows Event Log under "myTech.Today" event log with "mTTCleaner" source
- Enhanced event messages with structured Problem/Context/Solution format
- Monthly log archiving with YYYY-MM naming
- Cyclical logging with 10MB size limit
- Markdown table format for structured data

### Parameters

- Added `-NoParallel`: Disable parallel processing

### Known Limitations

- Parallel processing framework in place but requires function refactoring for full implementation
- Spectre.Console TUI requires PwshSpectreConsole module (graceful fallback if unavailable)
- Windows Event Log integration requires Logging.ps1 module download (graceful fallback if unavailable)

### Migration Notes

If upgrading from v2.0.0:
1. Script will automatically download Logging.ps1 module on first run
2. New browsers will be automatically detected and available for selection
3. Shortcuts and scheduled tasks can be recreated to use new cross-platform features
4. Windows Event Log will be automatically configured on first run (Windows only)

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

