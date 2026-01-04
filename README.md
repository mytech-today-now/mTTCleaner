# mTTCleaner - Cross-Platform Browser Cache and Database Cleanup Tool

## Overview

mTTCleaner is a comprehensive PowerShell 7+ based browser maintenance tool designed to keep your browsers running smoothly by cleaning caches, compacting databases, and removing unnecessary metrics files. It supports **28 browsers** across **Windows, macOS, and Linux** with modern interactive UI, active browser detection, and enterprise-grade logging.

## Features

- **Cross-Platform Support**: Works on Windows, macOS, and Linux with PowerShell 7+
- **28 Browser Support**: Supports 28 browsers including Chrome, Edge, Firefox, Brave, Opera, Vivaldi, Safari, and more
- **Modern Interactive TUI**: Spectre.Console-based UI with browser selection menu and operation options
- **Active Browser Detection**: Automatically detects installed browsers using platform-specific methods
- **Cache Cleanup**: Removes browser cache files to free up disk space
- **Database Compaction**: Uses SQLite VACUUM to compact browser databases and reclaim space
- **Automatic SQLite3 Installation**: Automatically downloads and installs SQLite3 on Windows (v2.1.1+)
- **Metrics Removal**: Deletes telemetry and metrics files
- **Process Management**: Automatically closes browser processes before cleanup
- **Windows Event Log Integration**: Enterprise monitoring via Windows Event Log (Windows only)
- **Cross-Platform Shortcuts**: Creates shortcuts on Desktop and Start Menu/Applications (all platforms)
- **Cross-Platform Scheduling**: Sets up monthly automated maintenance via Task Scheduler/launchd/cron (all platforms)
- **Parallel Processing**: Optional parallel browser processing for improved performance (PowerShell 7+)
- **Enhanced Logging**: myTech.Today logging module with markdown format and monthly archiving
- **Safe Operation**: Optional elevation with user confirmation
- **-WhatIf Support**: Test mode to preview changes without making them

## Supported Browsers

mTTCleaner supports **28 browsers** across Windows, macOS, and Linux platforms.

### Chromium-Based Browsers

- Google Chrome
- Microsoft Edge
- Brave Browser
- Vivaldi
- Opera
- Opera GX
- Chromium
- Ungoogled Chromium
- Midori Browser
- Min Browser
- DuckDuckGo Browser
- SRWare Iron
- Maxthon Browser
- Slimjet Browser
- Orion Browser (macOS only)
- Arc Browser (macOS only)
- SigmaOS (macOS only)

### Firefox-Based Browsers

- Mozilla Firefox
- LibreWolf
- Waterfox
- Pale Moon
- Tor Browser
- SeaMonkey

### WebKit-Based Browsers

- Safari (macOS only)
- iCab (macOS only)
- Epiphany/GNOME Web (Linux only)

### Other Browsers

- Falkon Browser
- Konqueror (Linux only)

## Requirements

- **Operating System**: Windows 10/11, macOS 10.13+, or Linux (any modern distribution)
- **PowerShell**: Version 7.0 or later (PowerShell Core/7+)
- **Privileges**: Administrator/root rights recommended but optional
- **Optional**: SQLite3 for database compaction (script will skip if not available)

### Installing PowerShell 7+

**Windows:**
```powershell
# Using winget
winget install Microsoft.PowerShell

# Or download from: https://github.com/PowerShell/PowerShell/releases
```

**macOS:**
```bash
# Using Homebrew
brew install powershell/tap/powershell

# Or download from: https://github.com/PowerShell/PowerShell/releases
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y powershell

# Fedora/RHEL/CentOS
sudo dnf install -y powershell

# Or follow instructions at: https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux
```

### SQLite3 for Database Compaction

SQLite3 is required for database compaction.

**Windows:**

- **Automatic Installation**: The script automatically downloads and installs SQLite3 on first run (v2.1.1+)
- No manual installation required!
- SQLite3 is installed to: `%LOCALAPPDATA%\myTech.Today\mTTCleaner\sqlite3\`

**macOS:**
```bash
brew install sqlite3
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt install sqlite3

# Fedora/RHEL/CentOS
sudo yum install sqlite

