@echo off
echo Fixing permissions for Minty-GI...
echo.

REM Take ownership of the folder
takeown /f "%~dp0" /r /d y

REM Grant full permissions to current user
icacls "%~dp0" /grant "%USERNAME%:(OI)(CI)F" /t

REM Grant full permissions to Administrators
icacls "%~dp0" /grant "Administrators:(OI)(CI)F" /t

echo.
echo Permissions fixed! Please run Minty-GI as Administrator.
pause
