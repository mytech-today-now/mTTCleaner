# PowerShell Development Guidelines - myTech.Today

**Developer:** myTech.Today
**Author:** Kyle C. Rode
**Copyright:** (c) 2025 myTech.Today. All rights reserved.
**Contact:** sales@mytech.today | https://mytech.today | GitHub: @mytech-today-now

## Business Branding (STRICT)

**Business Name:** myTech.Today

**Branding Rules:**
- Business name is **always** written as: `myTech.Today`
- First "m" is **always lowercase**
- All "T"s are **always capitalized** (in "Tech" and "Today")
- Period (`.`) **always** between "myTech" and "Today" with **no spaces**
- **Incorrect:** MyTech.Today, Mytech.today, mytech.today, MyTech Today
- **Correct:** myTech.Today

For Windows file paths, use lowercase: `C:\mytech.today\`

---

## CRITICAL: Character Encoding Standards

**NEVER USE EMOJI IN POWERSHELL SCRIPTS**

When generating PowerShell scripts, you MUST:
- USE ASCII characters only for status indicators
- NEVER USE emoji characters or Unicode box-drawing

**ASCII Alternatives:**
| Instead of | Use |
|------------|-----|
| ✅ | `[OK]` |
| ❌ | `[FAIL]` or `[ERROR]` |
| ⚠️ | `[WARN]` |
| ℹ️ | `[INFO]` |
| 🔍 | `[CHECK]` |
| 📦 | `[INSTALL]` |
| ⬇️ | `[DOWNLOAD]` |
| ⏱️ | `[TIME]` |
| ⏭️ | `[SKIP]` |

**Example:**
```powershell
# CORRECT - ASCII characters only
Write-Host "[OK] Installation completed successfully!" -ForegroundColor Green
Write-Host "[FAIL] Installation failed with exit code: $LASTEXITCODE" -ForegroundColor Red
Write-Host "[WARN] Configuration file not found, using defaults" -ForegroundColor Yellow
Write-Host "[INFO] Processing 100 items..." -ForegroundColor Cyan
```

---

## Cross-Platform Installation Paths

All myTech.Today scripts **MUST** use standardized paths resolved at runtime.

### Program Files (Read-Only Binaries)
| Platform | System-Wide | Per-User Fallback |
|----------|-------------|-------------------|
| Windows  | `C:\Program Files (x86)\myTech.Today\<Title>\` | `%LOCALAPPDATA%\myTech.Today\<Title>\` |
| macOS    | `/usr/local/myTech.Today/<Title>/` | `~/Library/Application Support/myTech.Today/<Title>/` |
| Linux    | `/opt/myTech.Today/<Title>/` | `~/.local/share/myTech.Today/<Title>/` |

### Writable Data Root
| Platform | System-Wide | Per-User Fallback |
|----------|-------------|-------------------|
| Windows  | `C:\ProgramData\myTech.Today\<Title>\` | `%LOCALAPPDATA%\myTech.Today\<Title>\` |
| macOS    | `/Library/Application Support/myTech.Today/<Title>/` | `~/Library/Preferences/myTech.Today/<Title>/` |
| Linux    | `/var/opt/myTech.Today/<Title>/` | `~/.config/myTech.Today/<Title>/` |

### Subfolder Structure (under Data Root)
| Subfolder | Purpose | Example |
|-----------|---------|---------|
| `data\` | Database files, persistent state | `devices.db`, `sites.db` |
| `config\` | Configuration files | `settings.json` |
| `logs\` | Log files | `RMM.log`, `RMM-20241214-120000.log` |

### Logs (Alternative Platform-Native Paths)
| Platform | System-Wide | Per-User Fallback |
|----------|-------------|-------------------|
| Windows  | `<DataRoot>\logs\` | `<DataRoot>\logs\` |
| macOS    | `/Library/Logs/myTech.Today/<Title>/` | `~/Library/Logs/myTech.Today/<Title>/` |
| Linux    | `/var/log/myTech.Today/<Title>/` | `~/.local/share/myTech.Today/<Title>/logs/` |

### Service/Daemon Persistence
| Platform | Service Type | Location |
|----------|--------------|----------|
| Windows  | Windows Service or Scheduled Task | SYSTEM context |
| macOS    | LaunchDaemon (system) / LaunchAgent (user) | `/Library/LaunchDaemons/` or `~/Library/LaunchAgents/` |
| Linux    | systemd unit | `/etc/systemd/system/` |

### Path Resolution in PowerShell
```powershell
# Detect platform and set paths dynamically
$ScriptTitle = "RMM"
if ($IsWindows) {
    $InstallDir = "${env:ProgramFiles(x86)}\myTech.Today\$ScriptTitle"
    $DataRoot = "$env:ProgramData\myTech.Today\$ScriptTitle"
    $DataDir = "$DataRoot\data"
    $ConfigDir = "$DataRoot\config"
    $LogDir = "$DataRoot\logs"
} elseif ($IsMacOS) {
    $InstallDir = "/usr/local/myTech.Today/$ScriptTitle"
    $DataRoot = "/Library/Application Support/myTech.Today/$ScriptTitle"
    $DataDir = "$DataRoot/data"
    $ConfigDir = "$DataRoot/config"
    $LogDir = "/Library/Logs/myTech.Today/$ScriptTitle"
} elseif ($IsLinux) {
    $InstallDir = "/opt/myTech.Today/$ScriptTitle"
    $DataRoot = "/var/opt/myTech.Today/$ScriptTitle"
    $DataDir = "$DataRoot/data"
    $ConfigDir = "$DataRoot/config"
    $LogDir = "/var/log/myTech.Today/$ScriptTitle"
}
```

### Elevation Detection
```powershell
function Test-IsElevated {
    if ($IsWindows) {
        $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } else { return (id -u) -eq 0 }
}
```

### Service Commands
- **Windows**: `New-Service -Name "myTechRMM" -BinaryPathName $exe -StartupType Automatic`
- **macOS**: `launchctl load /Library/LaunchDaemons/com.mytech.today.<title>.plist`
- **Linux**: `systemctl daemon-reload && systemctl enable --now mytech-<title>`

### Installer Best Practices
- **Idempotent**: Safe to run multiple times without side effects
- **Elevation-aware**: Detect admin/root, adjust paths accordingly
- **Silent mode**: Support `--silent` flag for unattended MSP deployment
- **Validation**: Verify all files copied and services started correctly
- **Rollback**: Preserve previous install for recovery if upgrade fails

---

## Centralized Logging

All scripts **MUST** log using cross-platform paths (see table above).

**Logging Functions:** `Write-LogInfo`, `Write-LogWarning`, `Write-LogError`, `Write-LogSuccess`, `Write-LogDebug`

**Log File Naming:** Current: `<script>.log`, Archived: `<script>-YYYYMMDD-HHMMSS.log`

---

## Naming Conventions

### Functions
- Use `Verb-Noun` format with approved verbs (run `Get-Verb` to see list)
- Common verbs: Get, Set, New, Remove, Start, Stop, Enable, Disable, Test, Invoke

### Variables
- `$PascalCase` for script-scope and public variables
- `$camelCase` for local/private variables
- `$script:VariableName` for script-scope
- `$global:VariableName` for global scope (use sparingly)

### Parameters
- Always use `$PascalCase`
- Use descriptive names: `$ComputerName` not `$CN`

### Modules
- Format: `Company.ModuleName` (e.g., `MyTech.Utilities`)

---

## Function Structure Template

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        Brief one-line description of the function.

    .DESCRIPTION
        Detailed description of what the function does, including any
        prerequisites, dependencies, or important notes.

    .PARAMETER ParameterName
        Description of the parameter, including valid values and defaults.

    .EXAMPLE
        Verb-Noun -ParameterName "Value"

        Description of what this example does.

    .EXAMPLE
        Get-Content "file.txt" | Verb-Noun

        Example showing pipeline usage.

    .INPUTS
        System.String. You can pipe strings to this function.

    .OUTPUTS
        System.Object. Returns processed objects.

    .NOTES
        Author: Kyle C. Rode
        Company: myTech.Today
        Version: 1.0.0
        Created: 2025-01-01

    .LINK
        https://mytech.today
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "Enter the target computer name")]
        [ValidateNotNullOrEmpty()]
        [Alias("CN", "Server")]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Option1", "Option2", "Option3")]
        [string]$Mode = "Option1",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    begin {
        # One-time initialization
        Write-Verbose "Starting $($MyInvocation.MyCommand.Name)"
        $results = [System.Collections.Generic.List[object]]::new()
    }

    process {
        foreach ($computer in $ComputerName) {
            try {
                if ($PSCmdlet.ShouldProcess($computer, "Perform operation")) {
                    # Main logic here
                    $result = [PSCustomObject]@{
                        ComputerName = $computer
                        Status       = "Success"
                        Timestamp    = Get-Date
                    }
                    $results.Add($result)
                }
            }
            catch {
                Write-Error "Failed to process $computer : $_"
                if (-not $Force) { throw }
            }
        }
    }

    end {
        Write-Verbose "Completed $($MyInvocation.MyCommand.Name)"
        return $results
    }
}
```

