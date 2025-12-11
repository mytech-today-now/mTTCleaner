<#
.SYNOPSIS
    Browser cache and database cleanup tool for myTech.Today

.DESCRIPTION
    mTTCleaner is a comprehensive browser maintenance tool that:
    - Cleans browser caches for 15+ browsers
    - Compacts SQLite databases to reclaim space
    - Removes metrics and telemetry files
    - Creates desktop shortcuts for easy access
    - Sets up monthly scheduled maintenance tasks

.PARAMETER Automated
    Run in automated mode (skip user confirmation)

.PARAMETER SkipConfirmation
    Skip the user confirmation prompt

.PARAMETER Browser
    Target specific browser or 'All' for all installed browsers

.PARAMETER SkipDatabaseCompaction
    Skip database compaction operations

.PARAMETER CreateShortcuts
    Create desktop and start menu shortcuts

.PARAMETER CreateScheduledTask
    Create monthly scheduled task

.EXAMPLE
    .\mTTCleaner.ps1
    Run interactive cleanup for all browsers

.EXAMPLE
    .\mTTCleaner.ps1 -Browser Chrome -SkipConfirmation
    Clean only Chrome without confirmation

.EXAMPLE
    .\mTTCleaner.ps1 -CreateShortcuts -CreateScheduledTask
    Set up shortcuts and scheduled task

.NOTES
    File Name      : mTTCleaner.ps1
    Author         : Kyle C. Rode / myTech.Today
    Version        : 1.0.0
    DateCreated    : 2025-01-23
    LastModified   : 2025-01-23
    Copyright      : (c) 2025 myTech.Today. All rights reserved.
    Requires       : PowerShell 5.1 or later, Administrator privileges
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Automated,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipConfirmation,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('All', 'Chrome', 'Edge', 'Firefox', 'Brave', 'Opera', 'Vivaldi', 'LibreWolf', 'Waterfox', 'TorBrowser', 'Chromium', 'PaleMoon', 'UngoogledChromium', 'Midori', 'Min', 'OperaGX')]
    [string]$Browser = 'All',
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipDatabaseCompaction,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateShortcuts,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateScheduledTask
)

# Suppress progress bars to prevent spinner graphics in logs
$script:OriginalProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

# Script constants
$script:ScriptVersion = '1.0.0'
$script:ScriptName = 'mTTCleaner'
# Install location: %USERPROFILE%\myTech.Today\scripts\mTTCleaner\
$script:InstallPath = Join-Path $env:USERPROFILE 'myTech.Today\scripts\mTTCleaner'
$script:IconUrl = 'https://raw.githubusercontent.com/mytech-today-now/scripts/refs/heads/main/mytech.ico'
$script:IconPath = Join-Path $script:InstallPath 'mytech.ico'

# Statistics tracking
$script:Stats = @{
    TotalCacheCleared = 0
    TotalDatabaseSpaceSaved = 0
    TotalMetricsFilesRemoved = 0
    BrowsersProcessed = 0
    StartTime = Get-Date
}

# Load shared logging module
try {
    $loggingUrl = 'https://raw.githubusercontent.com/mytech-today-now/scripts/refs/heads/main/logging.ps1'
    Invoke-Expression (Invoke-WebRequest -Uri $loggingUrl -UseBasicParsing).Content
    Initialize-Log -ScriptName 'mTTCleaner' -ScriptVersion '1.0.0'
}
catch {
    Write-Error "Failed to load logging module: $_"
    exit 1
}

Write-Log "$script:ScriptName v$script:ScriptVersion started" -Level INFO
Write-Log "Running as: $env:USERDOMAIN\$env:USERNAME" -Level INFO
Write-Log "Administrator: Yes" -Level INFO

# Check if running from install location
$currentPath = $PSCommandPath
$isInstalled = $currentPath -like "$script:InstallPath*"

