# 雷雨新闻客户端 APK 构建脚本 (PowerShell版本)
# 使用方法: powershell -ExecutionPolicy Bypass -File scripts/build_apk.ps1

Write-Host "================================" -ForegroundColor Cyan
Write-Host "    雷雨新闻客户端 APK 构建脚本" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 检查是否在项目根目录
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "错误: 请在Flutter项目根目录运行此脚本" -ForegroundColor Red
    Read-Host "按任意键退出"
    exit 1
}

# 询问用户是否要增加版本号
$increment = Read-Host "是否要增加版本号? (y/n, 默认y)"
if ([string]::IsNullOrEmpty($increment)) { $increment = "y" }

if ($increment.ToLower() -eq "y") {
    Write-Host ""
    Write-Host "选择版本号增加类型:" -ForegroundColor Yellow
    Write-Host "1. 构建号 (推荐，用于日常构建)" -ForegroundColor White
    Write-Host "2. 补丁版本号 (修复bug)" -ForegroundColor White
    Write-Host "3. 次版本号 (新功能)" -ForegroundColor White
    Write-Host "4. 主版本号 (重大更新)" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "请选择 (1-4, 默认1)"
    if ([string]::IsNullOrEmpty($choice)) { $choice = "1" }
    
    switch ($choice) {
        "1" {
            Write-Host "增加构建号..." -ForegroundColor Green
            & dart scripts/increment_version.dart build
        }
        "2" {
            Write-Host "增加补丁版本号..." -ForegroundColor Green
            & dart scripts/increment_version.dart patch
        }
        "3" {
            Write-Host "增加次版本号..." -ForegroundColor Green
            & dart scripts/increment_version.dart minor
        }
        "4" {
            Write-Host "增加主版本号..." -ForegroundColor Green
            & dart scripts/increment_version.dart major
        }
        default {
            Write-Host "无效选择，使用默认构建号增加" -ForegroundColor Yellow
            & dart scripts/increment_version.dart build
        }
    }
    Write-Host ""
}

# 清理之前的构建
Write-Host "清理之前的构建文件..." -ForegroundColor Yellow
& flutter clean
Write-Host ""

# 获取依赖
Write-Host "获取项目依赖..." -ForegroundColor Yellow
& flutter pub get
Write-Host ""

# 构建APK
Write-Host "开始构建APK..." -ForegroundColor Yellow
Write-Host "构建类型: Release" -ForegroundColor White
Write-Host ""
& flutter build apk --release

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "================================" -ForegroundColor Green
    Write-Host "        构建成功完成!" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host "APK文件位置: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor White
    Write-Host ""
    
    # 询问是否打开APK文件夹
    $open = Read-Host "是否打开APK文件夹? (y/n, 默认y)"
    if ([string]::IsNullOrEmpty($open)) { $open = "y" }
    if ($open.ToLower() -eq "y") {
        & explorer "build/app/outputs/flutter-apk"
    }
} else {
    Write-Host ""
    Write-Host "================================" -ForegroundColor Red
    Write-Host "        构建失败!" -ForegroundColor Red
    Write-Host "================================" -ForegroundColor Red
    Write-Host "请检查上面的错误信息" -ForegroundColor White
}

Write-Host ""
Read-Host "按任意键退出"