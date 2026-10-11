param(
    [Parameter(Mandatory = $true)]
    [string]$ArtifactPath
)

# Guard against the mixed Dart/native path_provider implementation in Play build 52.
# Run on the final APK/AAB, using the project's current release symbol settings.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ArtifactPath))

function Read-ArtifactText($Entry) {
    $stream = $Entry.Open()
    $memory = New-Object IO.MemoryStream
    try {
        $stream.CopyTo($memory)
        return [Text.Encoding]::ASCII.GetString($memory.ToArray())
    } finally {
        $stream.Dispose()
        $memory.Dispose()
    }
}

try {
    $dartLibraries = @($archive.Entries | Where-Object {
        $_.FullName -match '^(base/)?lib/[^/]+/libapp\.so$'
    })
    if ($dartLibraries.Count -eq 0) {
        throw 'No release Dart libraries found in APK/AAB.'
    }

    foreach ($entry in $dartLibraries) {
        $dartText = Read-ArtifactText $entry
        if ($dartText.Contains('dev.flutter.pigeon.path_provider_android') -or
            $dartText.Contains('path_provider_android/messages.g.dart')) {
            throw "Stale Pigeon implementation found in $($entry.FullName). Clean and rebuild with path_provider_android 2.3.1 before distributing."
        }
        if (!$dartText.Contains('path_provider_android_real.dart')) {
            throw "Expected JNI path_provider implementation missing in $($entry.FullName)."
        }
    }

    $jniPluginFound = $false
    foreach ($entry in $archive.Entries | Where-Object {
        $_.FullName -match '^(base/dex/)?classes[0-9]*\.dex$'
    }) {
        if ((Read-ArtifactText $entry).Contains('JniFlutterPlugin')) {
            $jniPluginFound = $true
            break
        }
    }
    if (!$jniPluginFound) {
        throw 'Native JniFlutterPlugin registration missing in APK/AAB.'
    }

    Write-Output "PASS: JNI path_provider and native registration present; no stale Pigeon code in $($dartLibraries.Count) Dart ABI libraries."
} finally {
    $archive.Dispose()
}
