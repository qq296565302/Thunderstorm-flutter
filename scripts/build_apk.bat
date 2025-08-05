@echo off
chcp 65001 >nul
echo ================================
echo    雷雨新闻客户端 APK 构建脚本
echo ================================
echo.

:: 检查是否在项目根目录
if not exist "pubspec.yaml" (
    echo 错误: 请在Flutter项目根目录运行此脚本
    pause
    exit /b 1
)

:: 询问用户是否要增加版本号
set /p increment="是否要增加版本号? (y/n, 默认y): "
if "%increment%"=="" set increment=y
if /i "%increment%"=="y" (
    echo.
    echo 选择版本号增加类型:
    echo 1. 构建号 (推荐，用于日常构建)
    echo 2. 补丁版本号 (修复bug)
    echo 3. 次版本号 (新功能)
    echo 4. 主版本号 (重大更新)
    echo.
    set /p choice="请选择 (1-4, 默认1): "
    if "%choice%"=="" set choice=1
    
    if "%choice%"=="1" (
        echo 增加构建号...
        dart scripts\increment_version.dart build
    ) else if "%choice%"=="2" (
        echo 增加补丁版本号...
        dart scripts\increment_version.dart patch
    ) else if "%choice%"=="3" (
        echo 增加次版本号...
        dart scripts\increment_version.dart minor
    ) else if "%choice%"=="4" (
        echo 增加主版本号...
        dart scripts\increment_version.dart major
    ) else (
        echo 无效选择，使用默认构建号增加
        dart scripts\increment_version.dart build
    )
    echo.
)

:: 清理之前的构建
echo 清理之前的构建文件...
flutter clean
echo.

:: 获取依赖
echo 获取项目依赖...
flutter pub get
echo.

:: 构建APK
echo 开始构建APK...
echo 构建类型: Release
echo.
flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ================================
    echo        构建成功完成!
    echo ================================
    echo APK文件位置: build\app\outputs\flutter-apk\app-release.apk
    echo.
    
    :: 询问是否打开APK文件夹
    set /p open="是否打开APK文件夹? (y/n, 默认y): "
    if "%open%"=="" set open=y
    if /i "%open%"=="y" (
        explorer build\app\outputs\flutter-apk
    )
) else (
    echo.
    echo ================================
    echo        构建失败!
    echo ================================
    echo 请检查上面的错误信息
)

echo.
pause