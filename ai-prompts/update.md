# mTTCleaner Maintenance and Update Guide

**Project:** mTTCleaner - Browser Cache and Database Cleanup Tool
**Developer:** myTech.Today
**Author:** Kyle C. Rode
**Copyright:** (c) 2025 myTech.Today. All rights reserved.
**Script:** `mTTCleaner.ps1`
**Current Version:** 2.2.0

---

## Purpose

This guide provides instructions for maintaining, updating, and enhancing the mTTCleaner PowerShell script. All changes must adhere to the standards defined in `.augment/core-guidelines.md` and maintain cross-platform compatibility across Windows, macOS, and Linux.

**CRITICAL REQUIREMENTS:**
- **ALWAYS follow** `.augment/core-guidelines.md` for all PowerShell development standards
- **PRESERVE existing functionality** - do not break current features
- **MAINTAIN cross-platform compatibility** - test on Windows, macOS, and Linux
- **USE ASCII characters only** - NO emoji or Unicode symbols (use `[OK]`, `[FAIL]`, `[WARN]`, `[INFO]`)
- **FOLLOW myTech.Today branding** - always write as `myTech.Today` (lowercase m, capital T's, period between)
- **INCREMENT version** appropriately using semantic versioning (MAJOR.MINOR.PATCH)

---

## Core Standards Reference

All code changes MUST comply with:
- **Character Encoding:** ASCII only, no emoji (see `.augment/core-guidelines.md` lines 24-53)
- **Branding:** myTech.Today format (see `.augment/core-guidelines.md` lines 8-21)
- **Installation Paths:** Cross-platform paths (see `.augment/core-guidelines.md` lines 56-118)
- **Naming Conventions:** Functions, variables, parameters (see `.augment/core-guidelines.md` lines 154-172)
- **Error Handling:** Try-catch patterns (see `.augment/core-guidelines.md` lines 330-369)
- **Logging:** Centralized logging (see `.augment/core-guidelines.md` lines 144-151)

---

## Current Architecture

### Script Structure
```
mTTCleaner.ps1
├── Comment-Based Help (.SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE)
├── Parameter Block (with ValidateSet for browsers)
├── Initialization
│   ├── Logging setup
│   ├── Platform detection ($IsWindows, $IsMacOS, $IsLinux)
│   └── Path resolution
├── Core Functions
│   ├── Get-BrowserPath - Returns platform-specific browser profile paths
│   ├── Get-InstalledBrowsers - Detects installed browsers
│   ├── Clear-BrowserCache - Removes cache files
│   ├── Compact-BrowserDatabase - SQLite database optimization
│   └── Install-SQLite3 - Auto-installs SQLite3 on Windows
├── Browser Definitions ($script:BrowserDefinitions hashtable)
└── Main Execution Logic
```

### Key Data Structures

**$script:BrowserDefinitions** - Hashtable containing all browser configurations:
```powershell
'BrowserKey' = @{
    Name = 'Browser Display Name'
    ProcessNames = @('process1', 'process2')
    ProfileRoot = Get-BrowserPath -BrowserName 'BrowserKey'
    CachePaths = @('Cache', 'Code Cache', 'GPUCache')
    DatabasePaths = @('History', 'Cookies', 'Web Data')
    MetricsPaths = @('*metrics*', '*telemetry*')
    Type = 'Chromium'  # or 'Firefox', 'WebKit', 'KHTML', 'Safari', 'Falkon'
}
```

**Platform Detection Hashtables:**
- `$browserNames` - Windows registry detection
- `$appNames` - macOS .app bundle detection
- `$binaryNames` - Linux binary detection

---

## Common Maintenance Tasks

### 1. Adding New Browsers

See `ai-prompts/expand-browsers.md` for detailed instructions.

**Quick Checklist:**
- [ ] Add browser path to `Get-BrowserPath` function
- [ ] Add browser definition to `$script:BrowserDefinitions`
- [ ] Add detection entry to `$browserNames` (Windows), `$appNames` (macOS), or `$binaryNames` (Linux)
- [ ] Add browser to `ValidateSet` in parameter block
- [ ] Update VERSION file (increment MINOR version)
- [ ] Update CHANGELOG.md
- [ ] Update README.md and README.html
- [ ] Test with `-WhatIf` flag
- [ ] Validate PowerShell syntax

### 2. Updating Logging Module

The script uses the myTech.Today logging module from:
```
https://raw.githubusercontent.com/mytech-today-now/scripts/refs/heads/main/logging.ps1
```

**When to update:**
- New logging features available in the module
- Bug fixes in the logging module
- Enhanced error handling needed

**How to update:**
1. Review changes in the logging module repository
2. Test compatibility with current mTTCleaner implementation
3. Update any function calls if the API changed
4. Test logging on all platforms (Windows, macOS, Linux)
5. Verify log file creation and rotation
6. Update CHANGELOG.md with logging improvements

### 3. Enhancing Cross-Platform Support

**Path Handling:**
- ALWAYS use `Join-Path` for path construction
- NEVER use string concatenation for paths
- Use `$env:HOME` instead of `~` in code
- Test path resolution on all platforms

**Platform-Specific Code:**
```powershell
if ($IsWindows) {
    # Windows-specific code
    $path = "$env:LOCALAPPDATA\myTech.Today\mTTCleaner"
}
elseif ($IsMacOS) {
    # macOS-specific code
    $path = "$env:HOME/Library/Application Support/myTech.Today/mTTCleaner"
}
elseif ($IsLinux) {
    # Linux-specific code
    $path = "$env:HOME/.local/share/myTech.Today/mTTCleaner"
}
```

### 4. Improving Error Handling

Follow the comprehensive error handling pattern from `.augment/core-guidelines.md`:

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
    Write-Error "File not found: $($_.Exception.Message)"
    Write-Log "[FAIL] FileNotFoundException: $($_.Exception.Message)" -Level ERROR
}
catch [System.UnauthorizedAccessException] {
    Write-Error "Access denied: $($_.Exception.Message)"
    Write-Log "[FAIL] UnauthorizedAccessException: $($_.Exception.Message)" -Level ERROR
}
catch {
    Write-Error "Unexpected error: $($_.Exception.Message)"
    Write-Log "[FAIL] Exception: $($_.Exception.GetType().FullName) - $($_.Exception.Message)" -Level ERROR

    # Re-throw if critical
    if (-not $Force) { throw }
}
finally {
    # Always runs - cleanup code
    if ($connection) {
        $connection.Close()
        $connection.Dispose()
    }
}
```

### 5. Performance Optimization

**Array Operations:**
```powershell
# SLOW - Array concatenation
$array = @()
foreach ($item in $items) {
    $array += $item  # Creates new array each time!
}

