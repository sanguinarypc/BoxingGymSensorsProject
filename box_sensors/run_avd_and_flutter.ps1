<# 
  run_avd_and_flutter.ps1
  ---------------------------------------------------------
  - Λίστα AVDs, επιλογή από μενού
  - Εκκίνηση emulator (ή σύνδεση σε ήδη ανοιχτό)
  - Αναμονή μέχρι να ολοκληρωθεί το boot
  - Λίστα flutter devices (JSON), επιλογή συσκευής
  - Επιλογή RUN MODE: 1) Debug  2) Profile  3) Release
  - flutter run [-d <deviceId>] με το αντίστοιχο mode
  ---------------------------------------------------------
  Τοποθέτησέ το στη ρίζα του Flutter project (εκεί που είναι το pubspec.yaml).
#>

[CmdletBinding()]
param(
  [switch]$JustLaunchAvd,   # Άνοιγμα μόνο AVD (χωρίς flutter run)
  [switch]$VerboseLog       # Αναλυτικά logs
)

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err ($msg) { Write-Host "[ERR ] $msg" -ForegroundColor Red }

function Ensure-BinariesInPath {
  $need = @("adb","emulator","flutter","sdkmanager")
  foreach ($n in $need) {
    $p = (Get-Command $n -ErrorAction SilentlyContinue)
    if (-not $p) {
      Write-Warn "Το '$n' δεν βρέθηκε στο PATH."
    } elseif ($VerboseLog) {
      Write-Info "$n => $($p.Source)"
    }
  }
}

function Get-AvdList {
  $avds = & emulator -list-avds 2>$null
  if (-not $avds) {
    Write-Err "Δεν βρέθηκαν AVDs. Φτιάξ’ τα από Android Studio → AVD Manager."
    exit 1
  }
  return $avds
}

function Choose-FromList([string]$title, [string[]]$items) {
  Write-Host ""
  Write-Host "=== $title ==="
  for ($i=0; $i -lt $items.Count; $i++) {
    Write-Host ("{0,2}) {1}" -f ($i+1), $items[$i])
  }
  do {
    $sel = Read-Host "Δώσε αριθμό 1..$($items.Count)"
  } until ([int]::TryParse($sel, [ref]$null) -and $sel -ge 1 -and $sel -le $items.Count)
  return $items[$sel-1]
}

function Get-EmulatorIds {
  $out = & adb devices 2>$null
  $emu = @()
  foreach ($line in $out) {
    if ($line -match "^emulator-(\d+)\s+device") { $emu += ($Matches[0] -split '\s+')[0] }
  }
  return $emu
}

function Wait-For-Prop($deviceId, $prop, $expected="1", [int]$timeoutSec=180) {
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while ($sw.Elapsed.TotalSeconds -lt $timeoutSec) {
    $val = (& adb -s $deviceId shell getprop $prop).Trim()
    if ($VerboseLog) { Write-Info "$deviceId getprop $prop => '$val'" }
    if ($val -eq $expected) { return $true }
    Start-Sleep -Seconds 2
  }
  return $false
}

function Start-Avd([string]$avdName) {
  $before = Get-EmulatorIds

  Write-Info "Εκκίνηση AVD '$avdName'..."
  Start-Process -FilePath "emulator" -ArgumentList @("-avd", $avdName) | Out-Null

  # Βρες νέο emulator id
  $emuId = $null
  $sw = [Diagnostics.Stopwatch]::StartNew()
  while ($sw.Elapsed.TotalSeconds -lt 60 -and -not $emuId) {
    Start-Sleep -Seconds 2
    $after = Get-EmulatorIds
    $emuId = ($after | Where-Object { $before -notcontains $_ }) | Select-Object -First 1
    if ($VerboseLog) { Write-Info "Αναζήτηση νέου emulator... found: $emuId" }
  }

  if (-not $emuId) {
    # Ίσως ήταν ήδη ανοιχτός
    $curr = Get-EmulatorIds
    if ($curr.Count -gt 0) {
      $emuId = $curr[0]
      Write-Warn "Δεν εντοπίστηκε νέος ID. Χρήση ήδη ανοιχτού: $emuId"
    } else {
      Write-Err "Απέτυχε η εκκίνηση του emulator."
      exit 1
    }
  }

  Write-Info "Περίμενε να γίνει ready: $emuId (adb wait-for-device)"
  & adb -s $emuId wait-for-device

  # Boot complete
  if (-not (Wait-For-Prop $emuId "sys.boot_completed" "1" 180)) {
    Write-Warn "Timeout στο sys.boot_completed. Συνεχίζουμε..."
  }
  if (-not (Wait-For-Prop $emuId "dev.bootcomplete" "1" 180)) {
    Write-Warn "Timeout στο dev.bootcomplete. Συνεχίζουμε..."
  }

  Write-Info "Emulator έτοιμος: $emuId"
  return $emuId
}

function Choose-FlutterDevice {
  # Χρησιμοποιούμε JSON για αξιόπιστο parsing
  $json = & flutter devices --machine 2>$null
  if (-not $json -or $json.Trim().Length -eq 0) {
    Write-Err "Το 'flutter devices --machine' δεν επέστρεψε τίποτα."
    exit 1
  }
  try {
    $list = $json | ConvertFrom-Json
  } catch {
    Write-Err "Απέτυχε το JSON parsing του 'flutter devices --machine'."
    Write-Host $json
    exit 1
  }

  $ids = @()
  foreach ($d in $list) {
    if ($null -ne $d.id -and $d.id.ToString().Trim().Length -gt 0) {
      $ids += ("{0}  —  {1}" -f $d.id, $d.name)
    }
  }

  if ($ids.Count -eq 0) {
    Write-Err "Δεν βρέθηκαν διαθέσιμες συσκευές για Flutter."
    exit 1
  }

  $chosen = Choose-FromList "Διάλεξε συσκευή για flutter run" $ids
  $deviceId = $chosen.Split("—")[0].Trim()
  return $deviceId
}

function Choose-RunMode {
  $modes = @("Debug","Profile","Release")
  $choice = Choose-FromList "Διάλεξε RUN MODE" $modes
  switch ($choice) {
    "Debug"   { return "debug" }
    "Profile" { return "profile" }
    "Release" { return "release" }
    default   { return "debug" }
  }
}

function Run-FlutterOnDevice([string]$deviceId, [string]$mode) {
  $args = @("run","-d",$deviceId)
  switch ($mode) {
    'release' { $args = @("run","--release","-d",$deviceId) }
    'profile' { $args = @("run","--profile","-d",$deviceId) }
    default   { $args = @("run","-d",$deviceId) }  # debug
  }
  Write-Info ("Τρέχω 'flutter {0}'..." -f ($args -join ' '))
  & flutter @args
}

# ----------------- main flow -----------------

if ($PSScriptRoot) { Set-Location $PSScriptRoot }
Ensure-BinariesInPath

# 1) Διάλεξε AVD
$avds = Get-AvdList
$avd = Choose-FromList "Διάλεξε AVD για εκκίνηση" $avds

# 2) Άνοιξε (ή σύνδεση σε) emulator & περίμενε boot
$emuId = Start-Avd $avd

if ($JustLaunchAvd) {
  Write-Info "Ζητήθηκε μόνο εκκίνηση AVD. Τέλος."
  exit 0
}

# 3) Λίστα flutter devices (JSON) και επιλογή στόχου (emulator ή φυσική)
$device = Choose-FlutterDevice

# 4) Επιλογή mode 1/2/3 και run
$mode = Choose-RunMode
Run-FlutterOnDevice $device $mode
