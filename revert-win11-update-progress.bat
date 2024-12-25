@echo off
setlocal EnableDelayedExpansion
mode con:cols=100 lines=50
cls
set ver=1.0.5
set name=Revert Win11 Update Progress
set author=Ali BEYAZ - Enhanced by PatrickJr
set title=%name% v%ver% by %author%
title %title%
color 0a

set updatefolder="%SYSTEMDRIVE%\Windows\SoftwareDistribution\Download"
set max_retries=5
set retry_delay=5
set retry_count=0
set logfile=update_revert_log.txt

:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.==========================================
    echo. ERROR: This script must be run as an administrator.
    echo. Please restart the script with admin rights.
    echo.==========================================
    pause
    exit /b
)

:: Clear previous log
if exist %logfile% del /q %logfile%

echo.==========================================
echo. Welcome to %title%
echo. This tool will help revert Windows Update progress.
echo. Logs will be saved to: %logfile%
echo.==========================================
echo.

:: Ask for confirmation
set /p confirm=Type 'Y' to proceed with deletion, or any other key to cancel: 
if /i not "!confirm!"=="Y" (
    echo. Operation canceled by the user.
    pause
    exit /b
)

goto checkservice

:checkservice
:: Check if the Windows Update service is already stopped
sc query wuauserv | findstr /i "STATE" | findstr /i "STOPPED" >nul 2>&1
if %errorlevel% equ 0 (
    echo.- The Windows Update service is already stopped.
    goto delete
)

goto stopservice

:stopservice
echo.- Stopping Windows Update service...
:retry_stopservice
net stop wuauserv >> %logfile% 2>&1
if %errorlevel% neq 0 (
    set /a retry_count+=1
    echo.  Failed to stop the service. Retrying... (!retry_count!/!max_retries!)
    if !retry_count! lss %max_retries% (
        timeout /t %retry_delay% /nobreak >nul
        goto retry_stopservice
    ) else (
        echo.  ERROR: Failed to stop the service after !max_retries! attempts. See %logfile% for details.
        pause
        exit /b
    )
)
echo.  Service stopped successfully.

:delete
echo.- Deleting update files from %updatefolder%...
if exist %updatefolder% (
    rmdir /s /q %updatefolder% >> %logfile% 2>&1
    if %errorlevel% neq 0 (
        echo.  ERROR: Failed to delete update files. Check permissions or folder lock.
        echo.  See %logfile% for details.
        pause
        exit /b
    )
    echo.  Update files deleted successfully.
) else (
    echo.  No update files found to delete.
)

:startservice
echo.- Restarting Windows Update service...
net start wuauserv >> %logfile% 2>&1
if %errorlevel% neq 0 (
    echo.  ERROR: Failed to start the service. Ensure Windows Update is enabled.
    echo.  See %logfile% for details.
    pause
    exit /b
)
echo.  Service restarted successfully.

:exit
echo.==========================================
echo. Operation completed successfully!
echo. Logs can be found in: %logfile%
echo.==========================================
pause
exit
