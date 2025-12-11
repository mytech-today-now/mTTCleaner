# mTTCleaner - Browser Cache and Database Cleanup Tool

## Project Overview

Create a comprehensive PowerShell 5.1 script that cleans browser caches, compacts databases, and removes metrics temp files for all major browsers. The script follows myTech.Today standards and includes automatic deployment, shortcut creation, and scheduled task setup.

## Files to Generate

1. **Script**: `Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\mTTCleaner.ps1`
2. **README**: `Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\README.md`
3. **README HTML**: `Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\README.html`
4. **Git Ignore**: `Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\.gitignore`
5. **Version File**: `Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\VERSION`

## myTech.Today Standards Compliance

### Logging Requirements
- **Module**: Use shared logging from `https://raw.githubusercontent.com/mytech-today-now/scripts/refs/heads/main/logging.ps1`
- **Log Path**: `%USERPROFILE%\myTech.Today\logs\mTTCleaner.md`
- **Format**: Markdown table format with monthly rotation (mTTCleaner-YYYY-MM.md)
- **Indicators**: ASCII only - [OK], [FAIL], [WARN], [INFO] (NO EMOJI)
- **Progress**: Suppress with `$ProgressPreference = 'SilentlyContinue'`

### Script Structure
- **PowerShell Version**: 5.1
- **Help**: Complete comment-based help with SYNOPSIS, DESCRIPTION, PARAMETER, EXAMPLE, NOTES
- **Error Handling**: Try-catch-finally blocks with detailed error logging
- **Parameters**: Use [CmdletBinding()] with proper validation
- **Exit Codes**: 0 for success, non-zero for errors
- **Naming**: PascalCase for parameters, camelCase for local variables

### Deployment Location
- **Install Path**: `%USERPROFILE%\myTech.Today\mTTCleaner\`
- **Files to Copy**: 
  - `mTTCleaner.ps1`
  - `README.md`
  - `README.html`

## Core Functionality

### 1. Administrator and Confirmation Checks
- **Admin Check**: Verify script is running as administrator, exit if not
- **User Confirmation**: Prompt user to type 'Yes' to confirm execution
- **Self-Deployment**: Copy script and documentation to `%USERPROFILE%\myTech.Today\mTTCleaner\` and run from there

### 2. Browser Support
Support all browsers from the myTech.Today installer applications list:

**Chromium-based Browsers:**
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

**Firefox-based Browsers:**
- Firefox
- LibreWolf
- Waterfox
- Pale Moon
- Tor Browser

### 3. Cleanup Operations

For each installed browser, perform these operations:

#### A. Force Close Browser Processes
- Detect and terminate all browser processes before cleanup
- Log each process termination
- Handle gracefully if browser is not running

#### B. Delete Cache Files
- **Chrome/Edge/Brave/Chromium**: `%LOCALAPPDATA%\[Browser]\User Data\Default\Cache\*`
- **Firefox**: `%APPDATA%\Mozilla\Firefox\Profiles\*.default*\cache2\*`
- **Opera**: `%APPDATA%\Opera Software\Opera Stable\Cache\*`
- Log size of cache deleted for each browser
- Handle multiple profiles where applicable

#### C. Compact Databases
- **Chrome/Edge/Brave**: Compact SQLite databases (History, Cookies, etc.)
- **Firefox**: Compact places.sqlite, favicons.sqlite, cookies.sqlite
- Use SQLite VACUUM command
- Log database sizes before and after compaction

#### D. Delete Metrics Temp Files
- **Chrome/Edge**: Delete metrics temp files from User Data directories
- **Firefox**: Delete telemetry and metrics files
- Log count of files deleted

### 4. Shortcut Creation

Create shortcuts in two locations with these properties:

**Desktop Shortcut**: `%USERPROFILE%\Desktop\mTTCleaner.lnk`
**Start Menu**: `%APPDATA%\Microsoft\Windows\Start Menu\Programs\myTech.Today\mTTCleaner.lnk`

**Shortcut Properties:**
- **Name**: mTTCleaner
- **Description**: myTech.Today - mTTCleaner
- **Icon**: Download from `https://raw.githubusercontent.com/mytech-today-now/scripts/refs/heads/main/mytech.ico`
- **Target**: `powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\myTech.Today\mTTCleaner\mTTCleaner.ps1"`
- **Start In**: `%USERPROFILE%\myTech.Today\mTTCleaner\`
- **Run As**: Administrator
- **Window Style**: Normal
- **Hotkey**: Ctrl+Shift+M
- **Category**: myTech.Today

### 5. Scheduled Task Creation

Create a Windows Scheduled Task with these specifications:

**Task Properties:**
- **Name**: mTTCleaner
- **Path**: `\myTech.Today\mTTCleaner`
- **Description**: myTech.Today Browser Cache and Database Cleanup
- **Trigger**: Monthly on the 15th at 1:00 PM
- **User**: Currently logged in user
- **Run Level**: Highest (Administrator)
- **Action**: `powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\myTech.Today\mTTCleaner\mTTCleaner.ps1" -Automated`
- **Conditions**: 
  - Start only if computer is on AC power
  - Wake computer to run task
- **Settings**:
  - Allow task to run on demand
  - Stop task if it runs longer than 1 hour
  - If task fails, restart every 10 minutes up to 3 times

## Script Parameters

