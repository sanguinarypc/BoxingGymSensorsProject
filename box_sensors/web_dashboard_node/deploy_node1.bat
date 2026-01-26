@echo off
setlocal

echo ===============================================
echo   Deploying Node.js Dashboard (Deployer User)
echo ===============================================

set "SERVER_IP=46.224.82.152"
set "SERVER_USER=deployer"
set "REMOTE_PATH=/opt/dashboard_staging"
set "LOCAL_PATH=%~dp0"
set "KEY=%USERPROFILE%\.ssh\id_ed25519"

cd /d "%LOCAL_PATH%" || (echo ERROR: Cannot cd to LOCAL_PATH & exit /b 1)

echo [1/6] Compressing files to dashboard.tgz...
if exist "dashboard.tgz" del /q "dashboard.tgz"

if exist package-lock.json (
  tar -czf dashboard.tgz public server.js package.json package-lock.json
) else (
  tar -czf dashboard.tgz public server.js package.json
)
if errorlevel 1 (echo ERROR: tar failed & exit /b 1)

echo.
echo [2/6] Uploading dashboard.tgz to %SERVER_USER%@%SERVER_IP%:%REMOTE_PATH%/ ...
scp -i "%KEY%" -o IdentitiesOnly=yes dashboard.tgz %SERVER_USER%@%SERVER_IP%:%REMOTE_PATH%/ || (echo ERROR: scp failed & exit /b 1)

echo.
echo [3/6] Extracting on server (as deployer)...
ssh -i "%KEY%" -o IdentitiesOnly=yes %SERVER_USER%@%SERVER_IP% "bash -lc 'set -e;
  cd %REMOTE_PATH%;
  rm -rf public server.js package.json package-lock.json node_modules 2>/dev/null || true;
  tar -xzf dashboard.tgz;
  rm -f dashboard.tgz;
  echo Files Extracted;
  if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi;
  sudo -n /usr/local/sbin/dashboard-deploy-finalize;
  sudo -n systemctl status dashboard --no-pager -l | head -n 25
'" || (echo ERROR: remote update failed & exit /b 1)

echo.
echo [4/6] Cleaning up local archive...
del /q dashboard.tgz

echo.
echo ===============================================
echo   DEPLOYMENT SUCCESSFUL!
echo ===============================================
pause