---

## Parameter Validation

### Available Validation Attributes

```powershell
# Not null or empty
[ValidateNotNull()]
[ValidateNotNullOrEmpty()]

# String length
[ValidateLength(1, 50)]

# Numeric range
[ValidateRange(1, 100)]
[ValidateRange("Positive")]  # PS 6.1+

# Pattern matching
[ValidatePattern('^[A-Z][a-z]+$')]

# Allowed values
[ValidateSet("Value1", "Value2", "Value3")]

# Count of items
[ValidateCount(1, 10)]

# Custom validation
[ValidateScript({
    if (Test-Path $_) { $true }
    else { throw "Path '$_' does not exist" }
})]

# Drive validation
[ValidateDrive("C", "D")]

# Trusted data
[ValidateTrustedData()]
```

### Parameter Sets

```powershell
param(
    [Parameter(ParameterSetName = "ByName", Mandatory = $true)]
    [string]$Name,

    [Parameter(ParameterSetName = "ByPath", Mandatory = $true)]
    [string]$Path,

    [Parameter(ParameterSetName = "ByName")]
    [Parameter(ParameterSetName = "ByPath")]
    [switch]$Force
)
```

---

## Error Handling

### Standard Try-Catch-Finally Pattern

```powershell
try {
    # Use -ErrorAction Stop to make errors terminating
    $result = Get-ChildItem -Path $Path -ErrorAction Stop

    # Process results
    foreach ($item in $result) {
        Process-Item -Item $item -ErrorAction Stop
    }
}
catch [System.IO.FileNotFoundException] {
    # Handle specific exception
    Write-Error "File not found: $($_.Exception.Message)"
    Write-LogError "FileNotFoundException: $($_.Exception.Message)"
}
catch [System.UnauthorizedAccessException] {
    # Handle access denied
    Write-Error "Access denied: $($_.Exception.Message)"
    Write-LogError "UnauthorizedAccessException: $($_.Exception.Message)"
}
catch {
    # Handle all other exceptions
    Write-Error "Unexpected error: $($_.Exception.Message)"
    Write-LogError "Exception: $($_.Exception.GetType().FullName) - $($_.Exception.Message)"

    # Re-throw if critical
    throw
}
finally {
    # Always runs - cleanup code
    if ($connection) {
        $connection.Close()
        $connection.Dispose()
    }
}
```

### Error Record Properties

```powershell
catch {
    $errorRecord = $_

    # Exception details
    $errorRecord.Exception.Message
    $errorRecord.Exception.GetType().FullName
    $errorRecord.Exception.InnerException

    # Invocation info
    $errorRecord.InvocationInfo.ScriptName
    $errorRecord.InvocationInfo.ScriptLineNumber
    $errorRecord.InvocationInfo.Line

    # Category info
    $errorRecord.CategoryInfo.Category
    $errorRecord.CategoryInfo.Activity

    # Full error
    $errorRecord.ToString()
    $errorRecord.ScriptStackTrace
}
```

---

## GUI Development - Responsive Design

