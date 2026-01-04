You are an expert PowerShell developer tasked with refactoring the existing script located at 'Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\mTTCleaner.ps1' into a high-quality, cross-platform PowerShell module/script that functions reliably on Windows, macOS, and Linux (using PowerShell 7+).

The primary goal is to create a fast, efficient, user-friendly tool for cleaning browser caches and compressing/optimizing browser SQLite databases (e.g., via VACUUM for Firefox-based browsers and safe cache deletion/rebuilding for Chromium-based browsers) only on browsers that are actually installed on the system.

Key requirements:

1. **Cross-Platform Compatibility**:
   - The script must detect the current OS ($IsWindows, $IsMacOS, $IsLinux) and adapt paths, detection methods, shortcut creation, and logging accordingly.
   - Ensure all operations are safe and tested across Windows, macOS, and Linux.

2. **Browser Detection**:
   - Dynamically detect which of the following browsers are installed before performing any cleaning:
     - Safari (macOS only)
     - Google Chrome
     - Chromium
     - Microsoft Edge (Chromium-based)
     - Mozilla Firefox
     - Opera
     - Brave
     - Vivaldi
     - Tor Browser
     - DuckDuckGo Browser
     - Waterfox
     - LibreWolf
     - Pale Moon
     - SRWare Iron
     - Other notable ones if feasible: Maxthon, SeaMonkey, Slimjet, Falkon, Midori
   - Use reliable methods:
     - On Windows: Registry queries (HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall, HKLM\Software\Wow6432Node, user profiles), executable paths in Program Files, common install locations.
     - On macOS: Check /Applications/*.app, ~/Applications, or use 'mdfind'/'mdls' if needed.
     - On Linux: Check common binaries (which chrome, which firefox, etc.), flatpak/snap/appimage locations, ~/.local/share, /usr/bin, /opt.
   - For portable installs, attempt to locate common profile directories.
   - Present a clear list of detected browsers to the user.

3. **Cache Cleaning and Database Optimization**:
   - Only process detected browsers.
   - Safely clear cache folders (e.g., Cache, Code Cache, GPUCache for Chromium-based).
   - For SQLite databases (places.sqlite, cookies.sqlite, etc. in Firefox-based; favicons.sqlite, History, Web Data in Chromium-based):
     - Close browser processes if running (prompt user or force with warning).
     - Perform VACUUM on Firefox/Gecko-based databases to defragment and reduce size.
     - For Chromium/Blink-based, delete safe cache files and let the browser rebuild; optionally vacuum compatible SQLite files if safe.
   - Optimize for speed: Use parallel processing where possible (ForEach-Object -Parallel in PWSH 7+), avoid unnecessary I/O, batch operations.
   - Handle multiple user profiles per browser gracefully.

4. **Deployment and Installation**:
   - The script should self-copy itself and any required supporting files/folders to platform-appropriate locations, following the rules and configurations specified in the '.augment/' folder (respect per-platform guidelines exactly).
   - Create shortcuts:
     - Windows: All Users Desktop shortcut; Start Menu shortcut in a "myTech.Today" folder.
     - macOS: Desktop shortcut (alias/.app link) for current user; optional Dock or Applications folder placement per best practices.
     - Linux: Desktop shortcut (.desktop file) on user desktop; optional menu entry via .desktop in ~/.local/share/applications.
   - Ensure shortcuts point correctly to 'pwsh -File' on non-Windows for cross-platform execution.

5. **Logging**:
   - On Windows: Use the provided Logging.ps1 module (download from https://raw.githubusercontent.com/mytech-today-now/scripts/refs/heads/main/logging.ps1 if needed) to write structured events to the Windows Event Log under the "myTech.Today" source/log.
   - On macOS and Linux: Fall back to writing detailed logs to a cross-platform location (e.g., ~/myTech.Today/Logs/mTTCleaner.log or /var/log/myTech.Today if elevated), using consistent formatted output.
   - Log all major actions, detected browsers, successes, errors, and performance metrics.

6. **Task Scheduling (if applicable)**:
   - If the script creates scheduled tasks:
     - Windows: Place in Task Scheduler under "myTech.Today" folder.
     - macOS/Linux: Use launchd plist or cron entries in appropriate user/system locations.

7. **User Interface**:
   - Implement a modern, attractive Text-based User Interface (TUI) using a suitable cross-platform library.
   - Preferred options (choose the best fit for beauty and ease):
     - PwshSpectreConsole (Spectre.Console wrapper) for colorful, structured menus, progress bars, tables, selections.
     - Or Microsoft.PowerShell.ConsoleGuiTools / Terminal.Gui for full interactive windows, dialogs, checkboxes.
   - The TUI should:
     - Display a welcome banner with script version and platform.
     - Show detected browsers in a selectable checklist.
     - Provide options for full clean, cache only, database vacuum only.
     - Show live progress bars during operations.
     - Confirm destructive actions with dialogs.
     - Display summary results (space saved, time taken) at the end.
     - Support keyboard navigation and be responsive.

8. **Performance and Best Practices**:
   - Optimize the entire script for maximum speed: Minimize disk reads, use efficient queries, cache detections.
   - Implement robust error handling (try/catch), verbose/debug output options.
   - Use modern PowerShell features (classes if needed, validated parameters, module structure).
   - Ensure the final product is easy to maintain, well-commented, and follows PowerShell best practices (approved verbs, help-based structure).
   - Make it intuitive and polished for end-users—no rough edges.

Refactor thoroughly for clarity, modularity (separate functions for detection, cleaning per browser type, UI, deployment), and reliability. Prioritize user experience: make this the best, most professional browser maintenance tool possible in PowerShell.