# Arch Linux
sudo pacman -S sqlite
```

## Installation

### Quick Install (All Platforms)

1. Download the script files to a temporary location
2. Open PowerShell 7+ (elevated/sudo recommended but optional)
3. Execute the script:

**Windows:**
```powershell
pwsh -File .\mTTCleaner.ps1
```

**macOS/Linux:**
```bash
pwsh -File ./mTTCleaner.ps1
```

The script will automatically:
- Detect your operating system
- Copy itself to the platform-specific installation directory
- Copy README files to the installation directory
- Re-launch from the installation location

### Platform-Specific Installation Paths

**Windows:**
- Install: `%LOCALAPPDATA%\myTech.Today\mTTCleaner`
- Logs: `%LOCALAPPDATA%\myTech.Today\mTTCleaner\logs`

**macOS:**
- Install: `~/Library/Application Support/myTech.Today/mTTCleaner`
- Logs: `~/Library/Logs/myTech.Today/mTTCleaner`

**Linux:**
- Install: `~/.local/share/myTech.Today/mTTCleaner`
- Logs: `~/.local/state/myTech.Today/mTTCleaner/logs`

## Usage

### Basic Usage

Run cleanup for all installed browsers:

**Windows:**
```powershell
pwsh -File .\mTTCleaner.ps1
```

**macOS/Linux:**
```bash
pwsh -File ./mTTCleaner.ps1
```

### Clean Specific Browser

Clean only Google Chrome:
```powershell
pwsh -File ./mTTCleaner.ps1 -Browser Chrome
```

### Test Mode (-WhatIf)

Preview what would be cleaned without making changes:
```powershell
pwsh -File ./mTTCleaner.ps1 -WhatIf
```

### Skip Confirmation

Run without user confirmation prompt:
```powershell
pwsh -File ./mTTCleaner.ps1 -SkipConfirmation
```

### Skip Database Compaction

Clean cache and metrics but skip database compaction:
```powershell
pwsh -File ./mTTCleaner.ps1 -SkipDatabaseCompaction
```

### Create Shortcuts (Cross-Platform)

Create desktop and start menu/applications shortcuts:

**Windows:**
```powershell
pwsh -File .\mTTCleaner.ps1 -CreateShortcuts
```

**macOS/Linux:**
```bash
pwsh -File ./mTTCleaner.ps1 -CreateShortcuts
```

### Create Scheduled Task (Cross-Platform)

Set up monthly automated maintenance:

**Windows:**
```powershell
pwsh -File .\mTTCleaner.ps1 -CreateScheduledTask
```

**macOS/Linux:**
```bash
pwsh -File ./mTTCleaner.ps1 -CreateScheduledTask
```

### Automated Mode

Run in automated mode (for scheduled tasks):
```powershell
pwsh -File ./mTTCleaner.ps1 -Automated
```

### Combined Options

Create shortcuts, scheduled task, and run cleanup (Windows):
```powershell
pwsh -File .\mTTCleaner.ps1 -CreateShortcuts -CreateScheduledTask
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-Automated` | Switch | Run in automated mode (skip confirmation and browser selection) |
| `-SkipConfirmation` | Switch | Skip user confirmation prompt |
| `-NoParallel` | Switch | Disable parallel processing (use sequential mode) |
| `-Browser` | String | Target specific browser or 'All' (default: All) |
| `-SkipDatabaseCompaction` | Switch | Skip database compaction operations |
| `-CreateShortcuts` | Switch | Create desktop and start menu/applications shortcuts (cross-platform) |
| `-CreateScheduledTask` | Switch | Create monthly scheduled task (cross-platform) |
| `-WhatIf` | Switch | Show what would happen without making changes |

## Scheduled Task Details

### Windows (Task Scheduler)

When you create a scheduled task using `-CreateScheduledTask` on Windows, the following task is created:

- **Name**: mTTCleaner
- **Location**: `\myTech.Today\`
- **Schedule**: Monthly on the 15th at 1:00 PM
- **User**: Current logged-in user
- **Privileges**: Runs with highest privileges (Administrator)
- **Conditions**:
  - Requires AC power
  - Wakes computer to run
- **Settings**:
  - Execution time limit: 2 hours
  - Auto-restart on failure (up to 3 times, every 10 minutes)

### macOS (launchd)

The script automatically creates a launchd plist file at `~/Library/LaunchAgents/com.mytech.today.mttcleaner.plist` with the following configuration:

- **Label**: com.mytech.today.mttcleaner
- **Schedule**: Monthly on the 15th at 1:00 PM
- **Logs**: ~/Library/Logs/mTTCleaner.log and mTTCleaner.error.log

The plist is automatically loaded after creation. To manually manage:

```bash
# Load the plist
launchctl load ~/Library/LaunchAgents/com.mytech.today.mttcleaner.plist

# Unload the plist
launchctl unload ~/Library/LaunchAgents/com.mytech.today.mttcleaner.plist
```

### Linux (cron)

The script automatically adds a cron entry to your crontab:

```bash
# Run mTTCleaner on the 15th of each month at 1:00 PM
0 13 15 * * /usr/bin/pwsh ~/.local/share/myTech.Today/mTTCleaner/mTTCleaner.ps1 -Automated
```

To manually manage:

```bash
# Edit crontab
crontab -e

