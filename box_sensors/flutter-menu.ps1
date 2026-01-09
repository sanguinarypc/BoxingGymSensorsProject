param(
  [string]$ProjectPath = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ✅ FIX (StrictMode): πρέπει να υπάρχει, αλλιώς "cannot be retrieved because it has not been set"
$script:LastDeviceId = ""

# App package name (Android applicationId) - used by uninstall/check info
$script:AndroidPackageName = "com.sanguinarypc.box_sensors"

function Write-Header($text) {
  Write-Host ""
  Write-Host "============================================================"
  Write-Host $text
  Write-Host "============================================================"
}

function Confirm-ProjectPath {
  if (-not (Test-Path -LiteralPath $ProjectPath)) {
    throw "ProjectPath δεν υπάρχει: $ProjectPath"
  }
  Set-Location -LiteralPath $ProjectPath

  if (-not (Test-Path -LiteralPath (Join-Path $ProjectPath "pubspec.yaml"))) {
    throw "Δεν βρήκα pubspec.yaml στο: $ProjectPath`nΔώσε σωστό path στο Flutter project root."
  }
}

function Get-SentryDsn([switch]$ForcePrompt) {
  $dsn = $env:SENTRY_DSN

  if ($ForcePrompt -or [string]::IsNullOrWhiteSpace($dsn)) {
    Write-Host ""
    Write-Host "Δώσε SENTRY_DSN (π.χ. https://...@o123.ingest.sentry.io/456 )"
    $dsn = Read-Host "SENTRY_DSN"
    $dsn = $dsn.Trim()
    if ([string]::IsNullOrWhiteSpace($dsn)) { return "" }

    # μόνο για το τρέχον PowerShell session
    $env:SENTRY_DSN = $dsn
  }

  return $dsn.Trim()
}

function Set-SentryDsnPersisted {
  $dsn = Get-SentryDsn -ForcePrompt
  if ([string]::IsNullOrWhiteSpace($dsn)) {
    Write-Host "❌ Δεν δόθηκε DSN. Ακυρώθηκε."
    return
  }

  Write-Host ""
  Write-Host "Θες να το αποθηκεύσω μόνιμα (User Environment Variable);"
  Write-Host "1) Ναι (μόνιμα για τον χρήστη)"
  Write-Host "2) Όχι (μόνο για αυτό το PowerShell παράθυρο)"
  $ans = Read-Host "Επιλογή (1/2)"

  if ($ans -eq "1") {
    [Environment]::SetEnvironmentVariable("SENTRY_DSN", $dsn, "User")
    Write-Host "✅ Αποθηκεύτηκε μόνιμα ως User env var: SENTRY_DSN"
    Write-Host "ℹ️ Σημείωση: Ίσως χρειαστεί νέο PowerShell window για να το δει παντού."
  } else {
    Write-Host "✅ ΟΚ, έμεινε μόνο στο τρέχον session."
  }
}

# ---------------------------
# Outputs helpers
# ---------------------------

function Get-OutputPaths {
  $aabPath = Join-Path $ProjectPath "build\app\outputs\bundle\release\app-release.aab"
  $apkPath = Join-Path $ProjectPath "build\app\outputs\flutter-apk\app-release.apk"
  $aabDir  = Split-Path -Parent $aabPath
  $apkDir  = Split-Path -Parent $apkPath
  $outputsRoot = Join-Path $ProjectPath "build\app\outputs"

  return [pscustomobject]@{
    AabPath = $aabPath
    ApkPath = $apkPath
    AabDir  = $aabDir
    ApkDir  = $apkDir
    OutputsRoot = $outputsRoot
  }
}

function Show-OutputPaths {
  $p = Get-OutputPaths

  Write-Header "Build Outputs"
  Write-Host "AAB  : $($p.AabPath)"
  Write-Host "     Exists: $(Test-Path -LiteralPath $p.AabPath)"
  Write-Host ""
  Write-Host "APK  : $($p.ApkPath)"
  Write-Host "     Exists: $(Test-Path -LiteralPath $p.ApkPath)"
  Write-Host ""
  Write-Host "AAB folder: $($p.AabDir)"
  Write-Host "APK folder: $($p.ApkDir)"
  Write-Host "Outputs root: $($p.OutputsRoot)"
}

function Open-FolderIfExists([string]$folder) {
  if (Test-Path -LiteralPath $folder) {
    Start-Process explorer.exe $folder
  } else {
    Write-Host "❌ Δεν υπάρχει φάκελος: $folder"
  }
}

function Open-OutputsFolder([ValidateSet("AAB","APK","ROOT","BOTH")] [string]$which) {
  $p = Get-OutputPaths

  switch ($which) {
    "AAB"  { Open-FolderIfExists $p.AabDir; break }
    "APK"  { Open-FolderIfExists $p.ApkDir; break }
    "ROOT" { Open-FolderIfExists $p.OutputsRoot; break }
    "BOTH" {
      # ανοίγει ό,τι υπάρχει
      $opened = $false
      if (Test-Path -LiteralPath $p.AabDir) { Open-FolderIfExists $p.AabDir; $opened = $true }
      if (Test-Path -LiteralPath $p.ApkDir) { Open-FolderIfExists $p.ApkDir; $opened = $true }
      if (-not $opened) {
        Write-Host "❌ Δεν βρήκα outputs folders. Κάνε πρώτα ένα build."
      }
      break
    }
  }
}

function Find-LatestArtifactFile(
  [ValidateSet("aab","apk")] [string]$ext,
  [datetime]$since
) {
  $p = Get-OutputPaths
  $root = $p.OutputsRoot
  if (-not (Test-Path -LiteralPath $root)) { return "" }

  try {
    $files = Get-ChildItem -LiteralPath $root -Recurse -File -Filter "*.$ext" -ErrorAction SilentlyContinue
    if ($null -eq $files -or $files.Count -eq 0) { return "" }

    # Πάρε μόνο όσα γράφτηκαν μετά το start του build (με μικρό buffer)
    $cutoff = $since.AddSeconds(-2)
    $candidates = $files | Where-Object { $_.LastWriteTime -ge $cutoff }

    if ($null -eq $candidates -or $candidates.Count -eq 0) {
      # fallback: αν δεν βρούμε “μετά το build”, πάρε το πιο πρόσφατο γενικά
      $candidates = $files
    }

    $latest = $candidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($null -eq $latest) { return "" }
    return $latest.FullName
  } catch {
    return ""
  }
}

function Resolve-ArtifactPath(
  [ValidateSet("AAB","APK")] [string]$kind,
  [datetime]$since
) {
  $p = Get-OutputPaths
  $expected = if ($kind -eq "AAB") { $p.AabPath } else { $p.ApkPath }

  if (Test-Path -LiteralPath $expected) { return $expected }

  $ext = if ($kind -eq "AAB") { "aab" } else { "apk" }
  $latest = Find-LatestArtifactFile -ext $ext -since $since
  return $latest
}

function Open-ArtifactInExplorer([string]$artifactPath) {
  if ([string]::IsNullOrWhiteSpace($artifactPath)) { return $false }
  if (-not (Test-Path -LiteralPath $artifactPath)) { return $false }

  # /select δείχνει το συγκεκριμένο αρχείο (το “artifact”) — αυτό είναι το πιο “σίγουρο”
  Start-Process explorer.exe "/select,`"$artifactPath`""
  return $true
}

function Format-Bytes([long]$bytes) {
  if ($bytes -lt 0) { return "0 B" }
  $units = @("B","KB","MB","GB","TB")
  $size = [double]$bytes
  $i = 0
  while ($size -ge 1024 -and $i -lt ($units.Count - 1)) {
    $size /= 1024
    $i++
  }
  if ($i -eq 0) { return ("{0} {1}" -f [long]$size, $units[$i]) }
  return ("{0:N2} {1}" -f $size, $units[$i])
}

function Write-ArtifactInfo([string]$artifactPath) {
  if ([string]::IsNullOrWhiteSpace($artifactPath)) { return }
  if (-not (Test-Path -LiteralPath $artifactPath)) { return }

  $fi = Get-Item -LiteralPath $artifactPath -ErrorAction Stop
  $sizeText = Format-Bytes $fi.Length
  $ts = $fi.LastWriteTime.ToString("dd/MM/yyyy HH:mm:ss")


  Write-Host "✅ Artifact:"
  Write-Host "   Path : $($fi.FullName)"
  Write-Host "   Size : $sizeText"
  Write-Host "   Time : $ts"
}

# ---------------------------
# Run helpers
# ---------------------------

function Invoke-Cmd([string]$title, [string[]]$flutterArgs) {
  Write-Header $title
  Write-Host "-> flutter $($flutterArgs -join ' ')"
  Write-Host ""

  & flutter @flutterArgs
  $code = $LASTEXITCODE

  if ($code -ne 0) {
    Write-Host ""
    Write-Host "❌ Η εντολή απέτυχε με exit code: $code"
    return $false
  } else {
    Write-Host ""
    Write-Host "✅ Ολοκληρώθηκε επιτυχώς."
    return $true
  }
}

function Invoke-BuildAndOpen(
  [string]$title,
  [string[]]$flutterArgs,
  [ValidateSet("AAB","APK")] [string]$openKind
) {
  $start = Get-Date

  $ok = Invoke-Cmd $title $flutterArgs
  if (-not $ok) { return $false }

  Write-Host ""
  $artifact = Resolve-ArtifactPath -kind $openKind -since $start

  if (-not [string]::IsNullOrWhiteSpace($artifact) -and (Test-Path -LiteralPath $artifact)) {
    Write-ArtifactInfo $artifact
    Write-Host "Άνοιγμα στον Explorer (select artifact)..."
  [void](Open-ArtifactInExplorer $artifact)
  } else {
    Write-Host "⚠️ Build OK, αλλά δεν βρήκα με σιγουριά $openKind artifact κάτω από build\app\outputs."
    Write-Host "   Θα ανοίξω το outputs root για να το δεις χειροκίνητα."
    Open-OutputsFolder "ROOT"
  }

  return $true
}


function Wait-Menu {
  Write-Host ""
  Read-Host "Πάτα Enter για επιστροφή στο μενού" | Out-Null
}

function Get-YesNoChoice([string]$question, [string]$default = "Y") {
  $suffix = if ($default -eq "Y") { "[Y/n]" } else { "[y/N]" }
  $ans = Read-Host "$question $suffix"
  $ans = $ans.Trim()

  if ([string]::IsNullOrWhiteSpace($ans)) { $ans = $default }
  return ($ans.ToLower() -eq "y" -or $ans.ToLower() -eq "yes")
}

# ---------------------------
# Device picker + default memory
# ---------------------------

function Get-LastDeviceFilePath {
  $dir = Join-Path $ProjectPath "build"
  if (-not (Test-Path -LiteralPath $dir)) {
    New-Item -ItemType Directory -Path $dir | Out-Null
  }
  return (Join-Path $dir ".flutter_menu_last_device.txt")
}

function Get-LastDeviceId {
  if (-not [string]::IsNullOrWhiteSpace($script:LastDeviceId)) {
    return $script:LastDeviceId.Trim()
  }

  $f = Get-LastDeviceFilePath
  if (Test-Path -LiteralPath $f) {
    $id = (Get-Content -LiteralPath $f -ErrorAction SilentlyContinue | Select-Object -First 1)
    if ($id) {
      $id = $id.Trim()
      if (-not [string]::IsNullOrWhiteSpace($id)) {
        $script:LastDeviceId = $id
        return $id
      }
    }
  }
  return ""
}

function Set-LastDeviceId([string]$deviceId) {
  $deviceId = $deviceId.Trim()
  if ([string]::IsNullOrWhiteSpace($deviceId)) { return }
  $script:LastDeviceId = $deviceId

  $f = Get-LastDeviceFilePath
  Set-Content -LiteralPath $f -Value $deviceId -Encoding UTF8
}

function Clear-LastDeviceId {
  $script:LastDeviceId = ""
  $f = Get-LastDeviceFilePath
  if (Test-Path -LiteralPath $f) {
    Remove-Item -LiteralPath $f -Force
    Write-Host "✅ Default device καθαρίστηκε (διέγραψα: $f)"
  } else {
    Write-Host "ℹ️ Δεν υπήρχε αποθηκευμένο default device."
  }
}

function Get-FlutterDevices {
  $json = & flutter devices --machine 2>$null
  $code = $LASTEXITCODE
  if ($code -ne 0 -or [string]::IsNullOrWhiteSpace($json)) { return @() }

  try {
    $devices = $json | ConvertFrom-Json
    if ($null -eq $devices) { return @() }
    return @($devices)
  } catch {
    return @()
  }
}

function Get-AdbProp([string]$deviceId, [string]$propName) {
  $adb = Get-Command adb -ErrorAction SilentlyContinue
  if ($null -eq $adb) { return "" }

  try {
    $out = & adb -s $deviceId shell getprop $propName 2>$null
    if ($LASTEXITCODE -ne 0) { return "" }
    if ($out) { return ($out.ToString().Trim()) }
    return ""
  } catch {
    return ""
  }
}

function Get-AndroidBrandModel([string]$deviceId) {
  $man = Get-AdbProp $deviceId "ro.product.manufacturer"
  $model = Get-AdbProp $deviceId "ro.product.model"

  $parts = @()
  if (-not [string]::IsNullOrWhiteSpace($man)) { $parts += $man }
  if (-not [string]::IsNullOrWhiteSpace($model)) { $parts += $model }

  if ($parts.Count -eq 0) { return "" }
  return ($parts -join " ")
}

function Select-DeviceIdFromList {
  $devices = Get-FlutterDevices

  Write-Header "Select Android device"
  if ($devices.Count -eq 0) {
    Write-Host "❌ Δεν βρήκα devices από 'flutter devices --machine'."
    Write-Host "Δοκίμασε: flutter devices"
    return ""
  }

  $androidDevices = @(
    $devices |
      Where-Object { $_.isSupported -eq $true } |
      Where-Object { $_.targetPlatform -like "android-*" }
  )

  if ($androidDevices.Count -eq 0) {
    Write-Host "❌ Δεν βρήκα Android devices."
    return ""
  }

  $defaultId = Get-LastDeviceId
  $defaultIndex = -1
  if (-not [string]::IsNullOrWhiteSpace($defaultId)) {
    for ($i = 0; $i -lt $androidDevices.Count; $i++) {
      if ($androidDevices[$i].id -eq $defaultId) { $defaultIndex = $i; break }
    }
  }

  Write-Host "Βρέθηκαν Android devices:"
  Write-Host ""

  for ($i = 0; $i -lt $androidDevices.Count; $i++) {
    $d = $androidDevices[$i]
    $n = $i + 1

    $name = $d.name
    $id = $d.id
    $sdk = $d.sdk
    $emulator = if ($d.emulator) { " (emulator)" } else { "" }

    $bm = Get-AndroidBrandModel $id
    $bmText = ""
    if (-not [string]::IsNullOrWhiteSpace($bm)) { $bmText = " | $bm" }

    $isDefault = ($i -eq $defaultIndex)
    $defText = if ($isDefault) { "  (default)" } else { "" }

    Write-Host ("{0}) {1}{2}{3}{4}  |  id: {5}" -f $n, $name, $emulator, $bmText, $defText, $id)
    Write-Host ("    sdk: {0}" -f $sdk)
  }

  Write-Host ""

  if ($defaultIndex -ge 0) {
    $defaultNumber = $defaultIndex + 1
    $pick = Read-Host ("Διάλεξε συσκευή (1-{0}) ή Enter για default: {1}" -f $androidDevices.Count, $defaultNumber)
    $pick = $pick.Trim()
    if ([string]::IsNullOrWhiteSpace($pick)) {
      $chosenId = $androidDevices[$defaultIndex].id
      Set-LastDeviceId $chosenId
      return $chosenId
    }
  } else {
    $pick = Read-Host ("Διάλεξε συσκευή (1-{0}) ή Enter για ακύρωση" -f $androidDevices.Count)
    $pick = $pick.Trim()
    if ([string]::IsNullOrWhiteSpace($pick)) { return "" }
  }

  $num = 0
  if (-not [int]::TryParse($pick, [ref]$num)) {
    Write-Host "❌ Μη έγκυρος αριθμός."
    return ""
  }

  if ($num -lt 1 -or $num -gt $androidDevices.Count) {
    Write-Host "❌ Εκτός ορίων."
    return ""
  }

  $chosen = $androidDevices[$num - 1].id
  Set-LastDeviceId $chosen
  return $chosen
}

# ---------------------------
# Install helpers (adb/flutter)
# ---------------------------

function Test-Adb {
  $adb = Get-Command adb -ErrorAction SilentlyContinue
  if ($null -eq $adb) {
    Write-Host "⚠️ Δεν βρέθηκε adb στο PATH."
    return $false
  }
  return $true
}

function Get-InstalledAppInfo([string]$deviceId) {
  if (-not (Test-Adb)) { return "" }

  try {
    $pkg = $script:AndroidPackageName

    $pathOut = & adb -s $deviceId shell pm path $pkg 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($pathOut)) {
      return "NOT_INSTALLED"
    }

    $installer = & adb -s $deviceId shell pm get-install-source $pkg 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($installer)) {
      $installer = "(unknown installer)"
    } else {
      $installer = $installer.ToString().Trim()
    }

    $dumpsys = & adb -s $deviceId shell dumpsys package $pkg 2>$null
    $vn = ""
    $vc = ""
    if ($dumpsys) {
      $m1 = [regex]::Match($dumpsys, "versionName=([^\s]+)")
      if ($m1.Success) { $vn = $m1.Groups[1].Value }
      $m2 = [regex]::Match($dumpsys, "versionCode=(\d+)")
      if ($m2.Success) { $vc = $m2.Groups[1].Value }
    }

    return "INSTALLED|versionName=$vn|versionCode=$vc|installSource=$installer"
  } catch {
    return ""
  }
}

function Uninstall-AppFromDevice([string]$deviceId) {
  if (-not (Test-Adb)) { return }

  $pkg = $script:AndroidPackageName
  Write-Header "Uninstall app from device"
  Write-Host "Device: $deviceId"
  Write-Host "Package: $pkg"
  Write-Host ""

  $out = & adb -s $deviceId uninstall $pkg 2>&1
  Write-Host $out
  if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Uninstall failed (exit code: $LASTEXITCODE)"
  } else {
    Write-Host "✅ Uninstall OK."
  }
}

function Install-ApkToDevice([string]$apkPath, [string]$title) {
  if (-not (Test-Path -LiteralPath $apkPath)) {
    Write-Host "❌ Δεν βρέθηκε APK: $apkPath"
    return
  }

  $deviceId = Select-DeviceIdFromList
  if ([string]::IsNullOrWhiteSpace($deviceId)) {
    Write-Host "Ακύρωση (δεν επιλέχθηκε συσκευή)."
    return
  }

  Write-Header $title
  Write-Host "APK: $apkPath"
  Write-Host "Device: $deviceId"
  Write-Host ""

  if (Test-Adb) {
    $info = Get-InstalledAppInfo $deviceId
    if ($info -eq "NOT_INSTALLED") {
      Write-Host "ℹ️ Η εφαρμογή ΔΕΝ είναι εγκατεστημένη στη συσκευή."
    } elseif (-not [string]::IsNullOrWhiteSpace($info)) {
      Write-Host "ℹ️ Υπάρχει ήδη εγκατεστημένη: $info"
    }
    Write-Host ""
  }

  $adb = Get-Command adb -ErrorAction SilentlyContinue
  if ($null -ne $adb) {
    Write-Host "-> adb -s $deviceId install -r `"$apkPath`""
    $out = & adb -s $deviceId install -r "$apkPath" 2>&1
    Write-Host $out

    $code = $LASTEXITCODE
    if ($code -ne 0) {
      Write-Host ""
      Write-Host "❌ adb install failed (exit code: $code)"

      if ($out -match "INSTALL_FAILED_UPDATE_INCOMPATIBLE" -or $out -match "signatures do not match") {
        Write-Host ""
        Write-Host "➡️ Signature mismatch: υπάρχει ήδη η app αλλά έχει χτιστεί/υπογραφεί με άλλο keystore."
        Write-Host "   Αυτό συμβαίνει συχνά όταν άλλοτε έχεις Play Store build και άλλοτε local APK."
        Write-Host ""
        Write-Host "   Λύσεις:"
        Write-Host "   A) Uninstall την υπάρχουσα app από τη συσκευή και ξανακάνε install (θα περάσει σίγουρα)."
        Write-Host "   B) Χτίσε APK/AAB με το ΙΔΙΟ keystore που είχε η ήδη εγκατεστημένη έκδοση."
        Write-Host ""
        Write-Host "Tip: Χρησιμοποίησε την επιλογή 14 (Uninstall app from device) και μετά ξαναδοκίμασε."
      }
    } else {
      Write-Host ""
      Write-Host "✅ Εγκαταστάθηκε με adb."
    }
  } else {
    Write-Host "⚠️ Δεν βρέθηκε adb στο PATH. Θα κάνω flutter install -d <device> (μπορεί να κάνει rebuild)."
    Invoke-Cmd "flutter install (may rebuild)" @("install","-d",$deviceId) | Out-Null
  }
}

