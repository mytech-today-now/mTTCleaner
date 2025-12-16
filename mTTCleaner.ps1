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

#Requires -Version 7.0

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

#region Platform Detection and Configuration

# Detect current platform
$script:CurrentPlatform = if ($IsWindows) { 'Windows' }
                         elseif ($IsMacOS) { 'macOS' }
                         elseif ($IsLinux) { 'Linux' }
                         else { 'Unknown' }

Write-Verbose "Detected platform: $script:CurrentPlatform"

# Platform-specific path resolution
function Get-PlatformPath {
    <#
    .SYNOPSIS
        Resolves platform-specific paths for cross-platform compatibility
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('InstallDir', 'DataRoot', 'ConfigDir', 'LogDir', 'CacheDir', 'TempDir')]
        [string]$PathType,

        [Parameter(Mandatory = $false)]
        [string]$SubPath = ''
    )

    $basePath = switch ($PathType) {
        'InstallDir' {
            if ($IsWindows) {
                Join-Path $env:LOCALAPPDATA 'myTech.Today\mTTCleaner'
            }
            elseif ($IsMacOS) {
                Join-Path $HOME 'Library/Application Support/myTech.Today/mTTCleaner'
            }
            elseif ($IsLinux) {
                Join-Path $HOME '.local/share/myTech.Today/mTTCleaner'
            }
        }
        'DataRoot' {
            if ($IsWindows) {
                Join-Path $env:LOCALAPPDATA 'myTech.Today\mTTCleaner'
            }
            elseif ($IsMacOS) {
                Join-Path $HOME 'Library/Preferences/myTech.Today/mTTCleaner'
            }
            elseif ($IsLinux) {
                $xdgConfig = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
                Join-Path $xdgConfig 'myTech.Today/mTTCleaner'
            }
        }
        'ConfigDir' {
            Join-Path (Get-PlatformPath -PathType DataRoot) 'config'
        }
        'LogDir' {
            if ($IsWindows) {
                Join-Path (Get-PlatformPath -PathType DataRoot) 'logs'
            }
            elseif ($IsMacOS) {
                Join-Path $HOME 'Library/Logs/myTech.Today/mTTCleaner'
            }
            elseif ($IsLinux) {
                Join-Path $HOME '.local/share/myTech.Today/mTTCleaner/logs'
            }
        }
        'CacheDir' {
            if ($IsWindows) {
                Join-Path $env:LOCALAPPDATA 'myTech.Today\mTTCleaner\cache'
            }
            elseif ($IsMacOS) {
                Join-Path $HOME 'Library/Caches/myTech.Today/mTTCleaner'
            }
            elseif ($IsLinux) {
                $xdgCache = if ($env:XDG_CACHE_HOME) { $env:XDG_CACHE_HOME } else { Join-Path $HOME '.cache' }
                Join-Path $xdgCache 'myTech.Today/mTTCleaner'
            }
        }
        'TempDir' {
            if ($IsWindows) {
                $env:TEMP
            }
            elseif ($IsMacOS -or $IsLinux) {
                '/tmp'
            }
        }
    }

    if ($SubPath) {
        return Join-Path $basePath $SubPath
    }
    return $basePath
}