# View current crontab
crontab -l
```

## Logging

All operations are logged to platform-specific locations:

**Windows:**
```
%LOCALAPPDATA%\myTech.Today\mTTCleaner\logs\mTTCleaner.log
```

**macOS:**
```
~/Library/Logs/myTech.Today/mTTCleaner/mTTCleaner.log
```

**Linux:**
```
~/.local/state/myTech.Today/mTTCleaner/logs/mTTCleaner.log
```

Logs include:

- Script start/end times
- Platform and elevation status
- Browser processes stopped
- Cache sizes cleared
- Database compaction results
- Metrics files removed
- Errors and warnings
- Summary statistics

**Windows Event Log** (Windows only):

- Events are logged to: `Applications and Services Logs → myTech.Today → mTTCleaner`
- Enhanced event messages with Problem/Context/Solution format
- Monthly log archiving with YYYY-MM naming
- Cyclical logging with 10MB size limit

## What Gets Cleaned

### Cache Files
- **Chromium Browsers**: Cache, Code Cache, GPU Cache, Service Worker Cache
- **Firefox Browsers**: cache2, startupCache, OfflineCache

### Databases (Compacted)
- **Chromium Browsers**: History, Cookies, Web Data, Login Data
- **Firefox Browsers**: places.sqlite, favicons.sqlite, cookies.sqlite, formhistory.sqlite

### Metrics/Telemetry Files
- Files matching patterns: `*metrics*`, `*telemetry*`, `datareporting`, `saved-telemetry-pings`

## Safety Features

1. **Cross-Platform Privilege Detection**: Detects elevation status on Windows, macOS, and Linux
2. **User Confirmation**: Prompts for 'Yes' confirmation before proceeding (unless `-Automated` or `-SkipConfirmation`)
3. **-WhatIf Support**: Test mode to preview changes without making them
4. **Process Termination**: Safely closes browser processes before cleanup
5. **Error Handling**: Comprehensive try-catch blocks prevent script crashes
6. **Logging**: All operations logged for audit trail
7. **Selective Cleanup**: Can target specific browsers or skip certain operations
8. **Platform Detection**: Automatically detects OS and uses appropriate paths

## Troubleshooting

### Script Won't Run

**Windows:**
- Ensure you're running PowerShell 7+ (`pwsh.exe`, not `powershell.exe`)
- Check execution policy: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`

**macOS/Linux:**
- Ensure PowerShell 7+ is installed: `pwsh --version`
- Make script executable: `chmod +x mTTCleaner.ps1`
- Run with: `pwsh -File ./mTTCleaner.ps1`

### Database Compaction Skipped

Install SQLite3 for your platform (see Requirements section above), or use `-SkipDatabaseCompaction` to skip this step.

### Browser Still Running

- Close browser manually before running script
- Script will attempt to force-close processes
- On Linux, some browsers may have multiple process names (e.g., `firefox` vs `firefox-bin`)

### Access Denied Errors

- Ensure no browser processes are running
- Check file permissions in browser profile directories
- Run with elevated privileges (Administrator/sudo) if needed

### Scheduled Task Not Running (Windows)

- Verify task exists in Task Scheduler under `\myTech.Today\` folder with task name `mTTCleaner`
- Check task history for errors
- Ensure computer is on AC power (task requires AC power)
- Verify task is using `pwsh.exe` not `powershell.exe`

### Browser Not Found (macOS/Linux)

- Browser paths may vary by distribution
- Check if browser is installed: `which chrome` or `which firefox`
- Use `-Verbose` to see which paths are being checked

## Examples

### Example 1: First-Time Setup (Windows)

```powershell
# Run with elevated privileges
pwsh -File .\mTTCleaner.ps1 -CreateShortcuts -CreateScheduledTask

# This will:
# 1. Install script to %LOCALAPPDATA%\myTech.Today\mTTCleaner\
# 2. Create desktop shortcut
# 3. Create start menu shortcut
# 4. Create monthly scheduled task
# 5. Run cleanup for all browsers
```

### Example 2: First-Time Setup (macOS/Linux)

```bash
# Run the script
pwsh -File ./mTTCleaner.ps1

