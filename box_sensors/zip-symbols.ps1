$libPath = "build\app\intermediates\merged_native_libs\release\mergeReleaseNativeLibs\out"    
$zipOutput = "symbols.zip"

if (Test-Path $libPath) {
    Compress-Archive -Path "$libPath\*" -DestinationPath $zipOutput -Force
    Write-Host "✅ Native symbols zipped to $zipOutput"
} else {
    Write-Host "❌ Path not found: $libPath"
}