if (-not $isInstalled) {
    Write-Log "Script not running from install location. Deploying..." -Level INFO
    
    # Create install directory
    if (-not (Test-Path $script:InstallPath)) {
        New-Item -ItemType Directory -Path $script:InstallPath -Force | Out-Null
        Write-Log "Created install directory: $script:InstallPath" -Level INFO
    }
    
    # Copy script files
    $scriptDir = Split-Path -Parent $PSCommandPath
    $filesToCopy = @('mTTCleaner.ps1', 'README.md', 'README.html')
    
    foreach ($file in $filesToCopy) {
        $sourcePath = Join-Path $scriptDir $file
        $destPath = Join-Path $script:InstallPath $file
        
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Log "Copied $file to install location" -Level INFO
        }
    }
    
    # Re-launch from install location (only if not in WhatIf mode)
    $installedScript = Join-Path $script:InstallPath 'mTTCleaner.ps1'

    if ($WhatIfPreference) {
        Write-Log "WhatIf mode: Would launch from install location: $installedScript" -Level INFO
        exit 0
    }

    if (Test-Path $installedScript) {
        Write-Log "Launching from install location: $installedScript" -Level INFO
        $params = $PSBoundParameters
        & $installedScript @params
        exit $LASTEXITCODE
    }
    else {
        Write-Log "Failed to copy script to install location" -Level ERROR
        exit 1
    }
}

# User confirmation check
if (-not $Automated -and -not $SkipConfirmation) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  mTTCleaner - Browser Cleanup Tool" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    Write-Host "This script will:" -ForegroundColor Yellow
    Write-Host "  - Close all browser processes" -ForegroundColor White
    Write-Host "  - Delete browser caches" -ForegroundColor White
    Write-Host "  - Compact browser databases" -ForegroundColor White
    Write-Host "  - Remove metrics/telemetry files`n" -ForegroundColor White

    $confirmation = Read-Host "Type 'Yes' to continue"

    if ($confirmation -ne 'Yes') {
        Write-Log "User cancelled operation" -Level WARNING
        Write-Host "`n[CANCELLED] Operation cancelled by user" -ForegroundColor Yellow
        exit 0
    }

    Write-Log "User confirmed operation" -Level INFO
}

#region Browser Configuration