# Manually set up scheduling (see Scheduling sections above)
```

### Example 3: Quick Cleanup (All Platforms)

```bash
# Clean all browsers without confirmation
pwsh -File ./mTTCleaner.ps1 -SkipConfirmation
```

### Example 4: Test Mode

```bash
# Preview what would be cleaned
pwsh -File ./mTTCleaner.ps1 -WhatIf -Verbose
```

### Example 5: Clean Specific Browser

```bash
# Clean only Firefox
pwsh -File ./mTTCleaner.ps1 -Browser Firefox -SkipConfirmation
```

### Example 6: Cache Only

```bash
# Clean cache but skip database compaction
pwsh -File ./mTTCleaner.ps1 -SkipDatabaseCompaction
```

## Performance

Typical cleanup results (varies by usage):

- **Cache Cleared**: 500 MB - 5 GB per browser
- **Database Space Saved**: 10 MB - 100 MB per browser
- **Metrics Files Removed**: 50 - 500 files per browser
- **Execution Time**: 2-5 minutes for all browsers

## Uninstallation

### Windows

```powershell
# Delete the scheduled task
Unregister-ScheduledTask -TaskName "mTTCleaner" -TaskPath "\myTech.Today\" -Confirm:$false

# Delete shortcuts
Remove-Item "$env:USERPROFILE\Desktop\mTTCleaner.lnk" -Force -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\myTech.Today\mTTCleaner.lnk" -Force -ErrorAction SilentlyContinue

# Delete installation directory
Remove-Item "$env:LOCALAPPDATA\myTech.Today\mTTCleaner" -Recurse -Force
```

### macOS

```bash
# Unload launchd job (if configured)
launchctl unload ~/Library/LaunchAgents/com.mytech.today.mttcleaner.plist
rm ~/Library/LaunchAgents/com.mytech.today.mttcleaner.plist

# Delete installation directory
rm -rf ~/Library/Application\ Support/myTech.Today/mTTCleaner
rm -rf ~/Library/Logs/myTech.Today/mTTCleaner
```

### Linux

```bash
# Remove cron job (if configured)
crontab -e
# Remove the mTTCleaner line

# Delete installation directory
rm -rf ~/.local/share/myTech.Today/mTTCleaner
rm -rf ~/.local/state/myTech.Today/mTTCleaner
```

## Version History

### Version 2.1.1 (2025-12-16)

- **Automatic SQLite3 Installation**: Windows users no longer need to manually install SQLite3
- **Zero Configuration**: Database compaction works out-of-the-box on Windows
- **Self-Contained**: SQLite3 automatically downloaded and installed to script directory
- **Improved UX**: Eliminated manual SQLite3 installation step for Windows users

### Version 2.1.0 (2025-12-16)

- **22 Browser Support**: Added Safari, DuckDuckGo, SRWare Iron, Maxthon, SeaMonkey, Slimjet, Falkon
- **Modern TUI**: Interactive UI with Spectre.Console (browser selection, operation options)
- **Active Browser Detection**: Platform-specific detection via registry/mdfind/which/flatpak/snap
- **Windows Event Log Integration**: Enterprise monitoring via myTech.Today logging module
- **Cross-Platform Shortcuts**: Desktop and Start Menu/Applications shortcuts on all platforms
- **Cross-Platform Scheduling**: Task Scheduler/launchd/cron support on all platforms
- **Parallel Processing**: Framework for parallel browser processing (PowerShell 7+)
- **Enhanced Logging**: myTech.Today module with markdown format and monthly archiving

### Version 2.0.0 (2025-12-16)

- **Cross-Platform Support**: Full support for Windows, macOS, and Linux
- **PowerShell 7+ Required**: Updated from PowerShell 5.1 to PowerShell 7.0+
- **Platform Detection**: Automatic OS detection and platform-specific path resolution
- **-WhatIf Support**: Added test mode to preview changes
- **Enhanced Logging**: Self-contained cross-platform logging system
- **Progress Indicators**: Shows current browser being processed
- **Improved Error Handling**: Better error messages and recovery

### Version 1.0.0 (2025-01-23)

- Initial Windows-only release
- Support for 15 browsers
- Cache cleanup functionality
- Database compaction with SQLite VACUUM
- Metrics file removal
- Desktop and start menu shortcuts
- Monthly scheduled task
- Comprehensive logging
- myTech.Today standards compliance

See [CHANGELOG.md](CHANGELOG.md) for detailed changes.

## License

Copyright (c) 2025 myTech.Today. All rights reserved.

## Author

**Kyle C. Rode**
myTech.Today
Lake Zurich, IL

## Support

For issues, questions, or feature requests:
- Visit: [https://mytech.today](https://mytech.today)
- Email: support@mytech.today

## Related Tools

- **bookmarks.ps1**: Manage browser bookmarks
- **hosts.ps1**: Manage Windows hosts file with ad-blocking
- **install-gui.ps1**: Application installer with GUI
- **Manage-RestorePoints.ps1**: Windows System Restore management

## Acknowledgments

- Follows myTech.Today PowerShell development standards
- Cross-platform support using PowerShell 7+
- SQLite database compaction requires sqlite3 (optional)

---

**Note**: This tool is designed for personal and professional use. Always ensure you have backups of important browser data before running cleanup operations.

