@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
echo ================================
echo    Thunder News Client Release Build
echo ================================
echo.

:: Check if running in project root directory
if not exist "pubspec.yaml" (
    echo Error: Please run this script from Flutter project root directory
    pause
    exit /b 1
)

:: 显示版本类型选择
echo 请选择发布版本类型:
echo 1. patch  - 补丁版本 (修复bug)
echo 2. minor  - 次版本 (新功能)
echo 3. major  - 主版本 (重大更新)
echo.
set /p choice="请选择 (1-3, 默认1): "
if "%choice%"=="" set choice=1

if "%choice%"=="1" (
    set version_type=patch
    echo 选择: 补丁版本构建
) else if "%choice%"=="2" (
    set version_type=minor
    echo 选择: 次版本构建
) else if "%choice%"=="3" (
    set version_type=major
    echo 选择: 主版本构建
) else (
    echo 无效选择，使用默认补丁版本
    set version_type=patch
)

echo.
echo Starting release build...
echo.

:: Call Dart script for building
dart scripts\release_build.dart %version_type%

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Release build completed!
    echo.
    
    :: Automatically open APK folder
    echo Opening APK folder...
    explorer build\app\outputs\flutter-apk
) else (
    echo.
    echo Release build failed!
    echo Please check error messages above
)

echo.
echo Script execution completed!