# Browser definitions with paths and process names
$script:BrowserDefinitions = @{
    'Chrome' = @{
        Name = 'Google Chrome'
        ProcessNames = @('chrome')
        ProfileRoot = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker\CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Edge' = @{
        Name = 'Microsoft Edge'
        ProcessNames = @('msedge')
        ProfileRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker\CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Brave' = @{
        Name = 'Brave Browser'
        ProcessNames = @('brave')
        ProfileRoot = Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\User Data'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker\CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Vivaldi' = @{
        Name = 'Vivaldi'
        ProcessNames = @('vivaldi')
        ProfileRoot = Join-Path $env:LOCALAPPDATA 'Vivaldi\User Data'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker\CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Opera' = @{
        Name = 'Opera'
        ProcessNames = @('opera')
        ProfileRoot = Join-Path $env:APPDATA 'Opera Software\Opera Stable'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'OperaGX' = @{
        Name = 'Opera GX'
        ProcessNames = @('opera')
        ProfileRoot = Join-Path $env:APPDATA 'Opera Software\Opera GX Stable'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Chromium' = @{
        Name = 'Chromium'
        ProcessNames = @('chrome')
        ProfileRoot = Join-Path $env:LOCALAPPDATA 'Chromium\User Data'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker\CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'UngoogledChromium' = @{
        Name = 'Ungoogled Chromium'
        ProcessNames = @('chrome')
        ProfileRoot = Join-Path $env:LOCALAPPDATA 'Chromium\User Data'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker\CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Midori' = @{
        Name = 'Midori Browser'
        ProcessNames = @('midori')
        ProfileRoot = Join-Path $env:LOCALAPPDATA 'Midori\User Data'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache')
        DatabasePaths = @('History', 'Cookies', 'Web Data')
        MetricsPaths = @('*metrics*')
        Type = 'Chromium'
    }
    'Min' = @{
        Name = 'Min Browser'
        ProcessNames = @('min')
        ProfileRoot = Join-Path $env:APPDATA 'Min\User Data'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache')
        DatabasePaths = @('History', 'Cookies')
        MetricsPaths = @('*metrics*')
        Type = 'Chromium'
    }
    'Firefox' = @{
        Name = 'Mozilla Firefox'
        ProcessNames = @('firefox')
        ProfileRoot = Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles'
        CachePaths = @('cache2', 'startupCache', 'OfflineCache')
        DatabasePaths = @('places.sqlite', 'favicons.sqlite', 'cookies.sqlite', 'formhistory.sqlite')
        MetricsPaths = @('*telemetry*', 'datareporting', 'saved-telemetry-pings')
        Type = 'Firefox'
    }
    'LibreWolf' = @{
        Name = 'LibreWolf'
        ProcessNames = @('librewolf')
        ProfileRoot = Join-Path $env:APPDATA 'LibreWolf\Profiles'
        CachePaths = @('cache2', 'startupCache', 'OfflineCache')
        DatabasePaths = @('places.sqlite', 'favicons.sqlite', 'cookies.sqlite')
        MetricsPaths = @('*telemetry*', 'datareporting')
        Type = 'Firefox'
    }
    'Waterfox' = @{
        Name = 'Waterfox'
        ProcessNames = @('waterfox')
        ProfileRoot = Join-Path $env:APPDATA 'Waterfox\Profiles'
        CachePaths = @('cache2', 'startupCache', 'OfflineCache')
        DatabasePaths = @('places.sqlite', 'favicons.sqlite', 'cookies.sqlite')
        MetricsPaths = @('*telemetry*', 'datareporting')
        Type = 'Firefox'
    }
    'TorBrowser' = @{
        Name = 'Tor Browser'
        ProcessNames = @('firefox')
        ProfileRoot = Join-Path $env:APPDATA 'Tor Browser\Browser\TorBrowser\Data\Browser'
        CachePaths = @('cache2', 'startupCache', 'OfflineCache')
        DatabasePaths = @('places.sqlite', 'favicons.sqlite', 'cookies.sqlite')
        MetricsPaths = @('*telemetry*')
        Type = 'Firefox'
    }
    'PaleMoon' = @{
        Name = 'Pale Moon'
        ProcessNames = @('palemoon')
        ProfileRoot = Join-Path $env:APPDATA 'Moonchild Productions\Pale Moon\Profiles'
        CachePaths = @('cache2', 'startupCache', 'OfflineCache')
        DatabasePaths = @('places.sqlite', 'favicons.sqlite', 'cookies.sqlite')
        MetricsPaths = @('*telemetry*')
        Type = 'Firefox'
    }
}

#endregion

#region Helper Functions

function Get-FolderSize {
    <#
    .SYNOPSIS
        Calculate total size of a folder in bytes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        return 0
    }

    try {
        $size = (Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum

        if ($null -eq $size) { return 0 }
        return $size
    }
    catch {
        return 0
    }
}

function Format-FileSize {
    <#
    .SYNOPSIS
        Format bytes into human-readable size
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [long]$Bytes
    )

    if ($Bytes -ge 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    }
    elseif ($Bytes -ge 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    }
    elseif ($Bytes -ge 1KB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    }
    else {
        return "$Bytes bytes"
    }
}

function Stop-BrowserProcesses {
    <#
    .SYNOPSIS
        Stop all processes for a specific browser
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$BrowserConfig
    )

    $processCount = 0

    foreach ($processName in $BrowserConfig.ProcessNames) {
        $processes = Get-Process -Name $processName -ErrorAction SilentlyContinue

        if ($processes) {
            foreach ($process in $processes) {
                try {
                    $process.Kill()
                    $processCount++
                }
                catch {
                    Write-Log "Failed to stop process $($process.Name) (PID: $($process.Id)): $_" -Level WARNING
                }
            }
        }
    }

    if ($processCount -gt 0) {
        Write-Log "Stopped $processCount $($BrowserConfig.Name) process(es)" -Level INFO
        Start-Sleep -Seconds 2  # Wait for processes to fully terminate
    }

    return $processCount
}

function Get-BrowserProfiles {
    <#
    .SYNOPSIS
        Get all profile directories for a browser
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$BrowserConfig
    )

    $profiles = @()

    if (-not (Test-Path $BrowserConfig.ProfileRoot)) {
        return $profiles
    }

    if ($BrowserConfig.Type -eq 'Chromium') {
        # Chromium browsers use Default, Profile 1, Profile 2, etc.
        $profileDirs = Get-ChildItem -Path $BrowserConfig.ProfileRoot -Directory -ErrorAction SilentlyContinue |
                       Where-Object { $_.Name -match '^(Default|Profile \d+)$' }

        foreach ($dir in $profileDirs) {
            $profiles += $dir.FullName
        }
    }
    elseif ($BrowserConfig.Type -eq 'Firefox') {
        # Firefox browsers use random profile names
        $profileDirs = Get-ChildItem -Path $BrowserConfig.ProfileRoot -Directory -ErrorAction SilentlyContinue

        foreach ($dir in $profileDirs) {
            $profiles += $dir.FullName
        }
    }

    return $profiles
}

