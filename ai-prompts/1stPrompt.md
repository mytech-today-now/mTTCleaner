generate a new augment AI prompt 'Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\ai-prompts\AuggiePrompt.md' that will generate the following Powershell 5.1 script and files. The script will follow the myTech.Today standards for PowerShell scripts located in the .augment directory.

Script: Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\mTTCleaner.ps1
Readme: Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\README.md
Readme: Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\README.html
.gitignore: Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\.gitignore
VERSION: Q:\_kyle\temp_documents\GitHub\PowerShellScripts\mTTCleaner\VERSION

This script will:

When the script is run, it will prompt the user to confirm that they want to run the script.  The user must type 'Yes' to confirm.  The user must also be running the script as an administrator.  If the user is not running the script as an administrator, the script will exit.

when it runs, it will copy itself to '%USERPROFILE%\myTech.Today\mTTCleaner\mTTCleaner.ps1' and it will copy the README.md file to '%USERPROFILE%\myTech.Today\mTTCleaner\README.md' and the README.html file to '%USERPROFILE%\myTech.Today\mTTCleaner\README.html', then run the script from there.

Use the logging module located at 'https://raw.githubusercontent.com/mytech-today-now/scripts/refs/heads/main/logging.ps1'
The local path for the log is '%USERPROFILE%\mytech.today\logs\mTTCleaner.md'

The script will force close the affected browsers before it starts the cleanup process.

1. **Delete the cache for all browsers** - This includes Chrome, Edge, Firefox, and Brave, and all browsers listed in 'Q:\_kyle\temp_documents\GitHub\PowerShellScripts\app_installer\install-gui.ps1' and 'Q:\_kyle\temp_documents\GitHub\PowerShellScripts\app_installer\install.ps1'.  The cache for each browser will be deleted.
2. **Compact the database for all browsers** - This includes Chrome, Edge, Firefox, and Brave, and all browsers listed in 'Q:\_kyle\temp_documents\GitHub\PowerShellScripts\app_installer\install-gui.ps1' and 'Q:\_kyle\temp_documents\GitHub\PowerShellScripts\app_installer\install.ps1'.  The database for each browser will be compacted.
3. **Delete the metrics temp files for all browsers** - This includes Chrome, Edge, Firefox, and Brave, and all browsers listed in 'Q:\_kyle\temp_documents\GitHub\PowerShellScripts\app_installer\install-gui.ps1' and 'Q:\_kyle\temp_documents\GitHub\PowerShellScripts\app_installer\install.ps1'.  The metrics temp files for each browser will be deleted.

4. Generate a shortcut on the Desktop and in the Programs Menu that points to the script.  The script will be run as an administrator.  The windows program settings regarding the shortcut are:
    - Name: mTTCleaner
    - Description: myTech.Today - mTTCleaner
    - Icon: 'https://raw.githubusercontent.com/mytech-today-now/scripts/refs/heads/main/mytech.ico'
    - it will run as an administrator
    - it will be on the taskbar when run
    - it will have a start in of '%USERPROFILE%\myTech.Today\mTTCleaner\'
    - it will have a target of 'powershell.exe -ExecutionPolicy Bypass -File "%USERPROFILE%\myTech.Today\mTTCleaner\mTTCleaner.ps1"'
    - it will have a working directory of '%USERPROFILE%\myTech.Today\mTTCleaner\'
    - it will have a hotkey of 'Ctrl+Shift+M'
    - it will have a category of 'myTech.Today'
    - it will have a comment of 'myTech.Today - mTTCleaner'
    - it will have a window style of 'Normal'
    - it will have a run as of '%USERPROFILE%\myTech.Today\mTTCleaner\mTTCleaner.ps1'

5.  The script will be signed with a code signing certificate.
6.  The script will be tested on Windows 10, 11.
7.  The script will be tested for errors and bugs.
8.  The script will be tested for performance.
9.  The script will be run as a scheduled Task in Windows Task Scheduler to run every 30 days, on the 15th of the month at 1:00 PM.  The Task will be called 'mTTCleaner' and it will be located in the 'myTech.Today' folder in Task Scheduler.  The task will run as the currently logged in user.