**MANDATORY:** All Windows GUI applications MUST implement responsive design.

### Helper Script

```powershell
# Load responsive GUI helper from GitHub
$responsiveUrl = 'https://raw.githubusercontent.com/mytech-today-now/scripts/refs/heads/main/responsive.ps1'
Invoke-Expression (Invoke-WebRequest -Uri $responsiveUrl -UseBasicParsing).Content

# Create responsive form
$form = New-ResponsiveForm -Title "My Application" -Width 800 -Height 600

# Create responsive controls
$label = New-ResponsiveLabel -Text "Enter Name:" -X 20 -Y 20
$textbox = New-ResponsiveTextBox -X 120 -Y 20 -Width 200
$button = New-ResponsiveButton -Text "Submit" -X 20 -Y 60 -Width 100
$checkbox = New-ResponsiveCheckBox -Text "Enable Feature" -X 20 -Y 100

# Add controls to form
$form.Controls.AddRange(@($label, $textbox, $button, $checkbox))

# Show form
$form.ShowDialog()
```

### DPI Scaling

```powershell
# Get DPI scale factor
$dpiScale = Get-ResponsiveDPIScale

# Scale a value
$scaledWidth = Get-ResponsiveScaledValue -Value 100  # Returns 100 * dpiScale

# Common resolutions and scale factors:
# 1920x1080 (Full HD)  = 1.0x
# 2560x1440 (QHD)      = 1.25x or 1.5x
# 3840x2160 (4K UHD)   = 1.5x or 2.0x
```

### Windows Forms Best Practices

```powershell
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Enable DPI awareness
[System.Windows.Forms.Application]::EnableVisualStyles()
[System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

# Create form with proper settings
$form = New-Object System.Windows.Forms.Form
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$form.MinimumSize = New-Object System.Drawing.Size(400, 300)
```

---

## Security Requirements

### Credential Management

```powershell
# NEVER do this:
$password = "MyPassword123"  # WRONG!

# DO this instead:
$credential = Get-Credential -Message "Enter credentials"

# Or use Windows Credential Manager:
$credential = Get-StoredCredential -Target "MyApp"

# For automation, use secure files:
$securePassword = Get-Content ".\password.txt" | ConvertTo-SecureString
$credential = New-Object PSCredential("username", $securePassword)
```

### Input Validation

```powershell
function Test-SafePath {
    param([string]$Path)

    # Prevent path traversal
    $normalizedPath = [System.IO.Path]::GetFullPath($Path)
    $allowedRoot = "C:\SafeDirectory"

    if (-not $normalizedPath.StartsWith($allowedRoot)) {
        throw "Access denied: Path outside allowed directory"
    }

    return $normalizedPath
}
```

### Code Signing

```powershell
# Sign a script
$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert | Select-Object -First 1
Set-AuthenticodeSignature -FilePath ".\script.ps1" -Certificate $cert -TimestampServer "http://timestamp.digicert.com"

# Verify signature
Get-AuthenticodeSignature -FilePath ".\script.ps1"
```

---

## Testing with Pester 5.x

### Basic Test Structure

```powershell
BeforeAll {
    # Import module or dot-source script
    . $PSScriptRoot\..\Source\MyFunction.ps1
}

Describe "Get-Something" {
    Context "When given valid input" {
        BeforeAll {
            $result = Get-Something -Name "Test"
        }

        It "Should return a non-null result" {
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should return correct type" {
            $result | Should -BeOfType [PSCustomObject]
        }

        It "Should have expected property" {
            $result.Name | Should -Be "Test"
        }
    }

    Context "When given invalid input" {
        It "Should throw on null input" {
            { Get-Something -Name $null } | Should -Throw
        }
    }
}
```

### Mocking

```powershell
Describe "Send-Report" {
    BeforeAll {
        Mock Send-MailMessage { }
        Mock Write-EventLog { }
    }

    It "Should send email" {
        Send-Report -To "user@example.com" -Subject "Test"

        Should -Invoke Send-MailMessage -Times 1 -Exactly
    }

    It "Should log event" {
        Send-Report -To "user@example.com" -Subject "Test"

        Should -Invoke Write-EventLog -Times 1
    }
}
```

### Code Coverage

```powershell
# Run tests with coverage
$config = New-PesterConfiguration
$config.Run.Path = ".\Tests"
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = ".\Source\*.ps1"
$config.CodeCoverage.OutputPath = ".\coverage.xml"

Invoke-Pester -Configuration $config
```

**Target: 80%+ code coverage**

---

## Performance Optimization

### Array Operations

```powershell
# SLOW - Array concatenation
$array = @()
foreach ($i in 1..10000) {
    $array += $i  # Creates new array each time!
}

# FAST - Generic List
$list = [System.Collections.Generic.List[int]]::new()
foreach ($i in 1..10000) {
    $list.Add($i)
}

# FAST - ArrayList
$arrayList = [System.Collections.ArrayList]::new()
foreach ($i in 1..10000) {
    [void]$arrayList.Add($i)
}
```

### String Operations

```powershell
# SLOW - String concatenation
$result = ""
foreach ($item in $items) {
    $result += $item + ","
}

# FAST - StringBuilder
$sb = [System.Text.StringBuilder]::new()
foreach ($item in $items) {
    [void]$sb.Append($item).Append(",")
}
$result = $sb.ToString()

# FAST - Join operator
$result = $items -join ","
```

### Filtering

```powershell
# SLOWER - Where-Object cmdlet
$large = Get-ChildItem -Recurse | Where-Object { $_.Length -gt 1MB }

# FASTER - Use -Filter parameter when available
$large = Get-ChildItem -Recurse -Filter "*.log" | Where-Object { $_.Length -gt 1MB }

# FASTER - .Where() method (PS 4+)
$items = @(Get-ChildItem -Recurse)
$large = $items.Where({ $_.Length -gt 1MB })
```

### Hash Tables for Lookups