# FAST - Generic List
$list = [System.Collections.Generic.List[object]]::new()
foreach ($item in $items) {
    $list.Add($item)
}
```

**String Operations:**
```powershell
# SLOW - String concatenation
$result = ""
foreach ($item in $items) {
    $result += $item + ","
}

# FAST - Join operator
$result = $items -join ","
```

**Hash Tables for Lookups:**
```powershell
# SLOW - Searching array repeatedly
foreach ($name in $namesToFind) {
    $browser = $browsers | Where-Object { $_.Name -eq $name }
}

# FAST - Hash table lookup
$browserHash = @{}
$browsers | ForEach-Object { $browserHash[$_.Name] = $_ }
foreach ($name in $namesToFind) {
    $browser = $browserHash[$name]  # O(1) lookup
}
```

---

## Testing Requirements

### 1. Syntax Validation

Always validate PowerShell syntax before committing:

```powershell
# Validate syntax
$null = [System.Management.Automation.PSParser]::Tokenize((Get-Content .\mTTCleaner.ps1 -Raw), [ref]$null)
Write-Host "[OK] Syntax validation passed" -ForegroundColor Green
```

### 2. WhatIf Testing

Test all changes with `-WhatIf` flag:

```powershell
# Test with WhatIf
.\mTTCleaner.ps1 -WhatIf -Automated -Browser Chrome
.\mTTCleaner.ps1 -WhatIf -Automated -Browser All
```

### 3. Cross-Platform Testing

Test on all supported platforms:
- **Windows 10/11** - PowerShell 7+
- **macOS 10.13+** - PowerShell 7+
- **Linux** (Ubuntu, Fedora, Arch) - PowerShell 7+

### 4. Browser Detection Testing

Verify browser detection works correctly:

```powershell
# Test browser detection
.\mTTCleaner.ps1 -Automated -Browser Chrome -Verbose
.\mTTCleaner.ps1 -Automated -Browser Firefox -Verbose
```

---

## Documentation Updates

### Files to Update

When making changes, update these files as appropriate:

1. **VERSION** - Increment version number (semantic versioning)
   - MAJOR: Breaking changes
   - MINOR: New features, backward compatible
   - PATCH: Bug fixes, backward compatible

2. **CHANGELOG.md** - Document all changes
   - Add new version section at the top
   - Use categories: Added, Changed, Fixed, Removed, Security
   - Include technical details and line numbers if relevant

3. **README.md** - Update user-facing documentation
   - Supported browsers list
   - Feature descriptions
   - Usage examples
   - Requirements

4. **README.html** - Update HTML version
   - Keep in sync with README.md
   - Update browser lists
   - Update feature descriptions

5. **Comment-Based Help** - Update in-script help
   - .SYNOPSIS
   - .DESCRIPTION
   - .PARAMETER (for new parameters)
   - .EXAMPLE (add examples for new features)
   - .NOTES (update version and date)

---

## Version Control

### Commit Message Format

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(browsers): add support for Orion, Arc, SigmaOS, iCab, Epiphany, and Konqueror

Added 6 new browsers (4 macOS-exclusive, 2 Linux-specific) to extend
cross-platform browser support. Updated browser definitions, path
resolution, and detection logic.

Closes #123
```

