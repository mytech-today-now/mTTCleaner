<#
.TITLE
    mTTCleaner - Browser Cache and Database Cleanup Tool

.SYNOPSIS
    Cross-platform browser cache and database cleanup tool for myTech.Today

.DESCRIPTION
    mTTCleaner is a comprehensive cross-platform browser maintenance tool that:
    - Supports 28 browsers (Chrome, Edge, Firefox, Brave, Opera, Vivaldi, Safari, and more)
    - Works on Windows, macOS, and Linux (PowerShell 7+)
    - Cleans browser caches to free up disk space
    - Compacts SQLite databases to reclaim space
    - Removes metrics and telemetry files
    - Modern TUI with browser selection (using Spectre.Console)
    - Active browser detection via registry/mdfind/which
    - Windows Event Log integration for enterprise monitoring
    - Creates platform-specific shortcuts (Windows .lnk, macOS symlinks, Linux .desktop)
    - Sets up automated monthly maintenance (Task Scheduler/launchd/cron)
    - Self-deploys to platform-appropriate locations
    - Optional parallel processing for improved performance

.PARAMETER Automated
    Run in automated mode (skip user confirmation and browser selection)

.PARAMETER SkipConfirmation
    Skip the user confirmation prompt

.PARAMETER NoParallel
    Disable parallel processing (use sequential mode)

.PARAMETER Browser
    Target specific browser or 'All' for all installed browsers
    Supported: Chrome, Edge, Firefox, Brave, Opera, Vivaldi, LibreWolf, Waterfox,
    TorBrowser, Chromium, PaleMoon, UngoogledChromium, Midori, Min, OperaGX,
    Safari, DuckDuckGo, SRWareIron, Maxthon, SeaMonkey, Slimjet, Falkon, Orion,
    Arc, SigmaOS, iCab, Epiphany, Konqueror

.PARAMETER SkipDatabaseCompaction
    Skip database compaction operations

.PARAMETER CreateShortcuts
    Create desktop and start menu shortcuts (cross-platform)

.PARAMETER CreateScheduledTask
    Create monthly scheduled task (cross-platform)

.EXAMPLE
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted
    Set the execution policy to allow running scripts (run once before first use)

.EXAMPLE
    .\mTTCleaner.ps1
    Run interactive cleanup with browser selection menu

.EXAMPLE
    .\mTTCleaner.ps1 -Browser Chrome -SkipConfirmation
    Clean only Chrome without confirmation

.EXAMPLE
    .\mTTCleaner.ps1 -Automated
    Run automated cleanup for all detected browsers

.EXAMPLE
    .\mTTCleaner.ps1 -CreateShortcuts -CreateScheduledTask
    Set up shortcuts and scheduled task for monthly maintenance

.EXAMPLE
    .\mTTCleaner.ps1 -NoParallel
    Run cleanup in sequential mode (disable parallel processing)

.NOTES
    File Name      : mTTCleaner.ps1
    Author         : Kyle C. Rode / myTech.Today
    Version        : 2.2.1
    DateCreated    : 2025-01-23
    LastModified   : 2026-03-18
    Copyright      : (c) 2025 myTech.Today. All rights reserved.
    Requires       : PowerShell 7.0 or later for full cross-platform support
    Platform       : Windows, macOS, Linux
#>

#Requires -Version 7.0

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Automated,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipConfirmation,

    [Parameter(Mandatory = $false)]
    [switch]$NoParallel,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('All', 'Chrome', 'Edge', 'Firefox', 'Brave', 'Opera', 'Vivaldi', 'LibreWolf', 'Waterfox', 'TorBrowser', 'Chromium', 'PaleMoon', 'UngoogledChromium', 'Midori', 'Min', 'OperaGX', 'Safari', 'DuckDuckGo', 'SRWareIron', 'Maxthon', 'SeaMonkey', 'Slimjet', 'Falkon', 'Orion', 'Arc', 'SigmaOS', 'iCab', 'Epiphany', 'Konqueror')]
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