#endregion

#region Cleanup Functions

function Clear-BrowserCache {
    <#
    .SYNOPSIS
        Clear cache files for a browser
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BrowserName,

        [Parameter(Mandatory = $true)]
        [hashtable]$BrowserConfig
    )

    Write-Log "Clearing cache for $($BrowserConfig.Name)..." -Level INFO

    $profiles = Get-BrowserProfiles -BrowserConfig $BrowserConfig

    if ($profiles.Count -eq 0) {
        Write-Log "$($BrowserConfig.Name) not installed or no profiles found" -Level INFO
        return 0
    }

    $totalCacheCleared = 0

    foreach ($profilePath in $profiles) {
        foreach ($cachePath in $BrowserConfig.CachePaths) {
            $fullCachePath = Join-Path $profilePath $cachePath

            if (Test-Path $fullCachePath) {
                try {
                    $sizeBefore = Get-FolderSize -Path $fullCachePath

                    Remove-Item -Path $fullCachePath -Recurse -Force -ErrorAction Stop

                    $totalCacheCleared += $sizeBefore

                    Write-Log "Cleared cache: $cachePath ($(Format-FileSize $sizeBefore))" -Level INFO
                }
                catch {
                    Write-Log "Failed to clear cache $cachePath`: $_" -Level WARNING
                }
            }
        }
    }

    if ($totalCacheCleared -gt 0) {
        Write-Log "Total cache cleared for $($BrowserConfig.Name): $(Format-FileSize $totalCacheCleared)" -Level SUCCESS
    }

    return $totalCacheCleared
}

function Optimize-BrowserDatabase {
    <#
    .SYNOPSIS
        Compact SQLite databases for a browser
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BrowserName,

        [Parameter(Mandatory = $true)]
        [hashtable]$BrowserConfig
    )

    if ($SkipDatabaseCompaction) {
        Write-Log "Skipping database compaction for $($BrowserConfig.Name)" -Level INFO
        return 0
    }

    Write-Log "Compacting databases for $($BrowserConfig.Name)..." -Level INFO

    $profiles = Get-BrowserProfiles -BrowserConfig $BrowserConfig

    if ($profiles.Count -eq 0) {
        return 0
    }

    $totalSpaceSaved = 0

    foreach ($profilePath in $profiles) {
        foreach ($dbPath in $BrowserConfig.DatabasePaths) {
            $fullDbPath = Join-Path $profilePath $dbPath

            if (Test-Path $fullDbPath) {
                try {
                    $sizeBefore = (Get-Item $fullDbPath).Length

                    # Use SQLite VACUUM command to compact database
                    # Try to use sqlite3.exe if available, otherwise skip
                    $sqlite3 = Get-Command sqlite3.exe -ErrorAction SilentlyContinue

                    if ($sqlite3) {
                        $result = & sqlite3.exe $fullDbPath "VACUUM;" 2>&1

                        if ($LASTEXITCODE -eq 0) {
                            $sizeAfter = (Get-Item $fullDbPath).Length
                            $spaceSaved = $sizeBefore - $sizeAfter

                            if ($spaceSaved -gt 0) {
                                $totalSpaceSaved += $spaceSaved
                                Write-Log "Compacted $dbPath ($(Format-FileSize $sizeBefore) -> $(Format-FileSize $sizeAfter), saved $(Format-FileSize $spaceSaved))" -Level SUCCESS
                            }
                        }
                        else {
                            Write-Log "Failed to compact $dbPath`: $result" -Level WARNING
                        }
                    }
                    else {
                        Write-Log "SQLite3 not found, skipping database compaction" -Level WARNING
                        break
                    }
                }
                catch {
                    Write-Log "Failed to compact database $dbPath`: $_" -Level WARNING
                }
            }
        }
    }

    if ($totalSpaceSaved -gt 0) {
        Write-Log "Total database space saved for $($BrowserConfig.Name): $(Format-FileSize $totalSpaceSaved)" -Level SUCCESS
    }

    return $totalSpaceSaved
}