# Check if running with elevated privileges (optional, not required)
function Test-IsElevated {
    <#
    .SYNOPSIS
        Checks if the current session has elevated privileges
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    if ($IsWindows) {
        $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    elseif ($IsMacOS -or $IsLinux) {
        return (id -u) -eq 0
    }
    return $false
}

$script:IsElevated = Test-IsElevated
if ($script:IsElevated) {
    Write-Verbose "Running with elevated privileges"
}
else {
    Write-Verbose "Running without elevated privileges (some operations may be limited)"
}

#endregion

# Suppress progress bars to prevent spinner graphics in logs
$script:OriginalProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

# Script constants
$script:ScriptVersion = '2.0.0'  # Updated for cross-platform support
$script:ScriptName = 'mTTCleaner'
$script:InstallPath = Get-PlatformPath -PathType InstallDir
$script:LogPath = Get-PlatformPath -PathType LogDir
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

#region Logging Functions

# Cross-platform logging implementation
$script:LogFile = Join-Path $script:LogPath "$script:ScriptName.log"

function Initialize-Logging {
    <#
    .SYNOPSIS
        Initialize logging directory and file
    #>
    [CmdletBinding()]
    param()

    try {
        if (-not (Test-Path $script:LogPath)) {
            New-Item -ItemType Directory -Path $script:LogPath -Force | Out-Null
        }

        # Create log file if it doesn't exist
        if (-not (Test-Path $script:LogFile)) {
            New-Item -ItemType File -Path $script:LogFile -Force | Out-Null
        }

        return $true
    }
    catch {
        Write-Warning "Failed to initialize logging: $_"
        return $false
    }
}

function Write-Log {
    <#
    .SYNOPSIS
        Write a log message to file and console
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    # Write to file
    try {
        Add-Content -Path $script:LogFile -Value $logMessage -ErrorAction SilentlyContinue
    }
    catch {
        # Silently continue if logging fails
    }

    # Write to console with color
    $color = switch ($Level) {
        'SUCCESS' { 'Green' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
        'DEBUG'   { 'Gray' }
        default   { 'White' }
    }

    Write-Host $logMessage -ForegroundColor $color
}

#endregion

# Initialize logging
Initialize-Logging | Out-Null

# Log startup information
Write-Log "$script:ScriptName v$script:ScriptVersion started on $script:CurrentPlatform" -Level INFO
$currentUser = if ($IsWindows) { "$env:USERDOMAIN\$env:USERNAME" } else { $env:USER }
Write-Log "Running as: $currentUser" -Level INFO
Write-Log "Elevated privileges: $script:IsElevated" -Level INFO
Write-Log "Log file: $script:LogFile" -Level INFO

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
    Write-Host "  Cross-Platform Edition v$script:ScriptVersion" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    Write-Host "Platform: $script:CurrentPlatform" -ForegroundColor Green
    Write-Host "Elevated: $script:IsElevated`n" -ForegroundColor $(if ($script:IsElevated) { 'Green' } else { 'Yellow' })
    Write-Host "This script will:" -ForegroundColor Yellow
    Write-Host "  - Close all browser processes" -ForegroundColor White
    Write-Host "  - Delete browser caches" -ForegroundColor White
    Write-Host "  - Compact browser databases (requires sqlite3)" -ForegroundColor White
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

function Get-BrowserPath {
    <#
    .SYNOPSIS
        Get platform-specific browser profile paths
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BrowserName
    )

    $paths = @{
        Windows = @{
            Chrome = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'
            Edge = Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data'
            Firefox = Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles'
            Brave = Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\User Data'
            Opera = Join-Path $env:APPDATA 'Opera Software\Opera Stable'
            OperaGX = Join-Path $env:APPDATA 'Opera Software\Opera GX Stable'
            Vivaldi = Join-Path $env:LOCALAPPDATA 'Vivaldi\User Data'
            Chromium = Join-Path $env:LOCALAPPDATA 'Chromium\User Data'
            UngoogledChromium = Join-Path $env:LOCALAPPDATA 'Chromium\User Data'
            LibreWolf = Join-Path $env:APPDATA 'LibreWolf\Profiles'
            Waterfox = Join-Path $env:APPDATA 'Waterfox\Profiles'
            TorBrowser = Join-Path $env:APPDATA 'Tor Browser\Browser\TorBrowser\Data\Browser'
            PaleMoon = Join-Path $env:APPDATA 'Moonchild Productions\Pale Moon\Profiles'
            Midori = Join-Path $env:LOCALAPPDATA 'Midori\User Data'
            Min = Join-Path $env:APPDATA 'Min\User Data'
        }
        macOS = @{
            Chrome = Join-Path $HOME 'Library/Application Support/Google/Chrome'
            Edge = Join-Path $HOME 'Library/Application Support/Microsoft Edge'
            Firefox = Join-Path $HOME 'Library/Application Support/Firefox/Profiles'
            Brave = Join-Path $HOME 'Library/Application Support/BraveSoftware/Brave-Browser'
            Opera = Join-Path $HOME 'Library/Application Support/com.operasoftware.Opera'
            OperaGX = Join-Path $HOME 'Library/Application Support/com.operasoftware.OperaGX'
            Vivaldi = Join-Path $HOME 'Library/Application Support/Vivaldi'
            Chromium = Join-Path $HOME 'Library/Application Support/Chromium'
            UngoogledChromium = Join-Path $HOME 'Library/Application Support/Chromium'
            LibreWolf = Join-Path $HOME 'Library/Application Support/librewolf/Profiles'
            Waterfox = Join-Path $HOME 'Library/Application Support/Waterfox/Profiles'
            TorBrowser = Join-Path $HOME 'Library/Application Support/TorBrowser-Data/Browser'
            PaleMoon = Join-Path $HOME 'Library/Application Support/Pale Moon/Profiles'
            Midori = Join-Path $HOME 'Library/Application Support/Midori'
            Min = Join-Path $HOME 'Library/Application Support/Min'
        }
        Linux = @{
            Chrome = Join-Path $HOME '.config/google-chrome'
            Edge = Join-Path $HOME '.config/microsoft-edge'
            Firefox = Join-Path $HOME '.mozilla/firefox'
            Brave = Join-Path $HOME '.config/BraveSoftware/Brave-Browser'
            Opera = Join-Path $HOME '.config/opera'
            OperaGX = Join-Path $HOME '.config/opera-gx'
            Vivaldi = Join-Path $HOME '.config/vivaldi'
            Chromium = Join-Path $HOME '.config/chromium'
            UngoogledChromium = Join-Path $HOME '.config/chromium'
            LibreWolf = Join-Path $HOME '.librewolf'
            Waterfox = Join-Path $HOME '.waterfox'
            TorBrowser = Join-Path $HOME '.local/share/torbrowser/tbb/x86_64/tor-browser/Browser/TorBrowser/Data/Browser'
            PaleMoon = Join-Path $HOME '.moonchild productions/pale moon'
            Midori = Join-Path $HOME '.config/midori'
            Min = Join-Path $HOME '.config/Min'
        }
    }

    $platform = $script:CurrentPlatform
    if ($paths.ContainsKey($platform) -and $paths[$platform].ContainsKey($BrowserName)) {
        return $paths[$platform][$BrowserName]
    }

    return $null
}

# Browser definitions with paths and process names
$script:BrowserDefinitions = @{
    'Chrome' = @{
        Name = 'Google Chrome'
        ProcessNames = @('chrome')
        ProfileRoot = Get-BrowserPath -BrowserName 'Chrome'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker/CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Edge' = @{
        Name = 'Microsoft Edge'
        ProcessNames = @('msedge', 'Microsoft Edge')
        ProfileRoot = Get-BrowserPath -BrowserName 'Edge'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker/CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Brave' = @{
        Name = 'Brave Browser'
        ProcessNames = @('brave', 'Brave Browser')
        ProfileRoot = Get-BrowserPath -BrowserName 'Brave'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker/CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Vivaldi' = @{
        Name = 'Vivaldi'
        ProcessNames = @('vivaldi', 'Vivaldi')
        ProfileRoot = Get-BrowserPath -BrowserName 'Vivaldi'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker/CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Opera' = @{
        Name = 'Opera'
        ProcessNames = @('opera')
        ProfileRoot = Get-BrowserPath -BrowserName 'Opera'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'OperaGX' = @{
        Name = 'Opera GX'
        ProcessNames = @('opera')
        ProfileRoot = Get-BrowserPath -BrowserName 'OperaGX'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Chromium' = @{
        Name = 'Chromium'
        ProcessNames = @('chrome', 'chromium', 'chromium-browser')
        ProfileRoot = Get-BrowserPath -BrowserName 'Chromium'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker/CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'UngoogledChromium' = @{
        Name = 'Ungoogled Chromium'
        ProcessNames = @('chrome', 'chromium')
        ProfileRoot = Get-BrowserPath -BrowserName 'UngoogledChromium'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker/CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Midori' = @{
        Name = 'Midori Browser'
        ProcessNames = @('midori')
        ProfileRoot = Get-BrowserPath -BrowserName 'Midori'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache')
        DatabasePaths = @('History', 'Cookies', 'Web Data')
        MetricsPaths = @('*metrics*')
        Type = 'Chromium'
    }
    'Min' = @{
        Name = 'Min Browser'
        ProcessNames = @('min')
        ProfileRoot = Get-BrowserPath -BrowserName 'Min'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache')
        DatabasePaths = @('History', 'Cookies')
        MetricsPaths = @('*metrics*')
        Type = 'Chromium'
    }
    'Firefox' = @{
        Name = 'Mozilla Firefox'
        ProcessNames = @('firefox', 'firefox-bin')
        ProfileRoot = Get-BrowserPath -BrowserName 'Firefox'
        CachePaths = @('cache2', 'startupCache', 'OfflineCache')
        DatabasePaths = @('places.sqlite', 'favicons.sqlite', 'cookies.sqlite', 'formhistory.sqlite')
        MetricsPaths = @('*telemetry*', 'datareporting', 'saved-telemetry-pings')
        Type = 'Firefox'
    }
    'LibreWolf' = @{
        Name = 'LibreWolf'
        ProcessNames = @('librewolf', 'librewolf-bin')
        ProfileRoot = Get-BrowserPath -BrowserName 'LibreWolf'
        CachePaths = @('cache2', 'startupCache', 'OfflineCache')
        DatabasePaths = @('places.sqlite', 'favicons.sqlite', 'cookies.sqlite')
        MetricsPaths = @('*telemetry*', 'datareporting')
        Type = 'Firefox'
    }
    'Waterfox' = @{
        Name = 'Waterfox'
        ProcessNames = @('waterfox', 'waterfox-bin')
        ProfileRoot = Get-BrowserPath -BrowserName 'Waterfox'
        CachePaths = @('cache2', 'startupCache', 'OfflineCache')
        DatabasePaths = @('places.sqlite', 'favicons.sqlite', 'cookies.sqlite')
        MetricsPaths = @('*telemetry*', 'datareporting')
        Type = 'Firefox'
    }
    'TorBrowser' = @{
        Name = 'Tor Browser'
        ProcessNames = @('firefox', 'tor-browser')
        ProfileRoot = Get-BrowserPath -BrowserName 'TorBrowser'
        CachePaths = @('cache2', 'startupCache', 'OfflineCache')
        DatabasePaths = @('places.sqlite', 'favicons.sqlite', 'cookies.sqlite')
        MetricsPaths = @('*telemetry*')
        Type = 'Firefox'
    }
    'PaleMoon' = @{
        Name = 'Pale Moon'
        ProcessNames = @('palemoon', 'palemoon-bin')
        ProfileRoot = Get-BrowserPath -BrowserName 'PaleMoon'
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
        Stop all processes for a specific browser (cross-platform)
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
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
                    if ($PSCmdlet.ShouldProcess("$($process.Name) (PID: $($process.Id))", "Stop process")) {
                        $process.Kill()
                        $processCount++
                        Write-Verbose "Stopped process: $($process.Name) (PID: $($process.Id))"
                    }
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
        Get all profile directories for a browser (cross-platform)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$BrowserConfig
    )

    $profiles = @()

    if (-not $BrowserConfig.ProfileRoot) {
        Write-Verbose "No profile root defined for $($BrowserConfig.Name)"
        return $profiles
    }

    if (-not (Test-Path $BrowserConfig.ProfileRoot)) {
        Write-Verbose "Profile root does not exist: $($BrowserConfig.ProfileRoot)"
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

    Write-Verbose "Found $($profiles.Count) profile(s) for $($BrowserConfig.Name)"
    return $profiles
}

#endregion

#region Cleanup Functions

function Clear-BrowserCache {
    <#
    .SYNOPSIS
        Clear cache files for a browser (cross-platform with -WhatIf support)
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
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

                    if ($PSCmdlet.ShouldProcess($fullCachePath, "Remove cache directory")) {
                        Remove-Item -Path $fullCachePath -Recurse -Force -ErrorAction Stop
                        $totalCacheCleared += $sizeBefore
                        Write-Log "Cleared cache: $cachePath ($(Format-FileSize $sizeBefore))" -Level INFO
                    }
                    else {
                        Write-Log "[WHATIF] Would clear cache: $cachePath ($(Format-FileSize $sizeBefore))" -Level INFO
                        $totalCacheCleared += $sizeBefore
                    }
                }
                catch {
                    Write-Log "Failed to clear cache ${cachePath}: $_" -Level WARNING
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
        Compact SQLite databases for a browser (cross-platform)
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
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

    # Try to find sqlite3 command (cross-platform)
    $sqlite3Cmd = $null
    if ($IsWindows) {
        $sqlite3Cmd = Get-Command sqlite3.exe -ErrorAction SilentlyContinue
    }
    else {
        $sqlite3Cmd = Get-Command sqlite3 -ErrorAction SilentlyContinue
    }

    if (-not $sqlite3Cmd) {
        Write-Log "SQLite3 command not found. Install sqlite3 to enable database compaction." -Level WARNING
        Write-Log "  Windows: Download from https://www.sqlite.org/download.html" -Level INFO
        Write-Log "  macOS: brew install sqlite3" -Level INFO
        Write-Log "  Linux: sudo apt install sqlite3 (Debian/Ubuntu) or sudo yum install sqlite (RHEL/CentOS)" -Level INFO
        return 0
    }

    $totalSpaceSaved = 0

    foreach ($profilePath in $profiles) {
        foreach ($dbPath in $BrowserConfig.DatabasePaths) {
            $fullDbPath = Join-Path $profilePath $dbPath

            if (Test-Path $fullDbPath) {
                try {
                    $sizeBefore = (Get-Item $fullDbPath).Length

                    if ($PSCmdlet.ShouldProcess($fullDbPath, "Compact database")) {
                        # Use SQLite VACUUM command to compact database
                        $result = & $sqlite3Cmd.Source $fullDbPath "VACUUM;" 2>&1
                        $exitCode = $LASTEXITCODE

                        if ($exitCode -eq 0) {
                            $sizeAfter = (Get-Item $fullDbPath).Length
                            $spaceSaved = $sizeBefore - $sizeAfter

                            if ($spaceSaved -gt 0) {
                                $totalSpaceSaved += $spaceSaved
                                Write-Log "Compacted $dbPath ($(Format-FileSize $sizeBefore) -> $(Format-FileSize $sizeAfter), saved $(Format-FileSize $spaceSaved))" -Level SUCCESS
                            }
                            else {
                                Write-Verbose "Database $dbPath already optimized"
                            }
                        }
                        else {
                            Write-Log "Failed to compact $dbPath (exit code: $exitCode)" -Level WARNING
                        }
                    }
                    else {
                        Write-Log "[WHATIF] Would compact database: $dbPath ($(Format-FileSize $sizeBefore))" -Level INFO
                    }
                }
                catch {
                    Write-Log "Failed to compact database ${dbPath}: $_" -Level WARNING
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
        Remove metrics and telemetry files for a browser (cross-platform with -WhatIf support)
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
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
                        if ($PSCmdlet.ShouldProcess($file.FullName, "Remove metrics file")) {
                            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
                            $totalFilesRemoved++
                            Write-Verbose "Removed metrics file: $($file.Name)"
                        }
                        else {
                            $totalFilesRemoved++
                            Write-Verbose "[WHATIF] Would remove metrics file: $($file.Name)"
                        }
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
        Create desktop shortcuts (platform-specific)
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Location
    )

    if (-not $IsWindows) {
        Write-Log "Shortcut creation is currently only supported on Windows" -Level WARNING
        Write-Log "On Linux, you can create a .desktop file manually" -Level INFO
        Write-Log "On macOS, you can create an alias or use Automator" -Level INFO
        return $false
    }

    try {
        if ($PSCmdlet.ShouldProcess($Location, "Create shortcut")) {
            # Download icon if not exists
            if (-not (Test-Path $script:IconPath)) {
                Write-Log "Downloading icon from GitHub..." -Level INFO
                Invoke-WebRequest -Uri $script:IconUrl -OutFile $script:IconPath -UseBasicParsing
                Write-Log "Icon downloaded successfully" -Level SUCCESS
            }

            # Create shortcut using COM (Windows only)
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($Location)
            $shortcut.TargetPath = "pwsh.exe"  # Use PowerShell 7+
            $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$script:InstallPath\mTTCleaner.ps1`""
            $shortcut.WorkingDirectory = $script:InstallPath
            $shortcut.Description = "myTech.Today - mTTCleaner"
            $shortcut.IconLocation = $script:IconPath
            $shortcut.WindowStyle = 1  # Normal window
            $shortcut.Save()

            # Try to set to run as administrator (best effort)
            try {
                $bytes = [System.IO.File]::ReadAllBytes($Location)
                $bytes[0x15] = $bytes[0x15] -bor 0x20  # Set byte 21 (0x15) bit 6 (0x20) to run as admin
                [System.IO.File]::WriteAllBytes($Location, $bytes)
            }
            catch {
                Write-Verbose "Could not set 'Run as Administrator' flag: $_"
            }

            Write-Log "Created shortcut: $Location" -Level SUCCESS
            return $true
        }
        else {
            Write-Log "[WHATIF] Would create shortcut: $Location" -Level INFO
            return $true
        }
    }
    catch {
        Write-Log "Failed to create shortcut ${Location}: $_" -Level ERROR
        return $false
    }
}

function Register-mTTCleanerTask {
    <#
    .SYNOPSIS
        Create scheduled task for monthly maintenance (platform-specific)
    .DESCRIPTION
        Creates a scheduled task/job that runs on the 15th of every month at 1:00 PM
        - Windows: Task Scheduler under \myTech.Today\
        - macOS: launchd (not yet implemented)
        - Linux: cron or systemd timer (not yet implemented)
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    if (-not $IsWindows) {
        Write-Log "Scheduled task creation is currently only supported on Windows" -Level WARNING
        Write-Log "On Linux, you can create a cron job manually: crontab -e" -Level INFO
        Write-Log "  Example: 0 13 15 * * /usr/bin/pwsh $script:InstallPath/mTTCleaner.ps1 -Automated" -Level INFO
        Write-Log "On macOS, you can create a launchd plist manually" -Level INFO
        return $false
    }

    try {
        $taskName = "mTTCleaner"
        $taskPath = "\myTech.Today\"

        if (-not $PSCmdlet.ShouldProcess("$taskPath$taskName", "Create scheduled task")) {
            Write-Log "[WHATIF] Would create scheduled task: $taskPath$taskName" -Level INFO
            return $true
        }

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
        $action.Path = "pwsh.exe"  # Use PowerShell 7+
        $action.Arguments = "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$scriptPath`" -Automated"

        Write-Log "Task action: pwsh.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$scriptPath`" -Automated" -Level INFO

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
    # Handle shortcut creation (Windows only)
    if ($CreateShortcuts) {
        Write-Log "Creating shortcuts..." -Level INFO

        if ($IsWindows) {
            $desktopPath = Join-Path $env:USERPROFILE 'Desktop\mTTCleaner.lnk'
            $startMenuPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\myTech.Today'

            if (-not (Test-Path $startMenuPath)) {
                New-Item -ItemType Directory -Path $startMenuPath -Force | Out-Null
            }

            $startMenuShortcut = Join-Path $startMenuPath 'mTTCleaner.lnk'

            New-mTTCleanerShortcut -Location $desktopPath
            New-mTTCleanerShortcut -Location $startMenuShortcut
        }
        else {
            Write-Log "Shortcut creation is only supported on Windows" -Level WARNING
        }
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
    $currentBrowser = 0
    foreach ($browserName in $browsersToProcess) {
        $currentBrowser++

        if (-not $script:BrowserDefinitions.ContainsKey($browserName)) {
            Write-Log "Unknown browser: $browserName" -Level WARNING
            continue
        }

        $browserConfig = $script:BrowserDefinitions[$browserName]

        Write-Log "`n========================================" -Level INFO
        Write-Log "Processing $($browserConfig.Name) ($currentBrowser of $($browsersToProcess.Count))..." -Level INFO
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
    Write-Log "Platform: $script:CurrentPlatform" -Level INFO
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