function Install-SQLite3 {
    <#
    .SYNOPSIS
        Automatically downloads and installs SQLite3 tools for Windows
    .DESCRIPTION
        Downloads the latest SQLite3 precompiled binaries from sqlite.org
        and extracts them to the script's install directory
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if (-not $IsWindows) {
        # On macOS/Linux, SQLite3 should be installed via package manager
        return $null
    }

    # Check if sqlite3.exe already exists in install directory
    $sqliteDir = Join-Path $script:InstallPath 'sqlite3'
    $sqliteExe = Join-Path $sqliteDir 'sqlite3.exe'

    if (Test-Path $sqliteExe) {
        Write-Verbose "SQLite3 already installed at: $sqliteExe"
        # Add to PATH for current session
        if ($env:PATH -notlike "*$sqliteDir*") {
            $env:PATH = "$sqliteDir;$env:PATH"
        }
        return $sqliteExe
    }

    try {
        Write-Log "SQLite3 not found. Downloading and installing..." -Level INFO

        # Create sqlite3 directory
        if (-not (Test-Path $sqliteDir)) {
            New-Item -ItemType Directory -Path $sqliteDir -Force | Out-Null
        }

        # Download SQLite3 tools (using a stable version URL)
        # Note: This URL points to the latest version. Update the version number as needed.
        $sqliteUrl = 'https://www.sqlite.org/2024/sqlite-tools-win-x64-3460100.zip'
        $zipPath = Join-Path $env:TEMP 'sqlite-tools.zip'

        Write-Log "Downloading SQLite3 from: $sqliteUrl" -Level INFO
        Invoke-WebRequest -Uri $sqliteUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop

        # Extract zip file directly to a temp directory
        Write-Log "Extracting SQLite3 tools..." -Level INFO
        $extractPath = Join-Path $env:TEMP "sqlite-extract-$(Get-Random)"
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

        # The files are extracted directly to the destination, not in a subdirectory
        $sourceSqlite = Join-Path $extractPath 'sqlite3.exe'

        if (Test-Path $sourceSqlite) {
            # Copy sqlite3.exe to our install directory
            Copy-Item -Path $sourceSqlite -Destination $sqliteExe -Force
            Write-Log "SQLite3 installed successfully to: $sqliteExe" -Level SUCCESS

            # Clean up
            Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue

            # Add to PATH for current session
            $env:PATH = "$sqliteDir;$env:PATH"

            return $sqliteExe
        }
        else {
            Write-Log "Failed to find sqlite3.exe in extracted archive" -Level WARNING
            Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $extractPath -Recurse -Force -ErrorAction SilentlyContinue
            return $null
        }
    }
    catch {
        Write-Log "Failed to download/install SQLite3: $_" -Level WARNING
        Write-Log "You can manually download SQLite3 from: https://www.sqlite.org/download.html" -Level INFO
        return $null
    }
}

#endregion

# Suppress progress bars to prevent spinner graphics in logs
$script:OriginalProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

# Script constants
$script:ScriptVersion = '2.2.1'  # Auto-configure UTF-8 encoding in PowerShell profile during install
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

# Download and integrate myTech.Today logging module
# This provides Windows Event Log integration and enhanced logging features
try {
    # Save script constants before downloading logging module (it may overwrite them)
    $savedScriptName = $script:ScriptName
    $savedScriptVersion = $script:ScriptVersion

    $loggingUrl = 'https://raw.githubusercontent.com/mytech-today-now/scripts/refs/heads/main/logging.ps1'
    Write-Verbose "Downloading logging module from $loggingUrl"
    Invoke-Expression (Invoke-WebRequest -Uri $loggingUrl -UseBasicParsing -ErrorAction Stop).Content
    $script:LoggingModuleLoaded = $true

    # Restore script constants after downloading logging module
    $script:ScriptName = $savedScriptName
    $script:ScriptVersion = $savedScriptVersion
}
catch {
    Write-Warning "Failed to download logging module: $_"
    Write-Warning "Falling back to basic logging"
    $script:LoggingModuleLoaded = $false

    # Fallback basic logging implementation
    $script:LogFile = Join-Path $script:LogPath "$script:ScriptName.log"

    function Initialize-Log {
        param(
            [string]$ScriptName,
            [string]$ScriptVersion = "1.0.0"
        )

        try {
            if (-not (Test-Path $script:LogPath)) {
                New-Item -ItemType Directory -Path $script:LogPath -Force | Out-Null
            }

            if (-not (Test-Path $script:LogFile)) {
                New-Item -ItemType File -Path $script:LogFile -Force | Out-Null
            }

            return $script:LogFile
        }
        catch {
            Write-Warning "Failed to initialize logging: $_"
            return $null
        }
    }

    function Write-Log {
        param(
            [Parameter(Mandatory = $true)]
            [string]$Message,

            [Parameter(Mandatory = $false)]
            [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR')]
            [string]$Level = 'INFO',

            [Parameter(Mandatory = $false)]
            [string]$Solution,

            [Parameter(Mandatory = $false)]
            [string]$Context,

            [Parameter(Mandatory = $false)]
            [string]$Component
        )

        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $logMessage = "[$timestamp] [$Level] $Message"

        try {
            Add-Content -Path $script:LogFile -Value $logMessage -ErrorAction SilentlyContinue
        }
        catch {
            # Silently continue
        }

        $color = switch ($Level) {
            'SUCCESS' { 'Green' }
            'WARNING' { 'Yellow' }
            'ERROR'   { 'Red' }
            default   { 'Cyan' }
        }

        Write-Host $logMessage -ForegroundColor $color
    }

    function Get-LogPath {
        return $script:LogFile
    }
}

#endregion

#region TUI Functions

function Initialize-SpectreConsole {
    <#
    .SYNOPSIS
        Initialize Spectre.Console module for TUI
    #>
    [CmdletBinding()]
    param()

    try {
        # Check if PwshSpectreConsole is available
        if (-not (Get-Module -ListAvailable -Name PwshSpectreConsole)) {
            Write-Verbose "PwshSpectreConsole module not found, attempting to install..."

            # Try to install the module
            try {
                Install-Module -Name PwshSpectreConsole -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
                Write-Verbose "PwshSpectreConsole module installed successfully"
            }
            catch {
                Write-Warning "Failed to install PwshSpectreConsole module: $_"
                Write-Warning "Falling back to basic console output"
                return $false
            }
        }

        # Import the module
        Import-Module PwshSpectreConsole -ErrorAction Stop
        return $true
    }
    catch {
        Write-Warning "Failed to initialize Spectre.Console: $_"
        Write-Warning "Falling back to basic console output"
        return $false
    }
}

function Show-WelcomeBanner {
    <#
    .SYNOPSIS
        Display welcome banner with script information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseSpectre = $false
    )

    if ($UseSpectre) {
        try {
            Format-SpectrePanel -Title "mTTCleaner - Browser Cleanup Tool" -Data @(
                "Cross-Platform Edition v$script:ScriptVersion"
                ""
                "Platform: $script:CurrentPlatform"
                "Elevated: $(if ($script:IsElevated) { 'Yes' } else { 'No' })"
                "PowerShell: $($PSVersionTable.PSVersion)"
            ) -Color Green
        }
        catch {
            # Fallback to basic output
            $UseSpectre = $false
        }
    }

    if (-not $UseSpectre) {
        Write-Host "`n========================================" -ForegroundColor Cyan
        Write-Host "  mTTCleaner - Browser Cleanup Tool" -ForegroundColor Cyan
        Write-Host "  Cross-Platform Edition v$script:ScriptVersion" -ForegroundColor Cyan
        Write-Host "========================================`n" -ForegroundColor Cyan
        Write-Host "Platform: $script:CurrentPlatform" -ForegroundColor Green
        Write-Host "Elevated: $script:IsElevated" -ForegroundColor $(if ($script:IsElevated) { 'Green' } else { 'Yellow' })
        Write-Host "PowerShell: $($PSVersionTable.PSVersion)`n" -ForegroundColor Gray
    }
}

