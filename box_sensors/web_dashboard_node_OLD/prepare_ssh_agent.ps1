# prepare_ssh_agent.ps1
$ErrorActionPreference = "Stop"

$keyPath = Join-Path $env:USERPROFILE ".ssh\id_ed25519"

Write-Host "==============================================="
Write-Host "  Preparing SSH Agent (Load Key Once)"
Write-Host "==============================================="

if (-not (Test-Path $keyPath)) {
  throw "SSH key not found: $keyPath"
}

# Ensure ssh-agent service is running
$svc = Get-Service ssh-agent -ErrorAction SilentlyContinue
if (-not $svc) {
  throw "ssh-agent service not found. Install OpenSSH Client on Windows."
}
if ($svc.Status -ne "Running") {
  Write-Host "Starting ssh-agent..."
  Start-Service ssh-agent
} else {
  Write-Host "ssh-agent is already running."
}

# Get fingerprint of our key
$fprLine = & ssh-keygen -lf $keyPath
if ($LASTEXITCODE -ne 0 -or -not $fprLine) {
  throw "Failed to read key fingerprint with ssh-keygen."
}
$fpr = ($fprLine -split "\s+")[1]   # e.g. SHA256:....

# Check if already loaded
$list = & ssh-add -l 2>$null
if ($LASTEXITCODE -eq 0 -and $list -match [regex]::Escape($fpr)) {
  Write-Host "Key already loaded in agent ($fpr)."
  exit 0
}

Write-Host "Adding key to agent (will ask passphrase once)..."
& ssh-add $keyPath

Write-Host "Loaded keys:"
& ssh-add -l
Write-Host "Done."