function Remove-BrowserMetrics {
    <#
    .SYNOPSIS
        Remove metrics and telemetry files for a browser
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BrowserName,

        [Parameter(Mandatory = $true)]
        [hashtable]$BrowserConfig
    )

    Write-Log "Removing metrics files for $($BrowserConfig.Name)..." -Level INFO

    $profiles = Get-BrowserProfiles -BrowserConfig $BrowserConfig

    if ($profiles.Count -eq 0) {
        return 0
    }

    $totalFilesRemoved = 0

    foreach ($profilePath in $profiles) {
        foreach ($metricsPattern in $BrowserConfig.MetricsPaths) {
            try {
                $metricsFiles = Get-ChildItem -Path $profilePath -Filter $metricsPattern -Recurse -File -ErrorAction SilentlyContinue

                foreach ($file in $metricsFiles) {
                    try {
                        Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                        $totalFilesRemoved++
                    }
                    catch {
                        Write-Log "Failed to remove metrics file $($file.Name): $_" -Level WARNING
                    }
                }
            }
            catch {
                # Silently continue if pattern doesn't match
            }
        }
    }

    if ($totalFilesRemoved -gt 0) {
        Write-Log "Removed $totalFilesRemoved metrics file(s) for $($BrowserConfig.Name)" -Level SUCCESS
    }

    return $totalFilesRemoved
}

#endregion

#region Shortcut and Task Functions

function New-mTTCleanerShortcut {
    <#
    .SYNOPSIS
        Create desktop and start menu shortcuts
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Location
    )

    try {
        # Download icon if not exists
        if (-not (Test-Path $script:IconPath)) {
            Write-Log "Downloading icon from GitHub..." -Level INFO
            Invoke-WebRequest -Uri $script:IconUrl -OutFile $script:IconPath -UseBasicParsing
            Write-Log "Icon downloaded successfully" -Level SUCCESS
        }

        # Create shortcut
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($Location)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$script:InstallPath\mTTCleaner.ps1`""
        $shortcut.WorkingDirectory = $script:InstallPath
        $shortcut.Description = "myTech.Today - mTTCleaner"
        $shortcut.IconLocation = $script:IconPath
        $shortcut.WindowStyle = 1  # Normal window
        $shortcut.Hotkey = "CTRL+SHIFT+M"
        $shortcut.Save()

        # Set to run as administrator
        $bytes = [System.IO.File]::ReadAllBytes($Location)
        $bytes[0x15] = $bytes[0x15] -bor 0x20  # Set byte 21 (0x15) bit 6 (0x20) to run as admin
        [System.IO.File]::WriteAllBytes($Location, $bytes)

        Write-Log "Created shortcut: $Location" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Failed to create shortcut $Location`: $_" -Level ERROR
        return $false
    }
}

