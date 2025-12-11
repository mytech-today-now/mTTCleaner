# mTTCleaner - Browser Cache and Database Cleanup Tool

## Overview

mTTCleaner is a comprehensive PowerShell-based browser maintenance tool designed to keep your browsers running smoothly by cleaning caches, compacting databases, and removing unnecessary metrics files. It supports 15+ popular browsers and can be run manually or scheduled for automatic monthly maintenance.

## Features

- **Multi-Browser Support**: Works with 15+ browsers including Chrome, Edge, Firefox, Brave, Opera, Vivaldi, and more
- **Cache Cleanup**: Removes browser cache files to free up disk space
- **Database Compaction**: Uses SQLite VACUUM to compact browser databases and reclaim space
- **Metrics Removal**: Deletes telemetry and metrics files
- **Process Management**: Automatically closes browser processes before cleanup
- **Desktop Shortcuts**: Creates convenient shortcuts for easy access
- **Scheduled Tasks**: Sets up monthly automated maintenance
- **Detailed Logging**: Comprehensive logging to track all operations
- **Safe Operation**: Requires administrator privileges and user confirmation

## Supported Browsers

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

### Firefox-Based Browsers
- Mozilla Firefox
- LibreWolf
- Waterfox
- Pale Moon
- Tor Browser

## Requirements

- **Operating System**: Windows 10 or Windows 11
- **PowerShell**: Version 5.1 or later
- **Privileges**: Administrator rights required
- **Optional**: SQLite3.exe for database compaction (script will skip if not available)

## Installation

### Quick Install

1. Download the script files to a temporary location
2. Run PowerShell as Administrator
3. Execute the script:

```powershell
.\mTTCleaner.ps1
```

The script will automatically:
- Copy itself to `%USERPROFILE%\myTech.Today\scripts\mTTCleaner\`
- Copy README files to the installation directory
- Re-launch from the installation location

### Manual Installation

1. Create the installation directory:
```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\myTech.Today\scripts\mTTCleaner" -Force
```

2. Copy the script files:
```powershell
Copy-Item -Path ".\mTTCleaner.ps1" -Destination "$env:USERPROFILE\myTech.Today\scripts\mTTCleaner\"
Copy-Item -Path ".\README.md" -Destination "$env:USERPROFILE\myTech.Today\scripts\mTTCleaner\"
Copy-Item -Path ".\README.html" -Destination "$env:USERPROFILE\myTech.Today\scripts\mTTCleaner\"
```

3. Run the script from the installation location

## Usage

### Basic Usage

Run cleanup for all installed browsers:
```powershell
.\mTTCleaner.ps1
```

### Clean Specific Browser

Clean only Google Chrome:
```powershell
.\mTTCleaner.ps1 -Browser Chrome
```

### Skip Confirmation

Run without user confirmation prompt:
```powershell
.\mTTCleaner.ps1 -SkipConfirmation
```

### Skip Database Compaction

Clean cache and metrics but skip database compaction:
```powershell
.\mTTCleaner.ps1 -SkipDatabaseCompaction
```

### Create Shortcuts

Create desktop and start menu shortcuts:
```powershell
.\mTTCleaner.ps1 -CreateShortcuts
```

### Create Scheduled Task

Set up monthly automated maintenance:
```powershell
.\mTTCleaner.ps1 -CreateScheduledTask
```

### Automated Mode

Run in automated mode (for scheduled tasks):
```powershell
.\mTTCleaner.ps1 -Automated
```

### Combined Options

Create shortcuts, scheduled task, and run cleanup:
```powershell
.\mTTCleaner.ps1 -CreateShortcuts -CreateScheduledTask
```

## Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `-Automated` | Switch | Run in automated mode (skip confirmation) |
| `-SkipConfirmation` | Switch | Skip user confirmation prompt |
| `-Browser` | String | Target specific browser or 'All' (default: All) |
| `-SkipDatabaseCompaction` | Switch | Skip database compaction operations |
| `-CreateShortcuts` | Switch | Create desktop and start menu shortcuts |
| `-CreateScheduledTask` | Switch | Create monthly scheduled task |
| `-WhatIf` | Switch | Show what would happen without making changes |

## Scheduled Task Details

When you create a scheduled task using `-CreateScheduledTask`, the following task is created:

- **Name**: mTTCleaner
- **Location**: `\myTech.Today\`
- **Schedule**: Monthly on the 15th at 1:00 PM
- **User**: Current logged-in user
- **Privileges**: Runs with highest privileges (Administrator)
- **Conditions**: 
  - Requires AC power
  - Wakes computer to run
- **Settings**:
  - Execution time limit: 1 hour
  - Auto-restart on failure (up to 3 times, every 10 minutes)

## Logging

All operations are logged to:
```
%USERPROFILE%\myTech.Today\logs\mttcleaner.md
```

Logs include:
- Script start/end times
- Browser processes stopped
- Cache sizes cleared
- Database compaction results
- Metrics files removed
- Errors and warnings
- Summary statistics

Logs are rotated monthly with the format: `mttcleaner.YYYY-MM.md`

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

1. **Administrator Check**: Script requires administrator privileges
2. **User Confirmation**: Prompts for 'Yes' confirmation before proceeding (unless `-Automated` or `-SkipConfirmation`)
3. **Process Termination**: Safely closes browser processes before cleanup
4. **Error Handling**: Comprehensive try-catch blocks prevent script crashes
5. **Logging**: All operations logged for audit trail
6. **Selective Cleanup**: Can target specific browsers or skip certain operations

## Troubleshooting

### Script Won't Run
- Ensure you're running PowerShell as Administrator
- Check execution policy: `Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`

### Database Compaction Skipped
- Install SQLite3.exe and add to PATH
- Or use `-SkipDatabaseCompaction` to skip this step

### Browser Still Running
- Close browser manually before running script
- Script will attempt to force-close processes

### Access Denied Errors
- Ensure no browser processes are running
- Check file permissions in browser profile directories
- Run as Administrator

### Scheduled Task Not Running
- Verify task exists in Task Scheduler under the `\myTech.Today\` folder with task name `mTTCleaner`
- Check task history for errors
- Ensure computer is on AC power (task requires AC power)

## Examples

### Example 1: First-Time Setup
```powershell
# Run as Administrator
.\mTTCleaner.ps1 -CreateShortcuts -CreateScheduledTask

