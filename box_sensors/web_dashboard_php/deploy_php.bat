@echo off
setlocal

echo ===============================================
echo   Deploying PHP Dashboard (Full Package)
echo ===============================================

set "SERVER_IP=46.224.82.152"
set "SERVER_USER=root"
set "REMOTE_PATH=/opt/dashboard_php"
set "LOCAL_PATH=%~dp0"
set "KEY=%USERPROFILE%\.ssh\id_ed25519"

cd /d "%LOCAL_PATH%" || (echo ERROR: Cannot cd to LOCAL_PATH & exit /b 1)

echo [1/5] Compressing files to dashboard.tgz...
if exist "dashboard.tgz" del /q "dashboard.tgz"

:: Zip the PHP files and HTML
tar -czf dashboard.tgz receiver.php list_history.php health.php index.html

if errorlevel 1 (echo ERROR: tar failed & exit /b 1)

echo.
echo [2/5] Uploading dashboard.tgz to %SERVER_IP%...
:: Create directory if not exists
ssh -i "%KEY%" -o IdentitiesOnly=yes %SERVER_USER%@%SERVER_IP% "mkdir -p %REMOTE_PATH%"
scp -i "%KEY%" -o IdentitiesOnly=yes dashboard.tgz %SERVER_USER%@%SERVER_IP%:%REMOTE_PATH%/ || (echo ERROR: scp failed & exit /b 1)

echo.
echo [3/5] Extracting on Server...
:: Extract and clean up. No npm install needed for PHP.
ssh -i "%KEY%" -o IdentitiesOnly=yes %SERVER_USER%@%SERVER_IP% "bash -lc 'set -e; cd %REMOTE_PATH%; ts=$(date +%%Y%%m%%d_%%H%%M%%S); mkdir -p backups; [ -f receiver.php ] && cp -a receiver.php backups/receiver.php.$ts || true; tar -xzf dashboard.tgz; rm -f dashboard.tgz; echo Files Extracted; echo PHP files updated.'" || (echo ERROR: remote update failed & exit /b 1)

echo.
echo [4/5] Cleaning up local archive...
del /q dashboard.tgz

echo.
echo [5/5] DONE.
echo ===============================================
echo   DEPLOYMENT SUCCESSFUL!
echo ===============================================
pause
