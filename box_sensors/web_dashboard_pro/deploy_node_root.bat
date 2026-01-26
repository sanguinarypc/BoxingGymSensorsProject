@echo off
setlocal

echo ===============================================
echo   Deploying Node.js Dashboard (Full Package)
echo ===============================================

set "SERVER_IP=46.224.82.152"
set "SERVER_USER=root"
set "REMOTE_PATH=/opt/dashboard"
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
echo [2/6] Uploading dashboard.tgz to %SERVER_IP%...
scp -i "%KEY%" -o IdentitiesOnly=yes dashboard.tgz %SERVER_USER%@%SERVER_IP%:%REMOTE_PATH%/ || (echo ERROR: scp failed & exit /b 1)

echo.
echo [3/6] Extracting ^& Updating on Server (permissions + ownership + restart)...
ssh -i "%KEY%" -o IdentitiesOnly=yes %SERVER_USER%@%SERVER_IP% "bash -lc 'set -e;
  cd %REMOTE_PATH%;

  ts=$(date +%%Y%%m%%d_%%H%%M%%S);
  mkdir -p backups;
  [ -f server.js ] && cp -a server.js backups/server.js.$ts || true;
  [ -f package.json ] && cp -a package.json backups/package.json.$ts || true;

  tar -xzf dashboard.tgz;
  rm -f dashboard.tgz;
  echo Files Extracted;

  # Install deps (root creates node_modules; service only needs read)
  if [ -f package-lock.json ]; then
    npm ci --omit=dev;
  else
    npm install --omit=dev;
  fi;

  # --- DEPLOY FINALIZE (IMPORTANT) ---
  # 1) Lock code as root, preserve exec bits (X keeps execute on dirs + already-exec files)
  chown -R root:root /opt/dashboard;
  chmod -R u=rwX,go=rX /opt/dashboard;
  [ -f /opt/dashboard/nohup.out ] && chmod 600 /opt/dashboard/nohup.out || true;

  # 2) Ensure data dir writable by dashboard user
  chown -R dashboard:dashboard /opt/data;
  find /opt/data -type d -exec chmod 750 {} \;;
  find /opt/data -type f -exec chmod 640 {} \;;

  # 3) Restart and reset failed (clean state)
  systemctl reset-failed dashboard || true;
  systemctl restart dashboard;
  sleep 1;
  echo Restarted dashboard.service;

  # Health check (local)
  ok=0;
  for i in $(seq 1 12); do
    code=$(curl -s -o /dev/null -w \"%%{http_code}\" http://127.0.0.1:3000/health || true);
    if [ \"$code\" -ge 200 ] && [ \"$code\" -lt 400 ]; then
      ok=1;
      echo \"Health check OK (HTTP $code)\";
      break;
    fi;
    echo \"Health check failed (HTTP $code) attempt $i\";
    sleep 1;
  done;

  if [ \"$ok\" -ne 1 ]; then
    echo \"HEALTH CHECK FAILED\";
    systemctl --no-pager -l status dashboard | head -n 80;
    exit 1;
  fi;

  # Quick confirmation: runs as dashboard user
  pid=$(systemctl show -p MainPID --value dashboard);
  echo \"MainPID=$pid\";
  if [ \"$pid\" -gt 0 ]; then ps -o user,pid,cmd -p \"$pid\"; fi;

  systemctl --no-pager -l status dashboard | head -n 30
'" || (echo ERROR: remote update failed & exit /b 1)

echo.
echo [4/6] Cleaning up local archive...
del /q dashboard.tgz

echo.
echo [5/6] DONE.
echo ===============================================
echo   DEPLOYMENT SUCCESSFUL!
echo ===============================================
pause