# ---------------------------
# Install flows (11/12)
# ---------------------------

function Install-ReleaseApk_SentryOff {
  $p = Get-OutputPaths

  if (-not (Test-Path -LiteralPath $p.ApkPath)) {
    Write-Host "Δεν βρήκα Release APK: $($p.ApkPath)"
    $buildIt = Get-YesNoChoice "Θες να κάνω πρώτα build Release APK (Sentry OFF) για να υπάρχει;" "Y"
    if ($buildIt) {
      $ok = Invoke-BuildAndOpen "Build Release APK (Sentry OFF) πριν το Install" @("build","apk","--release") "APK"
      if (-not $ok) { return }
    } else {
      Write-Host "Ακύρωση."
      return
    }
  }

  if (-not (Test-Path -LiteralPath $p.ApkPath)) {
    Write-Host "❌ Ακόμα δεν υπάρχει APK. Σταματάω."
    return
  }

  Install-ApkToDevice $p.ApkPath "Install Release APK (Sentry OFF)"
}

function Invoke-BuildAndInstallReleaseApk_SentryOn {
  $dsn = Get-SentryDsn
  if ([string]::IsNullOrWhiteSpace($dsn)) {
    Write-Host "❌ Δεν υπάρχει DSN. Πήγαινε στην επιλογή 6 για να το βάλεις."
    return
  }

  $ok = Invoke-BuildAndOpen "Build Release APK (Sentry ON)" @("build","apk","--release","--dart-define=SENTRY_DSN=$dsn") "APK"
  if (-not $ok) { return }

  $p = Get-OutputPaths
  if (-not (Test-Path -LiteralPath $p.ApkPath)) {
    Write-Host "❌ Δεν βρέθηκε APK μετά το build. Σταματάω."
    return
  }

  Install-ApkToDevice $p.ApkPath "Install Release APK (Sentry ON)"
}

