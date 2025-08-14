# Set console encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "================================" -ForegroundColor Cyan
Write-Host "  Flutter Clinet Release Build" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Check if in project root directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "Error: Please run this script in Flutter project root directory" -ForegroundColor Red
    Read-Host "Press any key to exit"
    exit 1
}

# Display version type selection
Write-Host "Please select release version type:" -ForegroundColor Yellow
Write-Host "0. test   - Test version (for testing, separate from release version)"
Write-Host "1. patch  - Patch version (bug fixes)"
Write-Host "2. minor  - Minor version (new features)"
Write-Host "3. major  - Major version (major updates)"
Write-Host ""

$choice = Read-Host "Please select (0-3, default 1)"
if ([string]::IsNullOrEmpty($choice)) { $choice = "1" }

switch ($choice) {
    "0" {
        $version_type = "test"
        Write-Host "Selected: Test version build" -ForegroundColor Magenta
    }
    "1" {
        $version_type = "patch"
        Write-Host "Selected: Patch version build" -ForegroundColor Green
    }
    "2" {
        $version_type = "minor"
        Write-Host "Selected: Minor version build" -ForegroundColor Green
    }
    "3" {
        $version_type = "major"
        Write-Host "Selected: Major version build" -ForegroundColor Green
    }
    default {
        Write-Host "Invalid selection, using default patch version" -ForegroundColor Yellow
        $version_type = "patch"
    }
}

Write-Host ""
Write-Host "Starting release build..." -ForegroundColor Cyan
Write-Host ""

# Check if Flutter is available
try {
    $flutterVersion = & flutter --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter not found"
    }
} catch {
    Write-Host "Error: Flutter is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Flutter SDK and add it to your PATH environment variable" -ForegroundColor Yellow
    Write-Host "Visit: https://flutter.dev/docs/get-started/install" -ForegroundColor Cyan
    Read-Host "Press any key to exit"
    exit 1
}

# Check if Dart is available
try {
    $dartVersion = & dart --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Dart not found"
    }
} catch {
    Write-Host "Error: Dart is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Dart should be included with Flutter SDK" -ForegroundColor Yellow
    Read-Host "Press any key to exit"
    exit 1
}

# Execute release build script
# 设置控制台编码为UTF-8，防止中文乱码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# 设置控制台代码页为UTF-8（65001）
chcp 65001
& dart "scripts\release_build.dart" $version_type

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Release build completed!" -ForegroundColor Green
    Write-Host ""
    
    # Automatically open APK folder
    if (Test-Path "build\app\outputs\flutter-apk") {
        Write-Host "Opening APK folder..." -ForegroundColor Cyan
        Start-Process "explorer" "build\app\outputs\flutter-apk"
    } else {
        Write-Host "APK folder does not exist, build may have failed" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "Release build failed!" -ForegroundColor Red
    Write-Host "Please check the error messages above" -ForegroundColor Red
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green