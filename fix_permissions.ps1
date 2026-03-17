Write-Host "Fixing permissions for Minty-GI..." -ForegroundColor Green
Write-Host ""

# Get current directory
$currentDir = Get-Location

# Take ownership of the folder
Write-Host "Taking ownership..." -ForegroundColor Yellow
takeown /f $currentDir /r /d y

# Grant full permissions to current user
Write-Host "Granting permissions to current user..." -ForegroundColor Yellow
icacls $currentDir /grant "$($env:USERNAME):(OI)(CI)F" /t

# Grant full permissions to Administrators
Write-Host "Granting permissions to Administrators..." -ForegroundColor Yellow
icacls $currentDir /grant "Administrators:(OI)(CI)F" /t

Write-Host ""
Write-Host "Permissions fixed! Please run Minty-GI as Administrator." -ForegroundColor Green
Read-Host "Press Enter to continue"