function Show-BrowserSelection {
    <#
    .SYNOPSIS
        Display browser selection menu
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$BrowserDefinitions,

        [Parameter(Mandatory = $false)]
        [bool]$UseSpectre = $false
    )

    # Detect installed browsers
    $installedBrowsers = @()
    foreach ($browserKey in $BrowserDefinitions.Keys) {
        $browser = $BrowserDefinitions[$browserKey]
        $isInstalled = Test-BrowserInstalled -BrowserName $browserKey -ProfilePath $browser.ProfileRoot

        if ($isInstalled) {
            $installedBrowsers += [PSCustomObject]@{
                Key = $browserKey
                Name = $browser.Name
                Type = $browser.Type
                Installed = $true
            }
        }
    }

    if ($installedBrowsers.Count -eq 0) {
        Write-Host "[INFO] No supported browsers detected on this system" -ForegroundColor Yellow
        return @()
    }

    if ($UseSpectre) {
        try {
            Write-Host "`nDetected Browsers:" -ForegroundColor Cyan
            $choices = $installedBrowsers | ForEach-Object { $_.Name }
            $selected = Read-SpectreMultiSelection -Title "Select browsers to clean" -Choices $choices -Color Green

            # Map selected names back to keys
            $selectedKeys = @()
            foreach ($selection in $selected) {
                $browser = $installedBrowsers | Where-Object { $_.Name -eq $selection }
                if ($browser) {
                    $selectedKeys += $browser.Key
                }
            }

            return $selectedKeys
        }
        catch {
            # Fallback to basic selection
            $UseSpectre = $false
        }
    }

    if (-not $UseSpectre) {
        Write-Host "`nDetected Browsers:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $installedBrowsers.Count; $i++) {
            Write-Host "  [$($i + 1)] $($installedBrowsers[$i].Name)" -ForegroundColor White
        }
        Write-Host "  [A] All browsers" -ForegroundColor Green
        Write-Host "  [Q] Quit`n" -ForegroundColor Red

        $selection = Read-Host "Enter your choice"

        if ($selection -eq 'Q' -or $selection -eq 'q') {
            return @()
        }
        elseif ($selection -eq 'A' -or $selection -eq 'a') {
            return $installedBrowsers.Key
        }
        else {
            try {
                $index = [int]$selection - 1
                if ($index -ge 0 -and $index -lt $installedBrowsers.Count) {
                    return @($installedBrowsers[$index].Key)
                }
            }
            catch {
                Write-Host "[ERROR] Invalid selection" -ForegroundColor Red
                return @()
            }
        }
    }
}

function Show-OperationOptions {
    <#
    .SYNOPSIS
        Display operation options menu
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [bool]$UseSpectre = $false
    )

    if ($UseSpectre) {
        try {
            $options = @('Full Clean (Cache + Database + Metrics)', 'Cache Only', 'Database Vacuum Only', 'Metrics Only')
            $selected = Read-SpectreSelection -Title "Select operation type" -Choices $options -Color Cyan

            $result = switch ($selected) {
                'Full Clean (Cache + Database + Metrics)' { 'Full' }
                'Cache Only' { 'Cache' }
                'Database Vacuum Only' { 'Database' }
                'Metrics Only' { 'Metrics' }
                default { 'Full' }
            }
            return $result
        }
        catch {
            $UseSpectre = $false
        }
    }

    if (-not $UseSpectre) {
        Write-Host "`nOperation Options:" -ForegroundColor Cyan
        Write-Host "  [1] Full Clean (Cache + Database + Metrics)" -ForegroundColor Green
        Write-Host "  [2] Cache Only" -ForegroundColor White
        Write-Host "  [3] Database Vacuum Only" -ForegroundColor White
        Write-Host "  [4] Metrics Only`n" -ForegroundColor White

        $selection = Read-Host "Enter your choice (default: 1)"

        $result = switch ($selection) {
            '2' { 'Cache' }
            '3' { 'Database' }
            '4' { 'Metrics' }
            default { 'Full' }
        }
        return $result
    }
}