function Uninstall-AppFlow {
  $deviceId = Select-DeviceIdFromList
  if ([string]::IsNullOrWhiteSpace($deviceId)) {
    Write-Host "Ακύρωση (δεν επιλέχθηκε συσκευή)."
    return
  }
  Uninstall-AppFromDevice $deviceId
}

function Invoke-InstalledAppInfoFlow {
  $deviceId = Select-DeviceIdFromList
  if ([string]::IsNullOrWhiteSpace($deviceId)) {
    Write-Host "Ακύρωση (δεν επιλέχθηκε συσκευή)."
    return
  }

  Write-Header "Check installed app info"
  Write-Host "Device: $deviceId"
  Write-Host "Package: $($script:AndroidPackageName)"
  Write-Host ""

  if (-not (Test-Adb)) {
    Write-Host "❌ Χρειάζεται adb στο PATH."
    return
  }

  $info = Get-InstalledAppInfo $deviceId
  if ($info -eq "NOT_INSTALLED") {
    Write-Host "ℹ️ Η εφαρμογή ΔΕΝ είναι εγκατεστημένη στη συσκευή."
  } elseif ([string]::IsNullOrWhiteSpace($info)) {
    Write-Host "⚠️ Δεν μπόρεσα να διαβάσω info."
  } else {
    Write-Host "✅ $info"
    Write-Host ""
    Write-Host "Hint:"
    Write-Host "- Αν δεις installSource με 'com.android.vending' => Play Store"
    Write-Host "- Αν είναι '(unknown)' ή άλλο => πιθανότατα APK / άλλος installer"
  }
}