```powershell
# SLOW - Searching array repeatedly
$users = Get-ADUser -Filter *
foreach ($name in $namesToFind) {
    $user = $users | Where-Object { $_.SamAccountName -eq $name }
}

# FAST - Hash table lookup
$userHash = @{}
Get-ADUser -Filter * | ForEach-Object { $userHash[$_.SamAccountName] = $_ }
foreach ($name in $namesToFind) {
    $user = $userHash[$name]  # O(1) lookup
}
```

---

## PowerShell Compatibility

### Version Detection

```powershell
# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion

if ($psVersion.Major -ge 7) {
    # PowerShell 7+ specific code
    $result = Get-Content $file -Raw | ConvertFrom-Json -AsHashtable
}
elseif ($psVersion.Major -eq 5) {
    # Windows PowerShell 5.1
    $result = Get-Content $file -Raw | ConvertFrom-Json
}
```

### Cross-Version Patterns

```powershell
# Use CIM instead of WMI (works in both 5.1 and 7+)
$os = Get-CimInstance -ClassName Win32_OperatingSystem

# Avoid Get-WmiObject (deprecated in PS 7)
# $os = Get-WmiObject -Class Win32_OperatingSystem  # Don't use

# Check for cmdlet availability
if (Get-Command -Name Get-CimInstance -ErrorAction SilentlyContinue) {
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk
}
```

### Windows Version Detection

```powershell
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$version = [Version]$os.Version

switch ($version.Build) {
    { $_ -ge 22000 } { "Windows 11" }
    { $_ -ge 10240 } { "Windows 10" }
    { $_ -ge 9600 }  { "Windows 8.1" }
    default          { "Earlier Windows" }
}
```

---

## Module Development

### Standard Module Structure

```
ModuleName/
├── ModuleName.psd1          # Module manifest
├── ModuleName.psm1          # Root module
├── Public/                  # Exported functions
│   ├── Get-Something.ps1
│   └── Set-Something.ps1
├── Private/                 # Internal functions
│   └── Helper-Function.ps1
├── Classes/                 # PowerShell classes
│   └── MyClass.ps1
├── Tests/                   # Pester tests
│   └── ModuleName.Tests.ps1
└── en-US/                   # Help files
    └── about_ModuleName.help.txt
```

### Module Manifest Template

```powershell
@{
    RootModule        = 'ModuleName.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
    CompanyName       = 'myTech.Today'
    Copyright         = '(c) 2025 myTech.Today. All rights reserved.'
    Description       = 'Module description'
    PowerShellVersion = '5.1'

    FunctionsToExport = @('Get-Something', 'Set-Something')
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags       = @('Tag1', 'Tag2')
            ProjectUri = 'https://github.com/mytech-today-now/ModuleName'
            LicenseUri = 'https://github.com/mytech-today-now/ModuleName/blob/main/LICENSE'
        }
    }
}
```

---

## Common Design Patterns

### Singleton Pattern

```powershell
class ConfigManager {
    static [ConfigManager] $Instance
    [hashtable] $Settings

    static [ConfigManager] GetInstance() {
        if ([ConfigManager]::Instance -eq $null) {
            [ConfigManager]::Instance = [ConfigManager]::new()
        }
        return [ConfigManager]::Instance
    }

    hidden ConfigManager() {
        $this.Settings = @{}
    }
}

# Usage
$config = [ConfigManager]::GetInstance()
$config.Settings['Theme'] = 'Dark'
```

### Retry Pattern

```powershell
function Invoke-WithRetry {
    param(
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 3,
        [int]$DelaySeconds = 2
    )

    $attempt = 0
    do {
        $attempt++
        try {
            return & $ScriptBlock
        }
        catch {
            if ($attempt -ge $MaxRetries) {
                throw "Failed after $MaxRetries attempts: $_"
            }
            Write-Warning "Attempt $attempt failed, retrying in $DelaySeconds seconds..."
            Start-Sleep -Seconds $DelaySeconds
            $DelaySeconds *= 2  # Exponential backoff
        }
    } while ($true)
}

# Usage
$result = Invoke-WithRetry -ScriptBlock {
    Invoke-RestMethod -Uri $apiUrl -ErrorAction Stop
} -MaxRetries 5
```

### Factory Pattern

```powershell
class LoggerFactory {
    static [object] CreateLogger([string]$Type) {
        switch ($Type) {
            'File'    { return [FileLogger]::new() }
            'Event'   { return [EventLogger]::new() }
            'Console' { return [ConsoleLogger]::new() }
            default   { throw "Unknown logger type: $Type" }
        }
    }
}

# Usage
$logger = [LoggerFactory]::CreateLogger('File')
$logger.Log("Message")
```

### Observer Pattern

```powershell
class EventPublisher {
    [System.Collections.Generic.List[scriptblock]] $Subscribers = @()

    [void] Subscribe([scriptblock]$Handler) {
        $this.Subscribers.Add($Handler)
    }

    [void] Publish([object]$EventData) {
        foreach ($handler in $this.Subscribers) {
            & $handler $EventData
        }
    }
}

# Usage
$publisher = [EventPublisher]::new()
$publisher.Subscribe({ param($data) Write-Host "Received: $data" })
$publisher.Publish("Hello!")
```

---

## Troubleshooting

### Common Issues

**Execution Policy:**
```powershell
# Check current policy
Get-ExecutionPolicy -List

# Set for current user (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Module Import Issues:**
```powershell
# Check module path
$env:PSModulePath -split ';'

# Force reimport
Remove-Module ModuleName -ErrorAction SilentlyContinue
Import-Module ModuleName -Force -Verbose
```

**Encoding Issues:**
```powershell
# Read with specific encoding
Get-Content -Path $file -Encoding UTF8

# Write with BOM for compatibility
$content | Out-File -Path $file -Encoding UTF8
```

### Debugging Techniques

```powershell
# Set breakpoint
Set-PSBreakpoint -Script "script.ps1" -Line 50

# Conditional breakpoint
Set-PSBreakpoint -Script "script.ps1" -Line 50 -Action {
    if ($item.Name -eq "Problem") { break }
}

# Enable verbose output
$VerbosePreference = "Continue"

