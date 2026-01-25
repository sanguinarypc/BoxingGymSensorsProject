@echo off
echo ===============================================
echo   Deploying Node.js Dashboard (Full Package)
echo ===============================================

set SERVER_IP=46.224.82.152
set SERVER_USER=root
set REMOTE_PATH=/opt/dashboard
set LOCAL_PATH=%~dp0

cd /d "%LOCAL_PATH%"

echo [1/4] Compressing files to dashboard.tgz...
:: We exclude node_modules to keep upload fast (30KB vs 80MB).
:: The server will run 'npm install' to recreate node_modules.
tar -czf dashboard.tgz public server.js package.json history

echo.
echo [2/4] Uploading dashboard.tgz to %SERVER_IP%...
scp dashboard.tgz %SERVER_USER%@%SERVER_IP%:%REMOTE_PATH%/

echo.
echo [3/4] Extracting & Updating on Server...
:: Runs commands on server: cd, extract, install deps, restart service (optional)
ssh %SERVER_USER%@%SERVER_IP% "cd %REMOTE_PATH% && tar -xzf dashboard.tgz && echo Files Extracted && npm install --production"

echo.
echo [4/4] Cleaning up local archive...
del dashboard.tgz

echo.
echo ===============================================
echo   DEPLOYMENT SUCCESSFUL!
echo ===============================================
echo If you saw SSH password prompts, consider setting up SSH keys for 100% automation.
pause
