You are Augment AI assisting with refactoring a PowerShell script in a repository that targets cross-platform execution using PowerShell 7+ (which runs natively on Windows, macOS, and Linux).

Your task is to fully refactor the script located at: `Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\mTTCleaner.ps1`

This script is currently a browser cache and database cleanup tool specifically designed for the "myTech.Today" environment. Your goal is to transform it into a robust, maintainable, cross-platform PowerShell module/script that provides equivalent functionality and a consistent user experience across Windows, macOS, and Linux.

### Key Requirements:

1. **Cross-Platform Compatibility**  
   Ensure the script runs seamlessly on:
   - Windows (via Windows PowerShell or PowerShell 7+)
   - macOS (via PowerShell 7+)
   - Linux (via PowerShell 7+)

   Use only PowerShell features and cmdlets available in PowerShell 7+ core (avoid Windows-specific modules like those relying on WMI or COM objects unless conditionally loaded on Windows only).

2. **Platform Auto-Detection**  
   Automatically detect the current operating system using `$IsWindows`, `$IsLinux`, and `$IsMacOS` automatic variables (available in PowerShell 7+).  
   Based on the detected platform, select and execute the appropriate cleanup paths and logic while providing a consistent interface and output to the user.

3. **Standardized Cross-Platform Paths**  
   Strictly adhere to the path conventions defined in the project's `.augment\core-guidelines.md` file.  
   Use appropriate environment variables and PowerShell providers to construct paths:
   - On **Windows**: Use `%LOCALAPPDATA%`, `%APPDATA%`, `%TEMP%`, etc. (accessed via `$env:LOCALAPPDATA`, etc.)
   - On **macOS**: Use `~/Library/Caches`, `~/Library/Application Support`, `~/Library/Preferences`
   - On **Linux**: Use `$env:XDG_CACHE_HOME` (fallback to `~/.cache`), `$env:XDG_CONFIG_HOME` (fallback to `~/.config`), `/tmp`

   Resolve all paths using `Join-Path` and expand user directories with `[System.Environment]::ExpandEnvironmentVariables()` or `Resolve-Path` where needed.

4. **Equivalent Feature Parity**  
   Implement the same set of cleanup operations (browser caches, temporary files, application databases, logs, etc. relevant to myTech.Today) on all three platforms.  
   If a direct equivalent does not exist on a platform (e.g., a Windows-specific browser profile location), implement the closest logical equivalent or clearly document and skip with a warning.

5. **Best Practices & Code Quality**  
   - Structure the script as a proper PowerShell module (`.psm1`) with exported functions, or as a well-organized script with functions, if preferred.
   - Use `cmdletbinding()` and proper parameter validation where functions accept input.
   - Implement comprehensive error handling with `Try/Catch` blocks and meaningful messages.
   - Add detailed comment-based help for all public functions.
   - Use `Write-Verbose`, `Write-Progress`, and `Write-Host` appropriately for user feedback.
   - Include safeguards: prompt for confirmation before deleting files (with a `-Force` switch to bypass), and support `-WhatIf`.
   - Calculate and report total space reclaimed.

6. **User Experience**  
   Provide a consistent command-line experience regardless of platform:
   - Same parameters and switches
   - Same output formatting (use `Format-Table`, `Write-Host` with consistent colors if possible)
   - Clear indication at startup of detected platform and which cleanup paths will be targeted

7. **Testing & Safety**  
   - Prefer removing items via `Remove-Item -WhatIf` in initial runs.
   - Log actions to a file in a cross-platform location (e.g., `$env:TEMP` or equivalent).
   - Include a dry-run mode that lists files/folders to be cleaned without deleting.

8. **Documentation**  
   Update or create a README section explaining cross-platform usage, prerequisites (PowerShell 7+), and any platform-specific notes.

Refactor the code to be clean, modular, readable, and maintainable. Prioritize simplicity and reliability while achieving full feature parity across Windows, macOS, and Linux.