# ---------------------------
# Keystore sanity check (Android signing) - same as before
# ---------------------------

function Find-AndroidSigningFiles {
  $androidDir = Join-Path $ProjectPath "android"
  $appDir = Join-Path $androidDir "app"

  $buildGradleGroovy = Join-Path $appDir "build.gradle"
  $buildGradleKts    = Join-Path $appDir "build.gradle.kts"

  $keyProps1 = Join-Path $androidDir "key.properties"
  $keyProps2 = Join-Path $appDir "key.properties"

  return [pscustomobject]@{
    AndroidDir = $androidDir
    AppDir = $appDir
    BuildGradleGroovy = $buildGradleGroovy
    BuildGradleKts = $buildGradleKts
    KeyPropsAndroid = $keyProps1
    KeyPropsApp = $keyProps2
  }
}

function Read-KeyProperties([string]$path) {
  if (-not (Test-Path -LiteralPath $path)) { return $null }

  $dict = @{}
  $lines = Get-Content -LiteralPath $path -ErrorAction Stop
  foreach ($line in $lines) {
    $t = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($t)) { continue }
    if ($t.StartsWith("#")) { continue }

    $idx = $t.IndexOf("=")
    if ($idx -lt 1) { continue }

    $k = $t.Substring(0, $idx).Trim()
    $v = $t.Substring($idx + 1).Trim()
    if (-not [string]::IsNullOrWhiteSpace($k)) { $dict[$k] = $v }
  }
  return $dict
}