# Trace command execution
Trace-Command -Name ParameterBinding -Expression { Get-ChildItem } -PSHost
```

---

## Development Checklist

### Before Writing Code
- [ ] Review requirements and scope
- [ ] Check compatibility requirements (PS 5.1 / 7+)
- [ ] Understand security implications
- [ ] Plan function/module structure

### During Development
- [ ] Follow naming conventions (Verb-Noun)
- [ ] Use approved verbs (`Get-Verb`)
- [ ] Implement proper error handling
- [ ] Add comment-based help
- [ ] Validate all input parameters
- [ ] Use appropriate design patterns
- [ ] Implement logging
- [ ] No emoji or special Unicode characters

### Before Deployment
- [ ] Write tests (80%+ coverage)
- [ ] Run PSScriptAnalyzer
- [ ] Test on target platforms
- [ ] Update documentation
- [ ] Sign code (if required)
- [ ] Version appropriately (SemVer)

---

## Required Tools

```powershell
# Install essential modules
Install-Module -Name Pester -Force -SkipPublisherCheck
Install-Module -Name PSScriptAnalyzer -Force
Install-Module -Name platyPS -Force
```

## External Resources

- [PowerShell Documentation](https://docs.microsoft.com/powershell)
- [PowerShell Gallery](https://www.powershellgallery.com)
- [Pester Documentation](https://pester.dev)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer)

---

## Advanced GUI Responsiveness

### Screen Resolution Reference

| Resolution | Name | Aspect Ratio | DPI Scale |
|------------|------|--------------|-----------|
| 640x480 | VGA | 4:3 | 0.5x |
| 800x600 | SVGA | 4:3 | 0.67x |
| 1024x768 | XGA | 4:3 | 0.8x |
| 1280x720 | HD | 16:9 | 0.67x |
| 1280x800 | WXGA | 16:10 | 0.67x |
| 1366x768 | WXGA | ~16:9 | 0.71x |
| 1440x900 | WXGA+ | 16:10 | 0.75x |
| 1600x900 | HD+ | 16:9 | 0.83x |
| 1680x1050 | WSXGA+ | 16:10 | 0.875x |
| 1920x1080 | Full HD | 16:9 | 1.0x (baseline) |
| 1920x1200 | WUXGA | 16:10 | 1.0x |
| 2560x1440 | QHD | 16:9 | 1.25x-1.5x |
| 2560x1600 | WQXGA | 16:10 | 1.25x-1.5x |
| 3440x1440 | UWQHD | 21:9 | 1.25x |
| 3840x2160 | 4K UHD | 16:9 | 1.5x-2.0x |
| 5120x2880 | 5K | 16:9 | 2.0x-2.5x |
| 7680x4320 | 8K UHD | 16:9 | 3.0x-4.0x |

### DPI Detection Implementation

```powershell
function Get-DPIScaleFactor {
    <#
    .SYNOPSIS
        Detects current screen DPI and returns appropriate scale factor.
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param()

    Add-Type -AssemblyName System.Windows.Forms

    # Get primary screen
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $bounds = $screen.Bounds

    # Calculate DPI using graphics context
    $graphics = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero)
    $dpiX = $graphics.DpiX
    $graphics.Dispose()

    # Base DPI is 96 (100% scaling)
    $scaleFactor = $dpiX / 96.0

    Write-Verbose "Screen: $($bounds.Width)x$($bounds.Height), DPI: $dpiX, Scale: $scaleFactor"

    return $scaleFactor
}

function Get-ScaledDimension {
    param(
        [Parameter(Mandatory)]
        [int]$BaseValue,
        [double]$ScaleFactor = (Get-DPIScaleFactor)
    )

    return [int]([Math]::Round($BaseValue * $ScaleFactor))
}
```

### Responsive Form Template

```powershell
function New-ResponsiveApplicationForm {
    param(
        [string]$Title = "Application",
        [int]$BaseWidth = 800,
        [int]$BaseHeight = 600,
        [int]$MinWidth = 400,
        [int]$MinHeight = 300
    )

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)

    $scale = Get-DPIScaleFactor

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(
        (Get-ScaledDimension $BaseWidth $scale),
        (Get-ScaledDimension $BaseHeight $scale)
    )
    $form.MinimumSize = New-Object System.Drawing.Size(
        (Get-ScaledDimension $MinWidth $scale),
        (Get-ScaledDimension $MinHeight $scale)
    )
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
    $form.Font = New-Object System.Drawing.Font("Segoe UI", (9 * $scale))

    # Store scale factor for child control creation
    $form.Tag = @{ Scale = $scale }

    return $form
}
```

### Responsive Control Patterns

```powershell
# Anchoring for automatic resize
$textBox.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
                  [System.Windows.Forms.AnchorStyles]::Left -bor
                  [System.Windows.Forms.AnchorStyles]::Right

# Docking for full-width/height
$listBox.Dock = [System.Windows.Forms.DockStyle]::Fill

# TableLayoutPanel for grid layouts
$tableLayout = New-Object System.Windows.Forms.TableLayoutPanel
$tableLayout.Dock = [System.Windows.Forms.DockStyle]::Fill
$tableLayout.ColumnCount = 2
$tableLayout.RowCount = 3
$tableLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle(
    [System.Windows.Forms.SizeType]::Percent, 30)))
$tableLayout.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle(
    [System.Windows.Forms.SizeType]::Percent, 70)))

