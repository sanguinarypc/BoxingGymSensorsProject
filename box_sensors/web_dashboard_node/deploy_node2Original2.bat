@echo off
echo ===========================================
echo   Deploying Node.js Dashboard to Server
echo ===========================================

cd /d "%~dp0"

echo Uploading public/index.html...
scp public\index.html root@46.224.82.152:/opt/dashboard/public/

echo.
echo Uploading server.js (if changed)...
scp server.js root@46.224.82.152:/opt/dashboard/

echo.
echo ===========================================
echo   Deployment Complete!
echo ===========================================
pause