function Register-mTTCleanerTask {
    <#
    .SYNOPSIS
        Create scheduled task for monthly maintenance in the myTech.Today folder
    .DESCRIPTION
        Creates a scheduled task that runs on the 15th of every month at 1:00 PM
        under the \myTech.Today\ folder in Task Scheduler
    #>
    [CmdletBinding()]
    param()

    try {
        $taskName = "mTTCleaner"
        $taskPath = "\myTech.Today\"

        Write-Log "Creating scheduled task: $taskPath$taskName" -Level INFO
        Write-Log "Schedule: Monthly on the 15th at 1:00 PM" -Level INFO

        # Check if task already exists
        $existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue

        if ($existingTask) {
            Write-Log "Scheduled task already exists, removing old task..." -Level INFO
            Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
            Write-Log "Old task removed successfully" -Level INFO
        }

        # Create task using Task Scheduler COM object for monthly trigger support
        $service = New-Object -ComObject Schedule.Service
        $service.Connect()

        # Get or create the myTech.Today folder
        $rootFolder = $service.GetFolder("\")
        $folderName = "myTech.Today"

        # Try to get the folder first
        try {
            $folder = $rootFolder.GetFolder($folderName)
            Write-Log "Task folder already exists: $taskPath" -Level INFO
        }
        catch {
            # Folder doesn't exist, create it
            try {
                $folder = $rootFolder.CreateFolder($folderName)
                Write-Log "Created task folder: $taskPath" -Level INFO
            }
            catch {
                # If creation fails (maybe it was just created), try to get it again
                $folder = $rootFolder.GetFolder($folderName)
                Write-Log "Task folder retrieved after creation attempt: $taskPath" -Level INFO
            }
        }

        # Create task definition
        $taskDefinition = $service.NewTask(0)
        $taskDefinition.RegistrationInfo.Description = "myTech.Today Browser Cache and Database Cleanup - Runs monthly on the 15th at 1:00 PM to clean browser caches, compact databases, and remove metrics files"
        $taskDefinition.RegistrationInfo.Author = $env:USERNAME

        # Create monthly trigger (runs on 15th of every month at 1:00 PM)
        $triggers = $taskDefinition.Triggers
        $trigger = $triggers.Create(4)  # 4 = Monthly trigger

        # Set start boundary - use December 15, 2025 at 1:00 PM as the first run
        $trigger.StartBoundary = "2025-12-15T13:00:00"
        $trigger.DaysOfMonth = 0x4000  # Bit 15 set (day 15)
        $trigger.MonthsOfYear = 0xFFF  # All months (bits 1-12 set)
        $trigger.Enabled = $true

        Write-Log "Task trigger configured: Monthly on day 15 at 1:00 PM" -Level INFO

        # Create action
        $scriptPath = Join-Path $script:InstallPath 'mTTCleaner.ps1'
        $actions = $taskDefinition.Actions
        $action = $actions.Create(0)  # 0 = Execute action
        $action.Path = "powershell.exe"
        $action.Arguments = "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$scriptPath`" -Automated"

        Write-Log "Task action: powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$scriptPath`" -Automated" -Level INFO

        # Configure settings
        $settings = $taskDefinition.Settings
        $settings.Enabled = $true
        $settings.StartWhenAvailable = $true
        $settings.WakeToRun = $true
        $settings.AllowDemandStart = $true
        $settings.AllowHardTerminate = $true
        $settings.ExecutionTimeLimit = "PT2H"  # 2 hours
        $settings.RestartCount = 3
        $settings.RestartInterval = "PT10M"  # 10 minutes

        # Configure principal (run with highest privileges)
        $principal = $taskDefinition.Principal
        $principal.UserId = $env:USERNAME
        $principal.LogonType = 3  # 3 = S4U (Service For User)
        $principal.RunLevel = 1  # 1 = Highest privileges

        Write-Log "Task principal: User=$env:USERNAME, LogonType=S4U, RunLevel=Highest" -Level INFO

        # Register the task
        # Parameters: TaskName, TaskDefinition, Flags, UserId, Password, LogonType, SecurityDescriptor
        $folder.RegisterTaskDefinition($taskName, $taskDefinition, 6, $null, $null, 3) | Out-Null

        Write-Log "Scheduled task created successfully: $taskPath$taskName" -Level SUCCESS
        Write-Log "Task will run monthly on the 15th at 1:00 PM" -Level SUCCESS

        # Release COM object
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($service) | Out-Null

        return $true
    }
    catch {
        Write-Log "Failed to create scheduled task: $_" -Level ERROR
        Write-Log "Error details: $($_.Exception.Message)" -Level ERROR
        Write-Log "Error at line: $($_.InvocationInfo.ScriptLineNumber)" -Level ERROR
        return $false
    }
}

#endregion

#region Main Execution

try {
    # Handle shortcut creation
    if ($CreateShortcuts) {
        Write-Log "Creating shortcuts..." -Level INFO

        $desktopPath = Join-Path $env:USERPROFILE 'Desktop\mTTCleaner.lnk'
        $startMenuPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\myTech.Today'

        if (-not (Test-Path $startMenuPath)) {
            New-Item -ItemType Directory -Path $startMenuPath -Force | Out-Null
        }

        $startMenuShortcut = Join-Path $startMenuPath 'mTTCleaner.lnk'

        New-mTTCleanerShortcut -Location $desktopPath
        New-mTTCleanerShortcut -Location $startMenuShortcut
    }

    # Handle scheduled task creation
    if ($CreateScheduledTask) {
        Write-Log "Creating scheduled task..." -Level INFO
        Register-mTTCleanerTask
    }

    # Determine which browsers to process
    $browsersToProcess = @()

    if ($Browser -eq 'All') {
        $browsersToProcess = $script:BrowserDefinitions.Keys
    }
    else {
        $browsersToProcess = @($Browser)
    }

    Write-Log "Processing $($browsersToProcess.Count) browser(s)..." -Level INFO

    # Process each browser
    foreach ($browserName in $browsersToProcess) {
        if (-not $script:BrowserDefinitions.ContainsKey($browserName)) {
            Write-Log "Unknown browser: $browserName" -Level WARNING
            continue
        }

        $browserConfig = $script:BrowserDefinitions[$browserName]

        Write-Log "`n========================================" -Level INFO
        Write-Log "Processing $($browserConfig.Name)..." -Level INFO
        Write-Log "========================================" -Level INFO

        # Stop browser processes
        $processCount = Stop-BrowserProcesses -BrowserConfig $browserConfig

        if ($processCount -eq 0) {
            # Check if browser is installed
            $profiles = Get-BrowserProfiles -BrowserConfig $browserConfig
            if ($profiles.Count -eq 0) {
                Write-Log "$($browserConfig.Name) not installed, skipping" -Level INFO
                continue
            }
        }

        # Clear cache
        $cacheCleared = Clear-BrowserCache -BrowserName $browserName -BrowserConfig $browserConfig
        $script:Stats.TotalCacheCleared += $cacheCleared

        # Compact databases
        $spaceSaved = Optimize-BrowserDatabase -BrowserName $browserName -BrowserConfig $browserConfig
        $script:Stats.TotalDatabaseSpaceSaved += $spaceSaved

        # Remove metrics files
        $metricsRemoved = Remove-BrowserMetrics -BrowserName $browserName -BrowserConfig $browserConfig
        $script:Stats.TotalMetricsFilesRemoved += $metricsRemoved

        $script:Stats.BrowsersProcessed++
    }

    # Calculate duration
    $duration = (Get-Date) - $script:Stats.StartTime

    # Log summary
    Write-Log "`n========================================" -Level INFO
    Write-Log "Cleanup Completed Successfully" -Level SUCCESS
    Write-Log "========================================" -Level INFO
    Write-Log "Total cache cleared: $(Format-FileSize $script:Stats.TotalCacheCleared)" -Level INFO
    Write-Log "Total database space saved: $(Format-FileSize $script:Stats.TotalDatabaseSpaceSaved)" -Level INFO
    Write-Log "Total metrics files removed: $($script:Stats.TotalMetricsFilesRemoved)" -Level INFO
    Write-Log "Browsers processed: $($script:Stats.BrowsersProcessed)" -Level INFO
    Write-Log "Duration: $($duration.Minutes) minutes $($duration.Seconds) seconds" -Level INFO

    exit 0
}
catch {
    Write-Log "Script failed with error: $_" -Level ERROR
    Write-Log $_.ScriptStackTrace -Level ERROR
    exit 1
}
finally {
    # Restore progress preference
    $ProgressPreference = $script:OriginalProgressPreference
}

#endregion

