@echo off
REM ============================================================================
REM  myTech.Today - mTTCleaner Setup
REM  Checks for PowerShell 7+, installs if needed, then runs the script
REM  Falls back to PowerShell 5.1 if PS7 install fails
REM ============================================================================
setlocal enabledelayedexpansion

echo.
echo ============================================================
echo   myTech.Today - mTTCleaner Setup
echo ============================================================
echo.

REM Check if PowerShell 7+ is installed (PATH first, then common locations)
call :FIND_PWSH
if defined PWSH_EXE (
    echo [OK] PowerShell 7+ found: %PWSH_EXE%
    goto :RUN_INSTALLER
)

echo [INFO] PowerShell 7+ not found. Attempting to install...
echo.

REM Check for admin privileges (needed for any install method)
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] Not running as administrator. Requesting elevation...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

REM Try winget first
where winget >nul 2>&1
if %ERRORLEVEL% NEQ 0 goto :TRY_MSI

echo [INFO] Installing PowerShell 7 using winget...
winget install --id Microsoft.PowerShell --source winget --accept-package-agreements --accept-source-agreements 2>nul
call :FIND_PWSH
if defined PWSH_EXE (
    echo [OK] PowerShell 7 installed via winget: %PWSH_EXE%
    goto :RUN_INSTALLER
)
echo [WARN] winget install did not succeed. Trying direct MSI download...

:TRY_MSI
echo [INFO] Downloading PowerShell 7 MSI installer...
set "PS7_MSI=%TEMP%\PowerShell-7-win-x64.msi"
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $r=(Invoke-RestMethod -Uri 'https://api.github.com/repos/PowerShell/PowerShell/releases/latest'); $a=$r.assets|Where-Object{$_.name -like '*win-x64.msi'}|Select-Object -First 1; if($a){Write-Host('[INFO] Downloading '+$a.name+'...');Invoke-WebRequest -Uri $a.browser_download_url -OutFile '%PS7_MSI%' -UseBasicParsing}else{exit 1}"

if not exist "%PS7_MSI%" (
    echo [WARN] MSI download failed.
    goto :FALLBACK_PS51
)

echo [INFO] Installing PowerShell 7 MSI (silent)...
msiexec /i "%PS7_MSI%" /qn ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ADD_FILE_CONTEXT_MENU_RUNPOWERSHELL=1 ENABLE_PSREMOTING=0 REGISTER_MANIFEST=1 USE_MU=0 ENABLE_MU=0
del /f /q "%PS7_MSI%" 2>nul

REM Re-check after MSI install
call :FIND_PWSH
if defined PWSH_EXE (
    echo [OK] PowerShell 7 installed via MSI: %PWSH_EXE%
    goto :RUN_INSTALLER
)

:FALLBACK_PS51
echo.
echo [WARN] Could not install PowerShell 7. Falling back to PowerShell 5.1...
echo        (Parallel processing will be disabled)
echo.
set "PWSH_EXE=powershell"

:RUN_INSTALLER
echo.
echo [INFO] Running mTTCleaner...
echo.

"%PWSH_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0mTTCleaner.ps1" %*

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [WARN] mTTCleaner exited with code: %ERRORLEVEL%
)

echo.
echo [INFO] Complete.
pause
exit /b 0

REM ---- Subroutine: locate pwsh.exe via PATH or common install dirs ----
:FIND_PWSH
set "PWSH_EXE="
where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set "PWSH_EXE=pwsh"
    goto :EOF
)
REM Check common install locations
for %%D in (
    "%ProgramFiles%\PowerShell\7\pwsh.exe"
    "%ProgramFiles(x86)%\PowerShell\7\pwsh.exe"
    "%LocalAppData%\Microsoft\PowerShell\pwsh.exe"
    "%ProgramW6432%\PowerShell\7\pwsh.exe"
) do (
    if exist %%D (
        set "PWSH_EXE=%%~D"
        goto :EOF
    )
)
goto :EOF