# FlowLayoutPanel for dynamic wrapping
$flowLayout = New-Object System.Windows.Forms.FlowLayoutPanel
$flowLayout.Dock = [System.Windows.Forms.DockStyle]::Top
$flowLayout.AutoSize = $true
$flowLayout.WrapContents = $true
```

---

## Extended Error Handling Patterns

### Comprehensive Error Logging Function

```powershell
function Write-DetailedError {
    <#
    .SYNOPSIS
        Writes comprehensive error information to log file.
    .DESCRIPTION
        Captures detailed error information including exception type, message,
        stack trace, inner exceptions, Windows error codes, and context.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter()]
        [string]$LogPath = "$env:USERPROFILE\myTech.Today\logs\$($MyInvocation.MyCommand.Name -replace '\.ps1$','').md",

        [Parameter()]
        [string]$ArchivePath = "$env:USERPROFILE\myTech.Today\logs\$($MyInvocation.MyCommand.Name -replace '\.ps1$','').$(Get-Date -Format 'yyyy-MM').md",

        [Parameter()]
        [hashtable]$AdditionalContext = @{}
    )

    process {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $separator = "=" * 80

        $errorDetails = [System.Text.StringBuilder]::new()
        [void]$errorDetails.AppendLine($separator)
        [void]$errorDetails.AppendLine("TIMESTAMP: $timestamp")
        [void]$errorDetails.AppendLine("ERROR TYPE: $($ErrorRecord.Exception.GetType().FullName)")
        [void]$errorDetails.AppendLine("MESSAGE: $($ErrorRecord.Exception.Message)")
        [void]$errorDetails.AppendLine("")

        # Script location
        if ($ErrorRecord.InvocationInfo) {
            [void]$errorDetails.AppendLine("LOCATION:")
            [void]$errorDetails.AppendLine("  Script: $($ErrorRecord.InvocationInfo.ScriptName)")
            [void]$errorDetails.AppendLine("  Line: $($ErrorRecord.InvocationInfo.ScriptLineNumber)")
            [void]$errorDetails.AppendLine("  Command: $($ErrorRecord.InvocationInfo.Line.Trim())")
            [void]$errorDetails.AppendLine("")
        }

        # Stack trace
        if ($ErrorRecord.ScriptStackTrace) {
            [void]$errorDetails.AppendLine("STACK TRACE:")
            [void]$errorDetails.AppendLine($ErrorRecord.ScriptStackTrace)
            [void]$errorDetails.AppendLine("")
        }

        # Inner exceptions
        $innerException = $ErrorRecord.Exception.InnerException
        $depth = 0
        while ($innerException -and $depth -lt 5) {
            [void]$errorDetails.AppendLine("INNER EXCEPTION ($depth):")
            [void]$errorDetails.AppendLine("  Type: $($innerException.GetType().FullName)")
            [void]$errorDetails.AppendLine("  Message: $($innerException.Message)")
            $innerException = $innerException.InnerException
            $depth++
        }

        # Additional context
        if ($AdditionalContext.Count -gt 0) {
            [void]$errorDetails.AppendLine("CONTEXT:")
            foreach ($key in $AdditionalContext.Keys) {
                [void]$errorDetails.AppendLine("  ${key}: $($AdditionalContext[$key])")
            }
        }

        [void]$errorDetails.AppendLine($separator)

        # Ensure directory exists
        $logDir = Split-Path $LogPath -Parent
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }

        # Append to log file
        $errorDetails.ToString() | Add-Content -Path $LogPath -Encoding UTF8

        # Also write to error stream
        Write-Error $ErrorRecord.Exception.Message
    }
}
```

### Error Recovery Patterns

```powershell
function Invoke-WithRecovery {
    <#
    .SYNOPSIS
        Executes a script block with automatic recovery strategies.
    #>
    param(
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [Parameter()]
        [scriptblock]$RecoveryAction,

        [Parameter()]
        [scriptblock]$FinalAction,

        [Parameter()]
        [int]$MaxRetries = 3,

        [Parameter()]
        [int]$RetryDelayMs = 1000
    )

    $attempt = 0
    $lastError = $null

    do {
        $attempt++
        try {
            $result = & $ScriptBlock

            # Success - run final action if defined
            if ($FinalAction) {
                & $FinalAction
            }

            return $result
        }
        catch {
            $lastError = $_
            Write-Warning "Attempt $attempt failed: $($_.Exception.Message)"

            # Run recovery action if defined
            if ($RecoveryAction) {
                try {
                    & $RecoveryAction $_
                }
                catch {
                    Write-Warning "Recovery action failed: $($_.Exception.Message)"
                }
            }

            if ($attempt -lt $MaxRetries) {
                Start-Sleep -Milliseconds $RetryDelayMs
                $RetryDelayMs *= 2  # Exponential backoff
            }
        }
    } while ($attempt -lt $MaxRetries)

    # All retries exhausted
    if ($FinalAction) {
        & $FinalAction
    }

    throw "Operation failed after $MaxRetries attempts. Last error: $($lastError.Exception.Message)"
}