function Resolve-KeystorePath([string]$androidDir, [string]$storeFileValue) {
  if ([string]::IsNullOrWhiteSpace($storeFileValue)) { return "" }
  $storeFileValue = $storeFileValue.Trim()

  if ([System.IO.Path]::IsPathRooted($storeFileValue)) { return $storeFileValue }
  return (Join-Path $androidDir $storeFileValue)
}

function Test-KeystoreSanity {
  $f = Find-AndroidSigningFiles
  $androidDir = $f.AndroidDir

  Write-Header "Keystore sanity check (Android signing) - STRICT"
  Write-Host "Project: $ProjectPath"
  Write-Host "Android: $androidDir"
  Write-Host ""

  if (-not (Test-Path -LiteralPath $androidDir)) {
    Write-Host "❌ Problem: Δεν υπάρχει android/ folder."
    return
  }

  $buildFile = ""
  $buildKind = ""
  if (Test-Path -LiteralPath $f.BuildGradleKts) { $buildFile = $f.BuildGradleKts; $buildKind = "kts" }
  elseif (Test-Path -LiteralPath $f.BuildGradleGroovy) { $buildFile = $f.BuildGradleGroovy; $buildKind = "groovy" }

  $keyPropsPath = ""
  if (Test-Path -LiteralPath $f.KeyPropsAndroid) { $keyPropsPath = $f.KeyPropsAndroid }
  elseif (Test-Path -LiteralPath $f.KeyPropsApp) { $keyPropsPath = $f.KeyPropsApp }

  $kp = $null
  if (-not [string]::IsNullOrWhiteSpace($keyPropsPath)) { $kp = Read-KeyProperties $keyPropsPath }

  $storeFileVal = ""
  $aliasVal = ""
  if ($null -ne $kp) {
    if ($kp.ContainsKey("storeFile")) { $storeFileVal = $kp["storeFile"] }
    if ($kp.ContainsKey("keyAlias"))  { $aliasVal = $kp["keyAlias"] }
  }

  $resolvedKs = ""
  if (-not [string]::IsNullOrWhiteSpace($storeFileVal)) { $resolvedKs = Resolve-KeystorePath $androidDir $storeFileVal }

  $keystoreExists = $false
  if (-not [string]::IsNullOrWhiteSpace($resolvedKs)) { $keystoreExists = (Test-Path -LiteralPath $resolvedKs) }

  $buildText = ""
  if (-not [string]::IsNullOrWhiteSpace($buildFile)) { $buildText = (Get-Content -LiteralPath $buildFile -Raw -ErrorAction Stop) }

  $hasSigningConfigsBlock = $false
  $hasReleaseSigningConfig = $false
  $releaseUsesSigningConfig = $false

  if (-not [string]::IsNullOrWhiteSpace($buildText)) {
    if ($buildText -match "(?s)signingConfigs\s*\{") { $hasSigningConfigsBlock = $true }

    if ($buildText -match "(?s)signingConfigs\s*\{.*?\brelease\s*\{") { $hasReleaseSigningConfig = $true }
    elseif ($buildKind -eq "kts" -and $buildText -match "(?s)signingConfigs\s*\{.*?\bcreate\(\s*""release""\s*\)") { $hasReleaseSigningConfig = $true }
    elseif ($buildKind -eq "kts" -and $buildText -match "signingConfigs\.create\(\s*""release""\s*\)") { $hasReleaseSigningConfig = $true }

    if ($buildText -match "(?s)buildTypes\s*\{[^}]*release\s*\{[^}]*signingConfig\s+signingConfigs\.release") { $releaseUsesSigningConfig = $true }
    elseif ($buildKind -eq "kts" -and $buildText -match "(?s)buildTypes\s*\{[^}]*getByName\(\s*""release""\s*\)\s*\{[^}]*signingConfig\s*=\s*signingConfigs\.getByName\(\s*""release""\s*\)") { $releaseUsesSigningConfig = $true }
    elseif ($buildKind -eq "kts" -and $buildText -match "(?s)buildTypes\s*\{[^}]*release\s*\{[^}]*signingConfig\s*=\s*signingConfigs\.getByName\(\s*""release""\s*\)") { $releaseUsesSigningConfig = $true }
  }

  $problems = @()

  Write-Host "Checklist:"
  Write-Host ""

  if ([string]::IsNullOrWhiteSpace($buildFile)) {
    Write-Host "❌ Problem: Δεν βρήκα android/app/build.gradle ή build.gradle.kts"
    $problems += "Missing build.gradle(.kts) in android/app/"
  } else { Write-Host "✅ OK: Found build file: $buildFile" }

  if ([string]::IsNullOrWhiteSpace($keyPropsPath)) {
    Write-Host "❌ Problem: Δεν βρήκα key.properties (android/key.properties ή android/app/key.properties)"
    $problems += "Missing key.properties"
  } else { Write-Host "✅ OK: Found key.properties: $keyPropsPath" }

  if ($null -eq $kp -and -not [string]::IsNullOrWhiteSpace($keyPropsPath)) {
    Write-Host "❌ Problem: key.properties υπάρχει αλλά δεν μπόρεσα να το διαβάσω"
    $problems += "Cannot read key.properties"
  } elseif ($null -ne $kp) {
    if ([string]::IsNullOrWhiteSpace($storeFileVal)) { Write-Host "❌ Problem: key.properties δεν έχει storeFile="; $problems += "Missing storeFile in key.properties" }
    else { Write-Host "✅ OK: key.properties έχει storeFile= $storeFileVal" }

    if ([string]::IsNullOrWhiteSpace($aliasVal)) { Write-Host "❌ Problem: key.properties δεν έχει keyAlias="; $problems += "Missing keyAlias in key.properties" }
    else { Write-Host "✅ OK: key.properties έχει keyAlias= $aliasVal" }

    if (-not [string]::IsNullOrWhiteSpace($storeFileVal)) {
      Write-Host "ℹ️ Resolved keystore path: $resolvedKs"
      if ($keystoreExists) { Write-Host "✅ OK: Keystore file υπάρχει." }
      else { Write-Host "❌ Problem: Keystore file ΔΕΝ υπάρχει στο resolved path."; $problems += "Keystore file not found at resolved path" }
    }
  }

  if (-not [string]::IsNullOrWhiteSpace($buildFile)) {
    if ($hasSigningConfigsBlock) { Write-Host "✅ OK: Υπάρχει signingConfigs { ... }" }
    else { Write-Host "❌ Problem: Δεν βλέπω signingConfigs { ... } στο build file"; $problems += "Missing signingConfigs block" }

    if ($hasReleaseSigningConfig) { Write-Host "✅ OK: Υπάρχει signing config για release." }
    else { Write-Host "❌ Problem: Δεν βλέπω signing config 'release' στο build file"; $problems += "Missing signingConfigs.release" }

    if ($releaseUsesSigningConfig) { Write-Host "✅ OK: Το buildTypes.release χρησιμοποιεί signingConfigs.release" }
    else { Write-Host "❌ Problem: Δεν βλέπω το buildTypes.release να δένει σε signingConfigs.release"; $problems += "Release buildType does not use signingConfigs.release" }
  }

  Write-Host ""
  Write-Host "------------------------------------------------------------"
  if ($problems.Count -eq 0) {
    Write-Host "✅ Συμπέρασμα: Release signing φαίνεται OK."
    Write-Host "   (Αν στο install βγει mismatch, πιθανότατα η ήδη εγκατεστημένη app είναι με άλλο keystore — π.χ. Play Store.)"
  } else {
    Write-Host "❌ Συμπέρασμα: Release signing έχει PROBLEMS."
    Write-Host ""
    Write-Host "Τι να φτιάξεις (συγκεκριμένα):"
    foreach ($p in $problems) {
      switch -Wildcard ($p) {
        "Missing key.properties" { Write-Host " - Φτιάξε key.properties (android/key.properties ή android/app/key.properties) και δήλωσε storeFile/keyAlias."; break }
        "Missing storeFile*"     { Write-Host " - Βάλε storeFile=... στο key.properties (path προς το keystore)."; break }
        "Missing keyAlias*"      { Write-Host " - Βάλε keyAlias=... στο key.properties."; break }
        "Keystore file not found*" { Write-Host " - Διόρθωσε το storeFile path ή βάλε το keystore αρχείο στο σωστό σημείο."; break }
        "Missing signingConfigs block" { Write-Host " - Πρόσθεσε signingConfigs { release { ... } } στο android/app build file."; break }
        "Missing signingConfigs.release" { Write-Host " - Πρόσθεσε signingConfigs.release (release { ... }) ή signingConfigs.create(""release"") στο kts."; break }
        "Release buildType does not use signingConfigs.release" { Write-Host " - Στο buildTypes.release βάλε signingConfig = signingConfigs.getByName(""release"") (kts) ή signingConfig signingConfigs.release (groovy)."; break }
        default { Write-Host " - $p" }
      }
    }
  }
  Write-Host "------------------------------------------------------------"
  Write-Host ""
  Write-Host "Σημείωση: Δεν εμφανίζω passwords. Μόνο structure/paths."
}