```
fix(logging): handle missing log directory on first run

Added directory creation check before initializing logging to prevent
errors on fresh installations.

Fixes #456
```

---

## Code Quality Checklist

Before committing changes:

### Development Standards
- [ ] Follows `.augment/core-guidelines.md` standards
- [ ] Uses ASCII characters only (no emoji)
- [ ] Follows myTech.Today branding (lowercase m, capital T's)
- [ ] Uses approved PowerShell verbs (`Get-Verb`)
- [ ] Follows naming conventions (Verb-Noun, PascalCase, camelCase)
- [ ] Includes comment-based help for new functions
- [ ] Implements proper error handling (try-catch-finally)
- [ ] Uses cross-platform paths (Join-Path, $IsWindows, $IsMacOS, $IsLinux)
- [ ] Validates all input parameters
- [ ] Implements appropriate logging

### Testing
- [ ] PowerShell syntax validation passed
- [ ] Tested with `-WhatIf` flag
- [ ] Tested on Windows (if applicable)
- [ ] Tested on macOS (if applicable)
- [ ] Tested on Linux (if applicable)
- [ ] Browser detection verified
- [ ] No breaking changes to existing functionality

### Documentation
- [ ] VERSION file updated
- [ ] CHANGELOG.md updated
- [ ] README.md updated (if user-facing changes)
- [ ] README.html updated (if user-facing changes)
- [ ] Comment-based help updated
- [ ] Code comments added for complex logic

### Performance
- [ ] Uses Generic Lists instead of array concatenation
- [ ] Uses hash tables for lookups
- [ ] Avoids unnecessary recursion
- [ ] Uses `-Filter` parameter when available
- [ ] No performance regressions

---

## Common Patterns

### Adding a New Function

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

    .NOTES
        Author: Kyle C. Rode
        Company: myTech.Today
        Version: 2.2.0
        Created: 2025-12-17

    .LINK
        https://mytech.today
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   HelpMessage = "Enter the parameter value")]
        [ValidateNotNullOrEmpty()]
        [string]$ParameterName
    )

    begin {
        Write-Verbose "Starting $($MyInvocation.MyCommand.Name)"
        $results = [System.Collections.Generic.List[object]]::new()
    }

    process {
        try {
            if ($PSCmdlet.ShouldProcess($ParameterName, "Perform operation")) {
                # Main logic here
                $result = [PSCustomObject]@{
                    Name      = $ParameterName
                    Status    = "Success"
                    Timestamp = Get-Date
                }
                $results.Add($result)

                Write-Log "[OK] Operation completed for $ParameterName" -Level SUCCESS
            }
        }
        catch {
            Write-Error "Failed to process $ParameterName : $_"
            Write-Log "[FAIL] Failed to process $ParameterName : $_" -Level ERROR
            if (-not $Force) { throw }
        }
    }

    end {
        Write-Verbose "Completed $($MyInvocation.MyCommand.Name)"
        return $results
    }
}
```

### Adding a New Parameter

```powershell
# Add to parameter block
[Parameter(Mandatory = $false)]
[ValidateSet("Option1", "Option2", "Option3")]
[string]$NewParameter = "Option1",

# Update comment-based help
<#
.PARAMETER NewParameter
    Description of the new parameter. Valid values: Option1, Option2, Option3.
    Default: Option1
#>

# Add usage example
<#
.EXAMPLE
    .\mTTCleaner.ps1 -NewParameter "Option2"

    Runs the script with NewParameter set to Option2.
#>
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
$env:PSModulePath -split [System.IO.Path]::PathSeparator

# Force reimport
Remove-Module ModuleName -ErrorAction SilentlyContinue
Import-Module ModuleName -Force -Verbose
```

**Path Issues:**
```powershell
# Verify path exists
if (-not (Test-Path $path)) {
    Write-Warning "Path does not exist: $path"
    New-Item -Path $path -ItemType Directory -Force | Out-Null
}

# Resolve relative paths
$absolutePath = [System.IO.Path]::GetFullPath($relativePath)
```

---

## External Resources

- **Core Guidelines:** `.augment/core-guidelines.md`
- **Browser Extension Guide:** `ai-prompts/expand-browsers.md`
- **PowerShell Documentation:** https://docs.microsoft.com/powershell
- **myTech.Today Scripts:** https://github.com/mytech-today-now/scripts
- **Logging Module:** https://raw.githubusercontent.com/mytech-today-now/scripts/refs/heads/main/logging.ps1

---

## Final Notes

- **Always test thoroughly** before committing changes
- **Follow existing patterns** - consistency is key
- **Document everything** - future you will thank you
- **Ask for review** - two pairs of eyes are better than one
- **Keep it simple** - complexity is the enemy of maintainability

For questions or clarification, refer to:
- `.augment/core-guidelines.md` - PowerShell development standards
- `mTTCleaner.ps1` - Current implementation
- `README.md` - Project documentation
- `CHANGELOG.md` - Change history