# Usage example
$result = Invoke-WithRecovery -ScriptBlock {
    Invoke-RestMethod -Uri $apiUrl -Method Get -ErrorAction Stop
} -RecoveryAction {
    param($error)
    Write-Host "Clearing cache and retrying..."
    Clear-DnsClientCache
} -FinalAction {
    Write-Host "Operation completed (success or failure)"
} -MaxRetries 5
```

---

## Advanced Testing Patterns

### Test Data Management

```powershell
Describe "User Management Functions" {
    BeforeAll {
        # Create test data
        $script:TestUsers = @(
            [PSCustomObject]@{ Name = "User1"; Email = "user1@test.com"; Active = $true }
            [PSCustomObject]@{ Name = "User2"; Email = "user2@test.com"; Active = $false }
            [PSCustomObject]@{ Name = "User3"; Email = "user3@test.com"; Active = $true }
        )

        # Mock external dependencies
        Mock Get-ADUser { return $script:TestUsers }
        Mock Set-ADUser { }
    }

    AfterAll {
        # Cleanup
        $script:TestUsers = $null
    }

    Context "Get-ActiveUsers" {
        It "Should return only active users" {
            $result = Get-ActiveUsers
            $result | Should -HaveCount 2
            $result | ForEach-Object { $_.Active | Should -BeTrue }
        }
    }

    Context "Disable-InactiveUsers" -Tag "Destructive" {
        BeforeEach {
            # Reset mock call history
            $script:DisabledUsers = @()
            Mock Set-ADUser {
                $script:DisabledUsers += $Identity
            }
        }

        It "Should disable inactive users" {
            Disable-InactiveUsers -WhatIf:$false
            Should -Invoke Set-ADUser -Times 1 -Exactly
        }
    }
}
```

### Parameterized Tests

```powershell
Describe "ConvertTo-Bytes" {
    It "Should convert '<Input>' to <Expected> bytes" -TestCases @(
        @{ Input = "1KB"; Expected = 1024 }
        @{ Input = "1MB"; Expected = 1048576 }
        @{ Input = "1GB"; Expected = 1073741824 }
        @{ Input = "1.5KB"; Expected = 1536 }
        @{ Input = "100"; Expected = 100 }
    ) {
        param($Input, $Expected)
        ConvertTo-Bytes -Value $Input | Should -Be $Expected
    }

    It "Should throw for invalid input '<Input>'" -TestCases @(
        @{ Input = "abc" }
        @{ Input = "-1KB" }
        @{ Input = "" }
        @{ Input = $null }
    ) {
        param($Input)
        { ConvertTo-Bytes -Value $Input } | Should -Throw
    }
}
```

### Integration Test Template

```powershell
Describe "Database Integration Tests" -Tag "Integration" {
    BeforeAll {
        # Setup test database
        $script:TestDbPath = Join-Path $TestDrive "test.db"
        Initialize-TestDatabase -Path $script:TestDbPath

        # Import module with test configuration
        $env:DATABASE_PATH = $script:TestDbPath
        Import-Module .\MyModule.psd1 -Force
    }

    AfterAll {
        # Cleanup
        Remove-Module MyModule -ErrorAction SilentlyContinue
        if (Test-Path $script:TestDbPath) {
            Remove-Item $script:TestDbPath -Force
        }
    }

    Context "Database Operations" {
        It "Should create a new record" {
            $record = New-DatabaseRecord -Name "Test" -Value "Data"
            $record.Id | Should -BeGreaterThan 0
        }

        It "Should retrieve created record" {
            $record = Get-DatabaseRecord -Name "Test"
            $record | Should -Not -BeNullOrEmpty
            $record.Value | Should -Be "Data"
        }

        It "Should update existing record" {
            Update-DatabaseRecord -Name "Test" -Value "Updated"
            $record = Get-DatabaseRecord -Name "Test"
            $record.Value | Should -Be "Updated"
        }

        It "Should delete record" {
            Remove-DatabaseRecord -Name "Test"
            $record = Get-DatabaseRecord -Name "Test"
            $record | Should -BeNullOrEmpty
        }
    }
}
```

---

## Deployment Automation

### Build Script Template

```powershell
#Requires -Version 5.1

<#
.SYNOPSIS
    Build and package the module for deployment.
.DESCRIPTION
    Compiles the module, runs tests, and creates deployment package.
#>

[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Release',

    [switch]$SkipTests,

    [switch]$CreatePackage
)

$ErrorActionPreference = 'Stop'
$script:BuildRoot = $PSScriptRoot
$script:ModuleName = 'MyModule'
$script:OutputPath = Join-Path $BuildRoot 'Output'
$script:TestResults = Join-Path $BuildRoot 'TestResults'

# Clean output
if (Test-Path $OutputPath) {
    Remove-Item $OutputPath -Recurse -Force
}
New-Item $OutputPath -ItemType Directory -Force | Out-Null

# Copy module files
$moduleOutput = Join-Path $OutputPath $ModuleName
New-Item $moduleOutput -ItemType Directory -Force | Out-Null

Copy-Item "$BuildRoot\$ModuleName.psd1" $moduleOutput
Copy-Item "$BuildRoot\$ModuleName.psm1" $moduleOutput
Copy-Item "$BuildRoot\Public" $moduleOutput -Recurse
Copy-Item "$BuildRoot\Private" $moduleOutput -Recurse

# Update version from git tag
$gitTag = git describe --tags --abbrev=0 2>$null
if ($gitTag -match '^\d+\.\d+\.\d+') {
    $version = $gitTag
    Update-ModuleManifest -Path "$moduleOutput\$ModuleName.psd1" -ModuleVersion $version
    Write-Host "[OK] Version set to $version" -ForegroundColor Green
}

# Run tests
if (-not $SkipTests) {
    Write-Host "[INFO] Running tests..." -ForegroundColor Cyan

    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = "$BuildRoot\Tests"
    $pesterConfig.Output.Verbosity = 'Detailed'
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = "$TestResults\results.xml"
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = "$BuildRoot\Public\*.ps1", "$BuildRoot\Private\*.ps1"

    $testResult = Invoke-Pester -Configuration $pesterConfig

    if ($testResult.FailedCount -gt 0) {
        throw "[FAIL] $($testResult.FailedCount) tests failed"
    }

    Write-Host "[OK] All $($testResult.PassedCount) tests passed" -ForegroundColor Green
}

# Create package
if ($CreatePackage) {
    Write-Host "[INFO] Creating package..." -ForegroundColor Cyan

    $packagePath = Join-Path $OutputPath "$ModuleName.zip"
    Compress-Archive -Path $moduleOutput -DestinationPath $packagePath -Force

    $hash = (Get-FileHash $packagePath -Algorithm SHA256).Hash
    Write-Host "[OK] Package created: $packagePath" -ForegroundColor Green
    Write-Host "     SHA256: $hash" -ForegroundColor Gray
}

Write-Host "[OK] Build completed successfully" -ForegroundColor Green
```

### CI/CD Integration

Use GitHub Actions with `windows-latest` runner. Key steps: checkout, install Pester/PSScriptAnalyzer, run tests.

---

## Security Best Practices Extended

### Secure String Handling

```powershell
# Convert plain text to secure string (for automation)
$securePassword = ConvertTo-SecureString "PlainTextPassword" -AsPlainText -Force

# Read secure string from encrypted file
$securePassword = Get-Content ".\password.enc" | ConvertTo-SecureString

# Create credential object
$credential = [PSCredential]::new("domain\username", $securePassword)

# Export secure string (machine/user specific)
$securePassword | ConvertFrom-SecureString | Set-Content ".\password.enc"

