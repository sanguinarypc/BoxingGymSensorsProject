cd C:\BoxingGymSensorsProject\box_sensors

Write-Host "=== 1. Stop Gradle daemons ==="
cd android
.\gradlew --stop
.\gradlew --status

Write-Host "=== 2. Gradle clean ==="
.\gradlew clean
cd ..

Write-Host "=== 3. Flutter clean ==="
flutter clean

Write-Host "=== 4. Get dependencies ==="
flutter pub get

Write-Host "=== 5. Upgrade dependencies within current constraints ==="
flutter pub upgrade

Write-Host "=== 6. Check outdated packages ==="
flutter pub outdated

Write-Host "=== 7. Analyze project ==="
flutter analyze

Write-Host "=== 8. Build release App Bundle ==="
flutter build appbundle --release

Write-Host "=== DONE ==="