# This will:
# 1. Install script to %USERPROFILE%\myTech.Today\scripts\mTTCleaner\
# 2. Create desktop shortcut
# 3. Create start menu shortcut
# 4. Create monthly scheduled task
# 5. Run cleanup for all browsers
```

### Example 2: Quick Cleanup
```powershell
# Clean all browsers without confirmation
.\mTTCleaner.ps1 -SkipConfirmation
```

### Example 3: Clean Specific Browser
```powershell
# Clean only Firefox
.\mTTCleaner.ps1 -Browser Firefox -SkipConfirmation
```

### Example 4: Cache Only
```powershell
# Clean cache but skip database compaction
.\mTTCleaner.ps1 -SkipDatabaseCompaction
```

## Performance

Typical cleanup results (varies by usage):

- **Cache Cleared**: 500 MB - 5 GB per browser
- **Database Space Saved**: 10 MB - 100 MB per browser
- **Metrics Files Removed**: 50 - 500 files per browser
- **Execution Time**: 2-5 minutes for all browsers

## Uninstallation

To remove mTTCleaner:

1. Delete the scheduled task:
```powershell
Unregister-ScheduledTask -TaskName "mTTCleaner" -TaskPath "\myTech.Today\" -Confirm:$false
```

2. Delete shortcuts:
```powershell
Remove-Item "$env:USERPROFILE\Desktop\mTTCleaner.lnk" -Force
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\myTech.Today\mTTCleaner.lnk" -Force
```

3. Delete installation directory:
```powershell
Remove-Item "$env:USERPROFILE\myTech.Today\scripts\mTTCleaner" -Recurse -Force
```

## Version History

### Version 1.0.0 (2025-01-23)
- Initial release
- Support for 15+ browsers
- Cache cleanup functionality
- Database compaction with SQLite VACUUM
- Metrics file removal
- Desktop and start menu shortcuts
- Monthly scheduled task
- Comprehensive logging
- myTech.Today standards compliance

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

- Uses shared logging module from myTech.Today scripts repository
- Follows myTech.Today PowerShell development standards
- SQLite database compaction requires sqlite3.exe (optional)

---

**Note**: This tool is designed for personal and professional use. Always ensure you have backups of important browser data before running cleanup operations.

