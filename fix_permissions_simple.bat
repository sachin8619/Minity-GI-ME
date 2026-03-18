@echo off
echo Fixing permissions for Minty-GI...
echo.

REM Set the current directory
cd /d "%~dp0"

REM Take ownership of the folder
takeown /f . /r /d y

REM Grant full permissions to current user
icacls . /grant "%USERNAME%:(OI)(CI)F" /t

REM Grant full permissions to Administrators  
icacls . /grant "Administrators:(OI)(CI)F" /t

echo.
echo Permissions fixed! Please run Minty-GI as Administrator.
pause