```powershell
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Automated,

    [Parameter(Mandatory = $false)]
    [switch]$SkipConfirmation,

    [Parameter(Mandatory = $false)]
    [ValidateSet('All', 'Chrome', 'Edge', 'Firefox', 'Brave', 'Opera', 'Vivaldi')]
    [string]$Browser = 'All',

    [Parameter(Mandatory = $false)]
    [switch]$SkipDatabaseCompaction,

    [Parameter(Mandatory = $false)]
    [switch]$CreateShortcuts,

    [Parameter(Mandatory = $false)]
    [switch]$CreateScheduledTask,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)
```

## Implementation Details

### Browser Detection Function
```powershell
function Get-InstalledBrowsers {
    # Detect installed browsers by checking:
    # 1. Registry entries (HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall)
    # 2. Common installation paths
    # 3. Running processes
    # Return array of browser objects with Name, Path, ProcessName, ProfilePath
}
```

### Cache Cleanup Function
```powershell
function Clear-BrowserCache {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Browser
    )
    # 1. Stop browser processes
    # 2. Calculate cache size before deletion
    # 3. Delete cache files
    # 4. Log results with size freed
}
```

### Database Compaction Function
```powershell
function Optimize-BrowserDatabase {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Browser
    )
    # 1. Locate SQLite databases
    # 2. Check database integrity
    # 3. Get size before compaction
    # 4. Run VACUUM command
    # 5. Get size after compaction
    # 6. Log space saved
}
```

### Metrics Cleanup Function
```powershell
function Remove-BrowserMetrics {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Browser
    )
    # 1. Locate metrics/telemetry files
    # 2. Count files before deletion
    # 3. Delete metrics files
    # 4. Log count of files removed
}
```

### Shortcut Creation Function
```powershell
function New-mTTCleanerShortcut {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Location
    )
    # 1. Download icon from GitHub
    # 2. Create WScript.Shell COM object
    # 3. Create shortcut with all specified properties
    # 4. Set RunAsAdministrator flag
    # 5. Log success/failure
}
```

### Scheduled Task Function
```powershell
function Register-mTTCleanerTask {
    # 1. Check if task already exists
    # 2. Create task folder \myTech.Today\ if needed
    # 3. Define task trigger (monthly, 15th, 1:00 PM)
    # 4. Define task action (PowerShell with script path)
    # 5. Set task settings (wake to run, AC power, etc.)
    # 6. Register task
    # 7. Log success/failure
}
```

## Error Handling Requirements

### Try-Catch Blocks
- Wrap all major operations in try-catch blocks
- Log detailed error information including stack trace
- Continue processing other browsers if one fails
- Return appropriate exit codes

### Specific Error Scenarios
1. **Access Denied**: Log warning and continue
2. **File Not Found**: Log info and continue
3. **Process Termination Failed**: Log warning and continue
4. **Database Locked**: Wait and retry up to 3 times
5. **Shortcut Creation Failed**: Log error but don't exit
6. **Task Registration Failed**: Log error but don't exit

## Logging Requirements

### Log Entry Types

**Script Start:**
```
[INFO] mTTCleaner v1.0.0 started
[INFO] Running as: DOMAIN\Username
[INFO] Administrator: Yes
```

**Browser Processing:**
```
[INFO] Processing Google Chrome...
[INFO] Stopping Chrome processes (3 processes)
[OK] Cache cleared: 1.2 GB freed
[OK] Database compacted: History (45 MB -> 32 MB, saved 13 MB)
[OK] Metrics files removed: 127 files
```

**Summary:**
```
[OK] Cleanup completed successfully
[INFO] Total cache cleared: 3.4 GB
[INFO] Total database space saved: 45 MB
[INFO] Total metrics files removed: 456 files
[INFO] Browsers processed: 5
[INFO] Duration: 2 minutes 34 seconds
```

## README.md Structure

```markdown
# mTTCleaner - Browser Cache and Database Cleanup Tool

## Overview
Comprehensive browser maintenance tool that cleans caches, compacts databases, and removes metrics files.

## Features
- Supports 15+ browsers
- Automatic cache cleanup
- SQLite database compaction
- Metrics file removal
- Scheduled monthly maintenance
- Desktop shortcuts
- Detailed logging

## Installation
[Installation instructions]

## Usage
[Usage examples]

## Supported Browsers
[List of browsers]

## Requirements
- Windows 10/11
- PowerShell 5.1 or later
- Administrator privileges

## License
Copyright (c) 2025 myTech.Today. All rights reserved.
```

## VERSION File Content
```
1.0.0
```

## .gitignore Content
```
# Logs
*.log
*.md.bak

# Temporary files
*.tmp
*.temp

# User-specific files
desktop.ini
Thumbs.db
```

## Testing Requirements

1. **Windows 10 Testing**: Verify all functionality on Windows 10
2. **Windows 11 Testing**: Verify all functionality on Windows 11
3. **Error Testing**: Test with browsers not installed, locked files, insufficient permissions
4. **Performance Testing**: Measure execution time with various browser combinations
5. **Scheduled Task Testing**: Verify task runs correctly on schedule

## Code Signing

Include placeholder for code signing:
```powershell
# TODO: Sign script with code signing certificate
# Set-AuthenticodeSignature -FilePath $PSCommandPath -Certificate $cert
```

## Success Criteria

- [x] Script runs without errors on Windows 10 and 11
- [x] All supported browsers are detected and cleaned
- [x] Logging is comprehensive and follows myTech.Today standards
- [x] Shortcuts are created with correct properties
- [x] Scheduled task is registered successfully
- [x] Error handling is robust and informative
- [x] README documentation is complete
- [x] Code follows PowerShell best practices
- [x] No emoji in output (ASCII indicators only)
- [x] Monthly log rotation implemented

