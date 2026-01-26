@echo off
setlocal enabledelayedexpansion

echo ===============================================
echo   Deploying Node.js Dashboard (Deployer + Staging)
echo ===============================================

set "SERVER_IP=46.224.82.152"
set "SERVER_USER=deployer"
set "REMOTE_PATH=/opt/dashboard_staging"
set "LOCAL_PATH=%~dp0"
set "KEY=%USERPROFILE%\.ssh\id_ed25519"
set "PUBLIC_HEALTH_URL=https://boxing-dashboard.ndimitrakarakos.gr/health"

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
scp -i "%KEY%" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new dashboard.tgz %SERVER_USER%@%SERVER_IP%:%REMOTE_PATH%/ || (echo ERROR: scp failed & exit /b 1)

echo.
echo [3/6] Running server-side deploy script...
ssh -i "%KEY%" -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new %SERVER_USER%@%SERVER_IP% "/usr/local/bin/dashboard-deploy-run" || (echo ERROR: remote deploy failed & exit /b 1)

echo.
echo [4/6] External (Cloudflare) health check: %PUBLIC_HEALTH_URL%
for /l %%i in (1,1,15) do (
  for /f "delims=" %%c in ('curl -s -o NUL -w "%%{http_code}" "%PUBLIC_HEALTH_URL%" 2^>NUL') do set "CODE=%%c"
  set "CODE=!CODE: =!"
  if "!CODE!"=="200" (
    echo External health OK (HTTP !CODE!)
    goto :external_ok
  )
  if "!CODE!"=="204" (
    echo External health OK (HTTP !CODE!)
    goto :external_ok
  )
  echo External health failed (HTTP !CODE!) attempt %%i
  timeout /t 1 >nul
)
echo ERROR: External health check FAILED
exit /b 1

:external_ok
echo.
echo [5/6] Cleaning up local archive...
del /q dashboard.tgz

echo.
echo [6/6] DONE.
echo ===============================================
echo   DEPLOYMENT SUCCESSFUL!
echo ===============================================
echo.
echo All checks passed. (Local + External)
pause