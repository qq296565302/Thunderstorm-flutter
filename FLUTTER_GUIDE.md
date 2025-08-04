# Flutter 开发指南

本文档介绍如何初始化 Flutter 项目以及常用的 Flutter 开发命令。

## 环境准备

### 1. 安装 Flutter SDK

1. 访问 [Flutter 官网](https://flutter.dev/docs/get-started/install) 下载 Flutter SDK
2. 解压到合适的目录（如 `C:\flutter`）
3. 将 Flutter 的 `bin` 目录添加到系统环境变量 PATH 中
4. 运行 `flutter doctor` 检查环境配置

### 2. 安装开发工具

- **Android Studio**: 用于 Android 开发
- **VS Code**: 轻量级编辑器，安装 Flutter 和 Dart 插件
- **Xcode**: macOS 上用于 iOS 开发

## 项目初始化

### 创建新项目

```bash
# 创建新的 Flutter 项目
flutter create my_app

# 进入项目目录
cd my_app

# 指定包名创建项目
flutter create --org com.example my_app

# 创建指定平台的项目
flutter create --platforms android,ios my_app
```

### 项目结构说明

```
my_app/
├── android/          # Android 平台相关文件
├── ios/              # iOS 平台相关文件
├── lib/              # Dart 源代码目录
│   └── main.dart     # 应用入口文件
├── test/             # 测试文件目录
├── pubspec.yaml      # 项目配置和依赖管理
└── README.md         # 项目说明文档
```

## 常用开发命令

### 项目运行和调试

```bash
# 运行项目（默认调试模式）
flutter run

# 指定设备运行
flutter run -d <device_id>

# 发布模式运行
flutter run --release

# 热重载（在运行时按 'r'）
# 热重启（在运行时按 'R'）

# 查看可用设备
flutter devices

# 启动模拟器
flutter emulators
flutter emulators --launch <emulator_id>
```

### 代码分析和测试

```bash
# 代码静态分析
flutter analyze

# 运行测试
flutter test

# 运行特定测试文件
flutter test test/widget_test.dart

# 代码格式化
flutter format lib/
```

### 依赖管理

```bash
# 获取依赖包
flutter pub get

# 升级依赖包
flutter pub upgrade

# 添加依赖包
flutter pub add <package_name>

# 移除依赖包
flutter pub remove <package_name>

# 查看过期依赖
flutter pub outdated

# 清理缓存
flutter pub cache clean
```

### 构建和发布

```bash
# 构建 APK（Android）
flutter build apk

# 构建 App Bundle（Android）
flutter build appbundle

# 构建 iOS 应用
flutter build ios

# 构建 Web 应用
flutter build web

# 构建 Windows 应用
flutter build windows

# 构建 macOS 应用
flutter build macos

# 构建 Linux 应用
flutter build linux
```

### 清理和重置

```bash
# 清理构建缓存
flutter clean

# 重新获取依赖
flutter clean && flutter pub get

# 升级 Flutter SDK
flutter upgrade

# 检查 Flutter 环境
flutter doctor

# 详细检查环境
flutter doctor -v
```

### 调试和性能分析

```bash
# 启用调试模式
flutter run --debug

# 启用性能分析
flutter run --profile

# 生成性能报告
flutter build apk --analyze-size

# 查看应用大小分析
flutter build apk --target-platform android-arm64 --analyze-size
```

### 国际化相关

```bash
# 生成国际化文件
flutter gen-l10n

# 添加国际化支持
flutter pub add flutter_localizations --sdk=flutter
flutter pub add intl:any
```

## 开发技巧

### 1. 热重载使用
- 在开发过程中，保存文件后按 `r` 进行热重载
- 如果热重载无效，按 `R` 进行热重启
- 按 `q` 退出调试模式

### 2. 调试技巧
- 使用 `print()` 输出调试信息
- 使用 `debugPrint()` 在发布模式下不输出
- 使用 Flutter Inspector 查看 Widget 树
- 使用断点调试

### 3. 性能优化
- 使用 `const` 构造函数减少重建
- 避免在 `build` 方法中创建对象
- 使用 `ListView.builder` 处理长列表
- 合理使用 `setState()`

## 常见问题解决

### 1. 依赖冲突
```bash
flutter pub deps
flutter pub cache clean
flutter clean
flutter pub get
```

### 2. 构建失败
```bash
flutter clean
flutter pub get
flutter doctor
```

### 3. 模拟器问题
```bash
flutter devices
flutter emulators
# 重启 Android Studio 或 Xcode
```

## 有用的资源

- [Flutter 官方文档](https://flutter.dev/docs)
- [Dart 语言文档](https://dart.dev/guides)
- [Flutter 包管理](https://pub.dev/)
- [Flutter 示例](https://github.com/flutter/samples)
- [Flutter 社区](https://flutter.dev/community)

---

**注意**: 本项目使用 Flutter 开发，请确保已正确安装和配置 Flutter 开发环境。