# ---------------- MAIN ----------------
try {
  Confirm-ProjectPath

  while ($true) {
    Clear-Host
    Write-Header "Flutter Build/Run Menu (Sentry via --dart-define)"
    Write-Host "Project: $ProjectPath"
    Write-Host "SENTRY_DSN (session): $($env:SENTRY_DSN)"
    Write-Host "Last Android device (default): $(Get-LastDeviceId)"
    Write-Host ""
    Write-Host "1)  Build Release AAB (Sentry ON)  + Open Output Folder (Explorer)"
    Write-Host "2)  Build Release AAB (Sentry OFF) + Open Output Folder (Explorer)"
    Write-Host "3)  Debug Run    (Sentry OFF)"
    Write-Host "4)  Debug Run    (Sentry ON)"
    Write-Host "5)  Clean + Pub Get"
    Write-Host "6)  Set/Update SENTRY_DSN"
    Write-Host "7)  Build Release APK (Sentry ON)  + Open Output Folder (Explorer) (προαιρετικό)"
    Write-Host "8)  Build Release APK (Sentry OFF) + Open Output Folder (Explorer) (προαιρετικό)"
    Write-Host "9)  Show output paths (AAB/APK)"
    Write-Host "10) Open output folders (Explorer) (no build)"
    Write-Host "11) Install Release APK (Sentry OFF)  (device picker: numbered list + remembers last device)"
    Write-Host "12) Build + Install Release APK (Sentry ON) (device picker: numbered list + remembers last device)"
    Write-Host "13) Clear Default Device"
    Write-Host "14) Uninstall app from Android device (fix signature mismatch)"
    Write-Host "15) Check installed app info (Play Store vs APK hint)"
    Write-Host "16) Keystore sanity check (Android signing config)"
    Write-Host "0)  Exit"
    Write-Host ""

    $choice = Read-Host "Δώσε επιλογή (0-16)"
    switch ($choice) {

      "1" {
        $dsn = Get-SentryDsn
        if ([string]::IsNullOrWhiteSpace($dsn)) {
          Write-Host "❌ Δεν υπάρχει DSN. Πήγαινε στην επιλογή 6 για να το βάλεις."
          Wait-Menu
          break
        }
        Invoke-BuildAndOpen "Release AAB (Sentry ON)" @("build","appbundle","--release","--dart-define=SENTRY_DSN=$dsn") "AAB" | Out-Null
        Wait-Menu
      }

      "2" {
        Invoke-BuildAndOpen "Release AAB (Sentry OFF)" @("build","appbundle","--release") "AAB" | Out-Null
        Wait-Menu
      }

      "3" { Invoke-Cmd "Debug Run (Sentry OFF)" @("run") | Out-Null; Wait-Menu }

      "4" {
        $dsn = Get-SentryDsn
        if ([string]::IsNullOrWhiteSpace($dsn)) {
          Write-Host "❌ Δεν υπάρχει DSN. Πήγαινε στην επιλογή 6 για να το βάλεις."
          Wait-Menu
          break
        }
        Invoke-Cmd "Debug Run (Sentry ON)" @("run","--dart-define=SENTRY_DSN=$dsn") | Out-Null
        Wait-Menu
      }

      "5" {
        Invoke-Cmd "flutter clean" @("clean") | Out-Null
        Invoke-Cmd "flutter pub get" @("pub","get") | Out-Null
        Wait-Menu
      }

      "6" { Set-SentryDsnPersisted; Wait-Menu }

      "7" {
        $dsn = Get-SentryDsn
        if ([string]::IsNullOrWhiteSpace($dsn)) {
          Write-Host "❌ Δεν υπάρχει DSN. Πήγαινε στην επιλογή 6 για να το βάλεις."
          Wait-Menu
          break
        }
        Invoke-BuildAndOpen "Release APK (Sentry ON)" @("build","apk","--release","--dart-define=SENTRY_DSN=$dsn") "APK" | Out-Null
        Wait-Menu
      }

      "8" {
        Invoke-BuildAndOpen "Release APK (Sentry OFF)" @("build","apk","--release") "APK" | Out-Null
        Wait-Menu
      }

      "9" { Show-OutputPaths; Wait-Menu }

      "10" {
        Write-Header "Open output folders (Explorer)"
        Open-OutputsFolder "BOTH"
        Wait-Menu
      }

      "11" { Install-ReleaseApk_SentryOff; Wait-Menu }
      "12" { Invoke-BuildAndInstallReleaseApk_SentryOn; Wait-Menu }

      "13" {
        Write-Header "Clear Default Device"
        Clear-LastDeviceId
        Wait-Menu
      }

      "14" { Uninstall-AppFlow; Wait-Menu }
      "15" { Invoke-InstalledAppInfoFlow; Wait-Menu }

      "16" {
        Test-KeystoreSanity
        Wait-Menu
      }

      "0" { Write-Host "Bye!"; return }

      default { Write-Host "Μη έγκυρη επιλογή."; Wait-Menu }
    }
  }
}
catch {
  Write-Host ""
  Write-Host "💥 ERROR: $($_.Exception.Message)"
  Write-Host ""
  Read-Host "Πάτα Enter για έξοδο" | Out-Null
}