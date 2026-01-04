# mTTCleaner Browser Extension Prompt

**Project:** mTTCleaner - Browser Cache and Database Cleanup Tool
**Developer:** myTech.Today
**Author:** Kyle C. Rode
**Copyright:** (c) 2025 myTech.Today. All rights reserved.
**Script:** `mTTCleaner.ps1`
**Current Version:** 2.1.1

---

## Objective

Extend mTTCleaner by adding support for **additional browsers** not currently included in the script. The script currently supports 22 browsers across Windows, macOS, and Linux platforms.

**CRITICAL REQUIREMENTS:**
- **DO NOT modify existing browser definitions** - preserve all current browser support
- **ONLY add NEW browser entries** to the `$script:BrowserDefinitions` hashtable
- **Follow existing code patterns** exactly as shown in the current implementation
- **Use ASCII characters only** - NO emoji or Unicode symbols (use `[OK]`, `[FAIL]`, `[WARN]`, `[INFO]`)
- **Follow myTech.Today branding** - always write as `myTech.Today` (lowercase m, capital T's, period between)

---

## Current Browser Support (DO NOT MODIFY)

The script currently supports these 22 browsers:
- **Chromium-based:** Chrome, Edge, Brave, Opera, Opera GX, Vivaldi, Chromium, DuckDuckGo, SRWare Iron, Maxthon
- **Firefox-based:** Firefox, LibreWolf, Waterfox, Tor Browser, Pale Moon, SeaMonkey
- **Platform-specific:** Safari (macOS), Falkon (Linux)
- **Other:** Slimjet, Yandex, Ungoogled Chromium, Iridium

---

## Browsers to Add

### macOS-Exclusive Browsers

Add support for these macOS-specific browsers:

1. **Orion Browser**
   - Profile Root: `~/Library/Application Support/Orion`
   - Cache Paths: `Cache`, `Code Cache`, `GPUCache`
   - Database Paths: `History`, `Cookies`, `Web Data`
   - Process Names: `Orion`
   - Type: `Chromium`

2. **Arc Browser**
   - Profile Root: `~/Library/Application Support/Arc`
   - Cache Paths: `Cache`, `Code Cache`, `GPUCache`, `Service Worker/CacheStorage`
   - Database Paths: `History`, `Cookies`, `Web Data`
   - Process Names: `Arc`
   - Type: `Chromium`

3. **SigmaOS**
   - Profile Root: `~/Library/Application Support/SigmaOS`
   - Cache Paths: `Cache`, `Code Cache`, `GPUCache`
   - Database Paths: `History`, `Cookies`, `Web Data`
   - Process Names: `SigmaOS`
   - Type: `Chromium`

4. **iCab**
   - Profile Root: `~/Library/Application Support/iCab`
   - Cache Paths: `Cache`, `WebKit Cache`
   - Database Paths: `History.db`, `Cookies.db`
   - Process Names: `iCab`
   - Type: `WebKit`

### Linux-Specific Browsers

Add support for these Linux-focused browsers:

1. **Midori**
   - Profile Root: `~/.config/midori`
   - Cache Paths: `~/.cache/midori`
   - Database Paths: `history.db`, `cookies.db`
   - Process Names: `midori`
   - Type: `WebKit`

2. **Epiphany (GNOME Web)**
   - Profile Root: `~/.local/share/epiphany`
   - Cache Paths: `~/.cache/epiphany`
   - Database Paths: `ephy-history.db`, `ephy-cookies.sqlite`
   - Process Names: `epiphany`, `epiphany-browser`
   - Type: `WebKit`

3. **Konqueror**
   - Profile Root: `~/.local/share/konqueror`
   - Cache Paths: `~/.cache/konqueror`
   - Database Paths: N/A (uses KDE config system)
   - Process Names: `konqueror`
   - Type: `KHTML`

---

## Implementation Requirements

### 1. Browser Definition Structure

Each new browser MUST follow this exact structure in `$script:BrowserDefinitions`:

```powershell
'BrowserKey' = @{
    Name = 'Browser Display Name'
    ProcessNames = @('process1', 'process2')
    ProfileRoot = Get-BrowserPath -BrowserName 'BrowserKey'
    CachePaths = @('Cache', 'Code Cache', 'GPUCache')
    DatabasePaths = @('History', 'Cookies', 'Web Data')
    MetricsPaths = @('*metrics*', '*telemetry*')
    Type = 'Chromium'  # or 'Firefox', 'WebKit', 'KHTML', 'Safari'
}
```

### 2. Get-BrowserPath Function

Add new browser paths to the `Get-BrowserPath` function following existing patterns:

```powershell
'BrowserKey' {
    if ($IsWindows) {
        return "$env:LOCALAPPDATA\BrowserName\User Data"
    }
    elseif ($IsMacOS) {
        return "$env:HOME/Library/Application Support/BrowserName"
    }
    elseif ($IsLinux) {
        return "$env:HOME/.config/browsername"
    }
}
```

### 3. Browser Name Detection

Add entries to the `$browserNames` hashtable in the `Get-InstalledBrowsers` function:

```powershell
'BrowserKey' = @('Browser Display Name', 'Alternate Name')
```

### 4. Cross-Platform Considerations

- Use `$IsWindows`, `$IsMacOS`, `$IsLinux` for platform detection
- Use `Test-Path` before accessing any paths
- Handle missing directories gracefully with `Write-Verbose` messages
- Use `Join-Path` for all path construction (never string concatenation)

### 5. Error Handling

Follow the existing try-catch pattern:

```powershell
try {
    # Operation
    Write-Log "[OK] Operation completed" -Level SUCCESS
}
catch {
    Write-Log "[FAIL] Operation failed: $_" -Level ERROR
    if (-not $Force) { throw }
}
```

### 6. Logging Standards

Use these logging levels consistently:
- `Write-Log "Message" -Level INFO` - General information
- `Write-Log "Message" -Level SUCCESS` - Successful operations
- `Write-Log "Message" -Level WARNING` - Non-critical issues
- `Write-Log "Message" -Level ERROR` - Errors and failures

### 7. Testing Requirements

After adding new browsers:

1. **Syntax Validation:**
   ```powershell
   $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content .\mTTCleaner.ps1 -Raw), [ref]$null)
   ```

2. **Test Execution:**
   ```powershell
   .\mTTCleaner.ps1 -WhatIf -Automated -Browser NewBrowserName
   ```

3. **Verify Detection:**
   ```powershell
   .\mTTCleaner.ps1 -Automated -Browser NewBrowserName -Verbose
   ```

### 8. Documentation Updates

After adding browsers, update these files:
- `README.md` - Add new browsers to supported browser list
- `README.html` - Update HTML version with new browsers
- `CHANGELOG.md` - Document new browser additions
- `VERSION` - Increment minor version (e.g., 2.1.1 → 2.2.0)

---

## Code Quality Standards

### Naming Conventions
- Functions: `Verb-Noun` format (e.g., `Get-BrowserPath`, `Clear-BrowserCache`)
- Variables: `$PascalCase` for script-scope, `$camelCase` for local
- Browser Keys: `PascalCase` (e.g., `'Chrome'`, `'Firefox'`, `'OrionBrowser'`)

### Comment-Based Help
All new functions MUST include:
```powershell
<#
.SYNOPSIS
    Brief description
.DESCRIPTION
    Detailed description
.PARAMETER ParameterName
    Parameter description
.EXAMPLE
    Usage example
.NOTES
    Author: Kyle C. Rode
    Company: myTech.Today
    Version: 2.2.0
#>
```

### Performance Optimization
- Use `[System.Collections.Generic.List[object]]::new()` instead of `@()` for arrays
- Use `-Filter` parameter with `Get-ChildItem` when possible
- Avoid unnecessary recursion with `-Recurse`
- Use hash tables for lookups instead of arrays

---

## Integration Checklist

Before submitting changes:

- [ ] All new browsers added to `$script:BrowserDefinitions`
- [ ] Browser paths added to `Get-BrowserPath` function
- [ ] Browser names added to `$browserNames` hashtable
- [ ] Cross-platform paths verified for Windows/macOS/Linux
- [ ] ASCII characters used (no emoji)
- [ ] Error handling implemented with try-catch
- [ ] Logging uses proper levels (INFO, SUCCESS, WARNING, ERROR)
- [ ] Code follows myTech.Today naming conventions
- [ ] Comment-based help added to new functions
- [ ] Syntax validation passed
- [ ] Test execution successful with `-WhatIf`
- [ ] Documentation files updated (README.md, CHANGELOG.md, VERSION)
- [ ] No existing browser definitions modified
- [ ] Code integrates cleanly without breaking existing functionality

---

## Example Implementation

Here's an example of adding a new browser (Orion):

```powershell
# 1. Add to Get-BrowserPath function
'Orion' {
    if ($IsMacOS) {
        return "$env:HOME/Library/Application Support/Orion"
    }
}

# 2. Add to $browserNames hashtable (in Get-InstalledBrowsers)
'Orion' = @('Orion', 'Orion Browser')

# 3. Add to $script:BrowserDefinitions
'Orion' = @{
    Name = 'Orion Browser'
    ProcessNames = @('Orion')
    ProfileRoot = Get-BrowserPath -BrowserName 'Orion'
    CachePaths = @('Cache', 'Code Cache', 'GPUCache')
    DatabasePaths = @('History', 'Cookies', 'Web Data')
    MetricsPaths = @('*metrics*', '*telemetry*')
    Type = 'Chromium'
}
```

---

## Final Notes

- **Preserve existing code** - Only add new browser definitions
- **Test thoroughly** - Use `-WhatIf` before running actual cleanup
- **Follow patterns** - Match existing code style exactly
- **Document changes** - Update all relevant documentation files
- **Use ASCII only** - No emoji or special Unicode characters
- **myTech.Today branding** - Always lowercase m, capital T's, period between

For questions or clarification, refer to:
- `.augment/core-guidelines.md` - PowerShell development standards
- `mTTCleaner.ps1` - Current implementation patterns
- `README.md` - Project documentation