# For cross-machine use, specify a key
$key = (1..16)  # 16, 24, or 32 bytes for AES
$encrypted = $securePassword | ConvertFrom-SecureString -Key $key
$decrypted = $encrypted | ConvertTo-SecureString -Key $key
```

### Input Sanitization

```powershell
function Invoke-SafeSqlQuery {
    param(
        [Parameter(Mandatory)]
        [string]$ConnectionString,

        [Parameter(Mandatory)]
        [string]$Query,

        [Parameter()]
        [hashtable]$Parameters = @{}
    )

    $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
    $command = $connection.CreateCommand()

    # Use parameterized queries - NEVER concatenate user input!
    $command.CommandText = $Query

    foreach ($key in $Parameters.Keys) {
        $param = $command.CreateParameter()
        $param.ParameterName = "@$key"
        $param.Value = $Parameters[$key]
        $command.Parameters.Add($param) | Out-Null
    }

    try {
        $connection.Open()
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset) | Out-Null
        return $dataset.Tables[0]
    }
    finally {
        $connection.Close()
        $connection.Dispose()
    }
}

# Usage - parameters are automatically escaped
$results = Invoke-SafeSqlQuery -ConnectionString $connStr -Query @"
    SELECT * FROM Users WHERE Username = @username AND Status = @status
"@ -Parameters @{
    username = $userInput  # Safe even if user enters "'; DROP TABLE Users;--"
    status = "Active"
}
```

### Path Validation

```powershell
function Test-SafePath {
    <#
    .SYNOPSIS
        Validates a path is within allowed boundaries.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string[]]$AllowedRoots,

        [switch]$MustExist
    )

    # Resolve to absolute path
    $resolvedPath = [System.IO.Path]::GetFullPath($Path)

    # Check for path traversal attempts
    if ($resolvedPath -match '\.\.' -or $Path -match '\.\.' ) {
        throw "Path traversal detected: $Path"
    }

    # Verify within allowed roots
    $isAllowed = $false
    foreach ($root in $AllowedRoots) {
        $resolvedRoot = [System.IO.Path]::GetFullPath($root)
        if ($resolvedPath.StartsWith($resolvedRoot, [StringComparison]::OrdinalIgnoreCase)) {
            $isAllowed = $true
            break
        }
    }

    if (-not $isAllowed) {
        throw "Path not within allowed directories: $resolvedPath"
    }

    # Check existence if required
    if ($MustExist -and -not (Test-Path $resolvedPath)) {
        throw "Path does not exist: $resolvedPath"
    }

    return $resolvedPath
}

# Usage
$safePath = Test-SafePath -Path $userInput -AllowedRoots @("C:\Data", "D:\Shared") -MustExist
```

---

## PowerShell Classes

### Class Definition Pattern

```powershell
class Person {
    [string]$FirstName
    [string]$LastName
    hidden [string]$_id

    Person([string]$first, [string]$last) {
        $this.FirstName = $first; $this.LastName = $last
        $this._id = [guid]::NewGuid().ToString()
    }

    [string] FullName() { return "$($this.FirstName) $($this.LastName)" }
}

# Inheritance
class Employee : Person {
    [string]$Department
    Employee([string]$first, [string]$last, [string]$dept) : base($first, $last) {
        $this.Department = $dept
    }
}
```

---

## Configuration Management

### JSON Configuration Handler

```powershell
class ConfigurationManager {
    [string]$ConfigPath
    [hashtable]$Settings
    hidden [datetime]$_lastLoaded

    ConfigurationManager([string]$configPath) {
        $this.ConfigPath = $configPath
        $this.Load()
    }

    [void] Load() {
        if (Test-Path $this.ConfigPath) {
            $json = Get-Content $this.ConfigPath -Raw | ConvertFrom-Json
            $this.Settings = @{}

            # Convert PSObject to hashtable
            foreach ($prop in $json.PSObject.Properties) {
                $this.Settings[$prop.Name] = $prop.Value
            }
        }
        else {
            $this.Settings = @{}
        }
        $this._lastLoaded = Get-Date
    }

    [void] Save() {
        $dir = Split-Path $this.ConfigPath -Parent
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }
        $this.Settings | ConvertTo-Json -Depth 10 | Set-Content $this.ConfigPath
    }

    [object] Get([string]$key, [object]$default = $null) {
        if ($this.Settings.ContainsKey($key)) {
            return $this.Settings[$key]
        }
        return $default
    }

    [void] Set([string]$key, [object]$value) {
        $this.Settings[$key] = $value
    }
}

# Usage
$config = [ConfigurationManager]::new("$env:USERPROFILE\myTech.Today\config.json")
$config.Set("Theme", "Dark")
$config.Set("MaxRetries", 5)
$config.Save()

$theme = $config.Get("Theme", "Light")
```

---

## Progress Reporting

### Advanced Progress Pattern

```powershell
function Invoke-BulkOperation {
    param(
        [Parameter(Mandatory)]
        [object[]]$Items,

        [Parameter(Mandatory)]
        [scriptblock]$Operation,

        [string]$ActivityName = "Processing items"
    )

    $total = $Items.Count
    $completed = 0
    $failed = 0
    $startTime = Get-Date
    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($item in $Items) {
        $completed++
        $percentComplete = [math]::Round(($completed / $total) * 100, 1)

        # Calculate ETA
        $elapsed = (Get-Date) - $startTime
        if ($completed -gt 1) {
            $avgTimePerItem = $elapsed.TotalSeconds / ($completed - 1)
            $remainingItems = $total - $completed
            $eta = [timespan]::FromSeconds($avgTimePerItem * $remainingItems)
            $etaString = "ETA: $($eta.ToString('hh\:mm\:ss'))"
        }
        else {
            $etaString = "Calculating..."
        }

        Write-Progress -Activity $ActivityName `
                       -Status "$completed of $total ($percentComplete%) - $etaString" `
                       -PercentComplete $percentComplete `
                       -CurrentOperation "Processing: $item"

        try {
            $result = & $Operation $item
            $results.Add([PSCustomObject]@{
                Item = $item
                Success = $true
                Result = $result
                Error = $null
            })
        }
        catch {
            $failed++
            $results.Add([PSCustomObject]@{
                Item = $item
                Success = $false
                Result = $null
                Error = $_.Exception.Message
            })
        }
    }

    Write-Progress -Activity $ActivityName -Completed
    return $results
}
```