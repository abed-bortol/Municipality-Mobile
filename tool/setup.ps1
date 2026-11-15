# One-time setup, run after installing Flutter:
#   powershell -ExecutionPolicy Bypass -File tool\setup.ps1
#
# 1. Generates the android/ and ios/ folders (existing files in lib/, test/,
#    pubspec.yaml are NOT overwritten by `flutter create`).
# 2. Sets the display name "Tripoli HealthPulse" + INTERNET permission.
# 3. Generates launcher icons and the native splash from assets/branding/.

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$AppName = 'Tripoli HealthPulse'
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

function Update-File($Path, [scriptblock]$Transform) {
    $text = [IO.File]::ReadAllText((Resolve-Path $Path))
    [IO.File]::WriteAllText((Resolve-Path $Path), (& $Transform $text), $Utf8NoBom)
}

flutter create --project-name municipality --org lb.tripoli --platforms android,ios .
if ($LASTEXITCODE) { throw 'flutter create failed' }

Update-File 'android/app/src/main/AndroidManifest.xml' {
    param($xml)
    $xml = $xml -replace 'android:label="[^"]*"', "android:label=`"$AppName`""
    if ($xml -notmatch 'android.permission.INTERNET') {
        $xml = $xml -replace '(<manifest[^>]*>)', "`$1`n    <uses-permission android:name=`"android.permission.INTERNET`"/>"
    }
    $xml
}

# Debug/profile builds may call the local dev API over plain http://
# (release builds stay HTTPS-only).
foreach ($variant in 'debug', 'profile') {
    Update-File "android/app/src/$variant/AndroidManifest.xml" {
        param($xml)
        if ($xml -match 'usesCleartextTraffic') { return $xml }
        $xml -replace '</manifest>', "    <application android:usesCleartextTraffic=`"true`"/>`n</manifest>"
    }
}

Update-File 'ios/Runner/Info.plist' {
    param($plist)
    $plist -replace '(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)', "`$1$AppName`$2"
}

flutter pub get
if ($LASTEXITCODE) { throw 'flutter pub get failed' }
# Generates *.g.dart / *.freezed.dart (Riverpod providers, Freezed models, JSON).
dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE) { throw 'build_runner failed' }
dart run flutter_launcher_icons
if ($LASTEXITCODE) { throw 'flutter_launcher_icons failed' }
dart run flutter_native_splash:create
if ($LASTEXITCODE) { throw 'flutter_native_splash failed' }

Write-Host "`nDone. Connect your phone (USB debugging on) and run: flutter run" -ForegroundColor Green