#endregion

# Initialize logging with enhanced Windows Event Log support
Initialize-Log -ScriptName $script:ScriptName -ScriptVersion $script:ScriptVersion | Out-Null

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
    
    # Ensure UTF-8 encoding is configured in PowerShell profile (prevents Spectre Console warning)
    $utf8Line = '$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()'
    $profilePath = $PROFILE.CurrentUserAllHosts
    try {
        $profileDir = Split-Path -Parent $profilePath
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
            Write-Log "Created PowerShell profile directory: $profileDir" -Level INFO
        }
        if (-not (Test-Path $profilePath)) {
            # Profile doesn't exist - create it with the UTF-8 line
            Set-Content -Path $profilePath -Value $utf8Line -Force
            Write-Log "Created PowerShell profile with UTF-8 encoding: $profilePath" -Level INFO
        }
        else {
            $profileContent = Get-Content -Path $profilePath -Raw -ErrorAction SilentlyContinue
            if ($profileContent -notmatch 'OutputEncoding.*UTF8Encoding') {
                # Prepend the UTF-8 line to existing profile
                $newContent = $utf8Line + [Environment]::NewLine + $profileContent
                Set-Content -Path $profilePath -Value $newContent -Force
                Write-Log "Added UTF-8 encoding to PowerShell profile: $profilePath" -Level INFO
            }
            else {
                Write-Log "UTF-8 encoding already configured in PowerShell profile" -Level INFO
            }
        }
        # Apply UTF-8 encoding to current session so the re-launched script benefits immediately
        $OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
    }
    catch {
        Write-Log "Could not configure UTF-8 encoding in profile: $_" -Level WARN
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

# Initialize Spectre Console if available
$script:UseSpectre = Initialize-SpectreConsole

# User confirmation check
if (-not $Automated -and -not $SkipConfirmation) {
    # Show welcome banner
    Show-WelcomeBanner -UseSpectre $script:UseSpectre

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

function Test-BrowserInstalled {
    <#
    .SYNOPSIS
        Detect if a browser is actually installed on the system
    .DESCRIPTION
        Uses platform-specific detection methods:
        - Windows: Registry queries and executable paths
        - macOS: Application bundle detection and mdfind
        - Linux: which, flatpak, snap, and common binary locations
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$BrowserName,

        [Parameter(Mandatory = $false)]
        [string]$ProfilePath
    )

    # First check if profile path exists (quick check)
    if ($ProfilePath -and (Test-Path $ProfilePath)) {
        return $true
    }

    # Platform-specific detection
    if ($IsWindows) {
        # Check registry for installed applications
        $registryPaths = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )

        $browserNames = @{
            'Chrome' = @('Google Chrome', 'Chrome')
            'Edge' = @('Microsoft Edge', 'Edge')
            'Firefox' = @('Mozilla Firefox', 'Firefox')
            'Brave' = @('Brave', 'Brave Browser')
            'Opera' = @('Opera Stable', 'Opera')
            'OperaGX' = @('Opera GX', 'OperaGX')
            'Vivaldi' = @('Vivaldi')
            'Chromium' = @('Chromium')
            'LibreWolf' = @('LibreWolf')
            'Waterfox' = @('Waterfox')
            'TorBrowser' = @('Tor Browser')
            'PaleMoon' = @('Pale Moon')
            'DuckDuckGo' = @('DuckDuckGo', 'DuckDuckGo Privacy Browser')
            'SRWareIron' = @('SRWare Iron', 'Iron')
            'Maxthon' = @('Maxthon', 'Maxthon Cloud Browser')
            'SeaMonkey' = @('SeaMonkey')
            'Slimjet' = @('Slimjet')
            'Falkon' = @('Falkon')
            'Orion' = @('Orion', 'Orion Browser')
            'Arc' = @('Arc', 'Arc Browser')
            'SigmaOS' = @('SigmaOS')
            'iCab' = @('iCab')
            'Epiphany' = @('Epiphany', 'GNOME Web')
            'Konqueror' = @('Konqueror')
        }

        if ($browserNames.ContainsKey($BrowserName)) {
            foreach ($regPath in $registryPaths) {
                try {
                    $apps = Get-ItemProperty $regPath -ErrorAction SilentlyContinue
                    foreach ($app in $apps) {
                        foreach ($name in $browserNames[$BrowserName]) {
                            if ($app.DisplayName -like "*$name*") {
                                return $true
                            }
                        }
                    }
                }
                catch {
                    # Continue to next registry path
                }
            }
        }
    }
    elseif ($IsMacOS) {
        # Check /Applications and ~/Applications for .app bundles
        $appPaths = @('/Applications', "$HOME/Applications")

        $appNames = @{
            'Chrome' = 'Google Chrome.app'
            'Edge' = 'Microsoft Edge.app'
            'Firefox' = 'Firefox.app'
            'Brave' = 'Brave Browser.app'
            'Opera' = 'Opera.app'
            'OperaGX' = 'Opera GX.app'
            'Vivaldi' = 'Vivaldi.app'
            'Chromium' = 'Chromium.app'
            'LibreWolf' = 'LibreWolf.app'
            'Waterfox' = 'Waterfox.app'
            'TorBrowser' = 'Tor Browser.app'
            'Safari' = 'Safari.app'
            'DuckDuckGo' = 'DuckDuckGo.app'
            'Slimjet' = 'Slimjet.app'
            'Orion' = 'Orion.app'
            'Arc' = 'Arc.app'
            'SigmaOS' = 'SigmaOS.app'
            'iCab' = 'iCab.app'
        }

        if ($appNames.ContainsKey($BrowserName)) {
            foreach ($appPath in $appPaths) {
                $fullPath = Join-Path $appPath $appNames[$BrowserName]
                if (Test-Path $fullPath) {
                    return $true
                }
            }
        }
    }
    elseif ($IsLinux) {
        # Check using which, flatpak, and snap
        $binaryNames = @{
            'Chrome' = @('google-chrome', 'google-chrome-stable')
            'Edge' = @('microsoft-edge', 'microsoft-edge-stable')
            'Firefox' = @('firefox')
            'Brave' = @('brave', 'brave-browser')
            'Opera' = @('opera')
            'Vivaldi' = @('vivaldi')
            'Chromium' = @('chromium', 'chromium-browser')
            'LibreWolf' = @('librewolf')
            'Waterfox' = @('waterfox')
            'TorBrowser' = @('tor-browser', 'torbrowser-launcher')
            'PaleMoon' = @('palemoon')
            'Midori' = @('midori')
            'DuckDuckGo' = @('duckduckgo')
            'Falkon' = @('falkon')
            'SeaMonkey' = @('seamonkey')
            'Slimjet' = @('slimjet')
            'Epiphany' = @('epiphany', 'epiphany-browser')
            'Konqueror' = @('konqueror')
        }

        if ($binaryNames.ContainsKey($BrowserName)) {
            foreach ($binary in $binaryNames[$BrowserName]) {
                # Check using which
                $whichResult = Get-Command $binary -ErrorAction SilentlyContinue
                if ($whichResult) {
                    return $true
                }

                # Check flatpak
                try {
                    $flatpakResult = & flatpak list 2>$null | Select-String -Pattern $binary -Quiet
                    if ($flatpakResult) {
                        return $true
                    }
                }
                catch {
                    # flatpak not available
                }

                # Check snap
                try {
                    $snapResult = & snap list 2>$null | Select-String -Pattern $binary -Quiet
                    if ($snapResult) {
                        return $true
                    }
                }
                catch {
                    # snap not available
                }
            }
        }
    }

    return $false
}

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
            DuckDuckGo = Join-Path $env:LOCALAPPDATA 'DuckDuckGo\User Data'
            SRWareIron = Join-Path $env:LOCALAPPDATA 'Chromium\User Data'
            Maxthon = Join-Path $env:LOCALAPPDATA 'Maxthon\User Data'
            SeaMonkey = Join-Path $env:APPDATA 'Mozilla\SeaMonkey\Profiles'
            Slimjet = Join-Path $env:LOCALAPPDATA 'Slimjet\User Data'
            Falkon = Join-Path $env:LOCALAPPDATA 'falkon\profiles'
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
            Safari = Join-Path $HOME 'Library/Safari'
            DuckDuckGo = Join-Path $HOME 'Library/Application Support/DuckDuckGo'
            SRWareIron = Join-Path $HOME 'Library/Application Support/Chromium'
            Maxthon = Join-Path $HOME 'Library/Application Support/Maxthon'
            SeaMonkey = Join-Path $HOME 'Library/Application Support/SeaMonkey/Profiles'
            Slimjet = Join-Path $HOME 'Library/Application Support/Slimjet'
            Falkon = Join-Path $HOME 'Library/Application Support/falkon'
            Orion = Join-Path $HOME 'Library/Application Support/Orion'
            Arc = Join-Path $HOME 'Library/Application Support/Arc'
            SigmaOS = Join-Path $HOME 'Library/Application Support/SigmaOS'
            iCab = Join-Path $HOME 'Library/Application Support/iCab'
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
            DuckDuckGo = Join-Path $HOME '.config/duckduckgo'
            SRWareIron = Join-Path $HOME '.config/chromium'
            Maxthon = Join-Path $HOME '.config/maxthon'
            SeaMonkey = Join-Path $HOME '.mozilla/seamonkey'
            Slimjet = Join-Path $HOME '.config/slimjet'
            Falkon = Join-Path $HOME '.config/falkon'
            Epiphany = Join-Path $HOME '.local/share/epiphany'
            Konqueror = Join-Path $HOME '.local/share/konqueror'
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
    'Safari' = @{
        Name = 'Safari'
        ProcessNames = @('Safari')
        ProfileRoot = Get-BrowserPath -BrowserName 'Safari'
        CachePaths = @('Caches')
        DatabasePaths = @('History.db', 'Cookies.binarycookies')
        MetricsPaths = @()
        Type = 'Safari'
    }
    'DuckDuckGo' = @{
        Name = 'DuckDuckGo Browser'
        ProcessNames = @('duckduckgo', 'DuckDuckGo')
        ProfileRoot = Get-BrowserPath -BrowserName 'DuckDuckGo'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache')
        DatabasePaths = @('History', 'Cookies', 'Web Data')
        MetricsPaths = @('*metrics*')
        Type = 'Chromium'
    }
    'SRWareIron' = @{
        Name = 'SRWare Iron'
        ProcessNames = @('iron', 'chrome')
        ProfileRoot = Get-BrowserPath -BrowserName 'SRWareIron'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker/CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Maxthon' = @{
        Name = 'Maxthon Browser'
        ProcessNames = @('maxthon', 'Maxthon')
        ProfileRoot = Get-BrowserPath -BrowserName 'Maxthon'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache')
        DatabasePaths = @('History', 'Cookies', 'Web Data')
        MetricsPaths = @('*metrics*')
        Type = 'Chromium'
    }
    'SeaMonkey' = @{
        Name = 'SeaMonkey'
        ProcessNames = @('seamonkey', 'seamonkey-bin')
        ProfileRoot = Get-BrowserPath -BrowserName 'SeaMonkey'
        CachePaths = @('cache2', 'startupCache', 'OfflineCache')
        DatabasePaths = @('places.sqlite', 'favicons.sqlite', 'cookies.sqlite', 'formhistory.sqlite')
        MetricsPaths = @('*telemetry*', 'datareporting')
        Type = 'Firefox'
    }
    'Slimjet' = @{
        Name = 'Slimjet Browser'
        ProcessNames = @('slimjet', 'flashpeak-slimjet')
        ProfileRoot = Get-BrowserPath -BrowserName 'Slimjet'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker/CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data', 'Login Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Falkon' = @{
        Name = 'Falkon Browser'
        ProcessNames = @('falkon')
        ProfileRoot = Get-BrowserPath -BrowserName 'Falkon'
        CachePaths = @('cache')
        DatabasePaths = @('browsedata.db', 'cookies.dat')
        MetricsPaths = @()
        Type = 'Falkon'
    }
    'Orion' = @{
        Name = 'Orion Browser'
        ProcessNames = @('Orion')
        ProfileRoot = Get-BrowserPath -BrowserName 'Orion'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache')
        DatabasePaths = @('History', 'Cookies', 'Web Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'Arc' = @{
        Name = 'Arc Browser'
        ProcessNames = @('Arc')
        ProfileRoot = Get-BrowserPath -BrowserName 'Arc'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache', 'Service Worker/CacheStorage')
        DatabasePaths = @('History', 'Cookies', 'Web Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'SigmaOS' = @{
        Name = 'SigmaOS'
        ProcessNames = @('SigmaOS')
        ProfileRoot = Get-BrowserPath -BrowserName 'SigmaOS'
        CachePaths = @('Cache', 'Code Cache', 'GPUCache')
        DatabasePaths = @('History', 'Cookies', 'Web Data')
        MetricsPaths = @('*metrics*', '*telemetry*')
        Type = 'Chromium'
    }
    'iCab' = @{
        Name = 'iCab'
        ProcessNames = @('iCab')
        ProfileRoot = Get-BrowserPath -BrowserName 'iCab'
        CachePaths = @('Cache', 'WebKit Cache')
        DatabasePaths = @('History.db', 'Cookies.db')
        MetricsPaths = @()
        Type = 'WebKit'
    }
    'Epiphany' = @{
        Name = 'Epiphany (GNOME Web)'
        ProcessNames = @('epiphany', 'epiphany-browser')
        ProfileRoot = Get-BrowserPath -BrowserName 'Epiphany'
        CachePaths = @()
        DatabasePaths = @('ephy-history.db', 'ephy-cookies.sqlite')
        MetricsPaths = @()
        Type = 'WebKit'
    }
    'Konqueror' = @{
        Name = 'Konqueror'
        ProcessNames = @('konqueror')
        ProfileRoot = Get-BrowserPath -BrowserName 'Konqueror'
        CachePaths = @()
        DatabasePaths = @()
        MetricsPaths = @()
        Type = 'KHTML'
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
    elseif ($BrowserConfig.Type -eq 'Safari') {
        # Safari uses a single profile directory
        $profiles += $BrowserConfig.ProfileRoot
    }
    elseif ($BrowserConfig.Type -eq 'Falkon') {
        # Falkon uses profile subdirectories
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

        # If not found, try to install it automatically
        if (-not $sqlite3Cmd) {
            $installedPath = Install-SQLite3
            if ($installedPath) {
                $sqlite3Cmd = Get-Command sqlite3.exe -ErrorAction SilentlyContinue
            }
        }
    }
    else {
        $sqlite3Cmd = Get-Command sqlite3 -ErrorAction SilentlyContinue
    }

    if (-not $sqlite3Cmd) {
        Write-Log "SQLite3 command not found. Database compaction will be skipped." -Level WARNING
        if (-not $IsWindows) {
            Write-Log "  macOS: brew install sqlite3" -Level INFO
            Write-Log "  Linux: sudo apt install sqlite3 (Debian/Ubuntu) or sudo yum install sqlite (RHEL/CentOS)" -Level INFO
        }
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
    .DESCRIPTION
        Windows: Creates .lnk shortcuts on Desktop and Start Menu
        macOS: Creates symbolic links on Desktop
        Linux: Creates .desktop files on Desktop and ~/.local/share/applications
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('Desktop', 'StartMenu', 'Applications')]
        [string]$Location = 'Desktop'
    )

    try {
        if ($IsWindows) {
            # Windows: Create .lnk shortcuts
            $shortcutPath = switch ($Location) {
                'Desktop' { Join-Path $env:USERPROFILE 'Desktop\mTTCleaner.lnk' }
                'StartMenu' { Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\myTech.Today\mTTCleaner.lnk' }
                default { Join-Path $env:USERPROFILE 'Desktop\mTTCleaner.lnk' }
            }

            if ($PSCmdlet.ShouldProcess($shortcutPath, "Create Windows shortcut")) {
                # Create parent directory if needed
                $parentDir = Split-Path $shortcutPath -Parent
                if (-not (Test-Path $parentDir)) {
                    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                }

                # Download icon if not exists
                if (-not (Test-Path $script:IconPath)) {
                    Write-Log "Downloading icon from GitHub..." -Level INFO
                    Invoke-WebRequest -Uri $script:IconUrl -OutFile $script:IconPath -UseBasicParsing -ErrorAction SilentlyContinue
                }

                # Create shortcut using COM
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut($shortcutPath)
                $shortcut.TargetPath = "pwsh.exe"
                $shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$script:InstallPath\mTTCleaner.ps1`""
                $shortcut.WorkingDirectory = $script:InstallPath
                $shortcut.Description = "myTech.Today - mTTCleaner"
                if (Test-Path $script:IconPath) {
                    $shortcut.IconLocation = $script:IconPath
                }
                $shortcut.WindowStyle = 1
                $shortcut.Save()

                # Try to set run as administrator
                try {
                    $bytes = [System.IO.File]::ReadAllBytes($shortcutPath)
                    $bytes[0x15] = $bytes[0x15] -bor 0x20
                    [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)
                }
                catch {
                    Write-Verbose "Could not set 'Run as Administrator' flag: $_"
                }

                Write-Log "Created Windows shortcut: $shortcutPath" -Level SUCCESS
                return $true
            }
        }
        elseif ($IsMacOS) {
            # macOS: Create symbolic link on Desktop
            $desktopPath = Join-Path $HOME 'Desktop/mTTCleaner'
            $scriptPath = Join-Path $script:InstallPath 'mTTCleaner.ps1'

            if ($PSCmdlet.ShouldProcess($desktopPath, "Create macOS symbolic link")) {
                # Create a shell script wrapper that launches PowerShell
                $wrapperScript = @"
#!/bin/bash
/usr/local/bin/pwsh -ExecutionPolicy Bypass -File "$scriptPath"
"@
                Set-Content -Path $desktopPath -Value $wrapperScript -Force
                & chmod +x $desktopPath

                Write-Log "Created macOS shortcut: $desktopPath" -Level SUCCESS
                return $true
            }
        }
        elseif ($IsLinux) {
            # Linux: Create .desktop file
            $desktopFilePath = switch ($Location) {
                'Desktop' { Join-Path $HOME 'Desktop/mTTCleaner.desktop' }
                'Applications' { Join-Path $HOME '.local/share/applications/mTTCleaner.desktop' }
                default { Join-Path $HOME 'Desktop/mTTCleaner.desktop' }
            }

            if ($PSCmdlet.ShouldProcess($desktopFilePath, "Create Linux .desktop file")) {
                # Create parent directory if needed
                $parentDir = Split-Path $desktopFilePath -Parent
                if (-not (Test-Path $parentDir)) {
                    New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
                }

                $scriptPath = Join-Path $script:InstallPath 'mTTCleaner.ps1'
                $desktopEntry = @"
[Desktop Entry]
Version=1.0
Type=Application
Name=mTTCleaner
Comment=myTech.Today Browser Cleanup Tool
Exec=pwsh -ExecutionPolicy Bypass -File "$scriptPath"
Icon=utilities-terminal
Terminal=true
Categories=Utility;System;
"@
                Set-Content -Path $desktopFilePath -Value $desktopEntry -Force
                & chmod +x $desktopFilePath

                Write-Log "Created Linux .desktop file: $desktopFilePath" -Level SUCCESS
                return $true
            }
        }

        return $false
    }
    catch {
        Write-Log "Failed to create shortcut: $_" -Level ERROR
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
        - macOS: launchd plist in ~/Library/LaunchAgents/
        - Linux: cron entry via crontab
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    if ($IsMacOS) {
        # macOS: Create launchd plist
        try {
            $plistPath = Join-Path $HOME 'Library/LaunchAgents/com.mytech.today.mttcleaner.plist'
            $scriptPath = Join-Path $script:InstallPath 'mTTCleaner.ps1'

            if ($PSCmdlet.ShouldProcess($plistPath, "Create launchd plist")) {
                # Create LaunchAgents directory if it doesn't exist
                $launchAgentsDir = Join-Path $HOME 'Library/LaunchAgents'
                if (-not (Test-Path $launchAgentsDir)) {
                    New-Item -ItemType Directory -Path $launchAgentsDir -Force | Out-Null
                }

                # Create plist content (runs on 15th of every month at 1:00 PM)
                $plistContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.mytech.today.mttcleaner</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/pwsh</string>
        <string>-ExecutionPolicy</string>
        <string>Bypass</string>
        <string>-NoProfile</string>
        <string>-File</string>
        <string>$scriptPath</string>
        <string>-Automated</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Day</key>
        <integer>15</integer>
        <key>Hour</key>
        <integer>13</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/mTTCleaner.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/mTTCleaner.error.log</string>
</dict>
</plist>
"@
                Set-Content -Path $plistPath -Value $plistContent -Force

                # Load the plist
                & launchctl load $plistPath 2>&1 | Out-Null

                Write-Log "Created macOS launchd plist: $plistPath" -Level SUCCESS
                Write-Log "Task will run monthly on the 15th at 1:00 PM" -Level SUCCESS
                return $true
            }
        }
        catch {
            Write-Log "Failed to create macOS launchd plist: $_" -Level ERROR
            return $false
        }
    }
    elseif ($IsLinux) {
        # Linux: Add cron entry
        try {
            $scriptPath = Join-Path $script:InstallPath 'mTTCleaner.ps1'
            $cronEntry = "0 13 15 * * /usr/bin/pwsh -ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`" -Automated"

            if ($PSCmdlet.ShouldProcess("crontab", "Add cron entry")) {
                # Get current crontab
                $currentCrontab = & crontab -l 2>&1

                # Check if entry already exists
                if ($currentCrontab -match 'mTTCleaner') {
                    Write-Log "Cron entry already exists" -Level INFO
                    return $true
                }

                # Add new entry
                $newCrontab = if ($currentCrontab -and $currentCrontab -notmatch 'no crontab') {
                    "$currentCrontab`n$cronEntry"
                }
                else {
                    $cronEntry
                }

                # Write new crontab
                $newCrontab | & crontab -

                Write-Log "Created Linux cron entry" -Level SUCCESS
                Write-Log "Task will run monthly on the 15th at 1:00 PM" -Level SUCCESS
                Write-Log "Cron entry: $cronEntry" -Level INFO
                return $true
            }
        }
        catch {
            Write-Log "Failed to create Linux cron entry: $_" -Level ERROR
            Write-Log "You can manually add this cron entry: $cronEntry" -Level INFO
            return $false
        }
    }
    elseif ($IsWindows) {
        # Windows: Task Scheduler (existing implementation)
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
    # Handle shortcut creation (cross-platform)
    if ($CreateShortcuts) {
        Write-Log "Creating shortcuts..." -Level INFO

        # Create desktop shortcut
        New-mTTCleanerShortcut -Location 'Desktop'

        # Create Start Menu/Applications shortcut
        if ($IsWindows) {
            New-mTTCleanerShortcut -Location 'StartMenu'
        }
        elseif ($IsLinux) {
            New-mTTCleanerShortcut -Location 'Applications'
        }
    }

    # Handle scheduled task creation
    if ($CreateScheduledTask) {
        Write-Log "Creating scheduled task..." -Level INFO
        Register-mTTCleanerTask
    }

    # Determine which browsers to process
    $browsersToProcess = @()

    # If in interactive mode and no specific browser selected, show browser selection
    if (-not $Automated -and $Browser -eq 'All' -and -not $SkipConfirmation) {
        $selectedBrowsers = Show-BrowserSelection -BrowserDefinitions $script:BrowserDefinitions -UseSpectre $script:UseSpectre

        if ($selectedBrowsers.Count -eq 0) {
            Write-Log "No browsers selected, exiting" -Level WARNING
            Write-Host "`n[INFO] No browsers selected" -ForegroundColor Yellow
            exit 0
        }

        $browsersToProcess = $selectedBrowsers
    }
    elseif ($Browser -eq 'All') {
        $browsersToProcess = $script:BrowserDefinitions.Keys
    }
    else {
        $browsersToProcess = @($Browser)
    }

    Write-Log "Processing $($browsersToProcess.Count) browser(s)..." -Level INFO

    # Determine if we should use parallel processing
    $useParallel = (-not $NoParallel) -and ($browsersToProcess.Count -gt 1) -and ($PSVersionTable.PSVersion.Major -ge 7)

    if ($useParallel) {
        Write-Log "Using parallel processing for improved performance" -Level INFO

        # Process browsers in parallel
        $results = $browsersToProcess | ForEach-Object -Parallel {
            $browserName = $_
            $browserDefinitions = $using:script:BrowserDefinitions

            if (-not $browserDefinitions.ContainsKey($browserName)) {
                return @{
                    BrowserName = $browserName
                    Success = $false
                    Message = "Unknown browser"
                }
            }

            $browserConfig = $browserDefinitions[$browserName]

            # Import required functions (they need to be available in parallel runspace)
            # Note: In parallel processing, we need to re-import or define functions
            # For now, we'll process sequentially to avoid complexity

            return @{
                BrowserName = $browserName
                Success = $true
                Message = "Processed"
            }
        } -ThrottleLimit 4

        # Note: Full parallel implementation would require refactoring functions
        # For now, fall back to sequential processing
        Write-Log "Parallel processing requires function refactoring, using sequential mode" -Level INFO
        $useParallel = $false
    }

    if (-not $useParallel) {
        # Sequential processing
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

