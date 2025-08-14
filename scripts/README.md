# 🚀 Flutter 自动化构建神器：告别手动打包的烦恼！

在 Flutter 开发中，频繁的打包、版本号管理和发布流程是不可避免的。为了简化这些重复性工作，我们创建了一套自动化构建脚本。这篇博文将详细介绍这些脚本的功能、使用方法以及它们背后的源码实现。

## 核心痛点：繁琐的手动构建流程

一个标准的 Flutter 发布流程通常包含以下步骤：

1.  **更新版本号**：手动修改 `pubspec.yaml` 文件中的版本号。
2.  **清理项目**：运行 `flutter clean` 清除旧的构建缓存。
3.  **获取依赖**：运行 `flutter pub get` 确保依赖最新。
4.  **构建应用**：运行 `flutter build apk --release` 或其他打包命令。
5.  **找到产物**：在 `build` 文件夹中找到生成的 APK 或其他产物。

这个过程不仅耗时，而且容易出错。我们的自动化脚本旨在解决这些问题。

## 脚本家族概览

我们的脚本库包含以下几个核心文件：

-   `increment_version.dart`：独立的版本号递增工具。
-   `release_build.dart`：核心发布构建逻辑，由PowerShell脚本调用。
-   `release_build_fixed.ps1`：Windows PowerShell 封装脚本，提供交互式体验，解决了编码问题。

## 一、智能版本号管理 (`increment_version.dart`)

这是所有自动化流程的基础。它允许你通过命令行参数快速增加版本号。

### 功能

-   支持 `test`、`major`、`minor`、`patch` 和 `build` 五种类型的版本号递增。
-   `test` 版本：仅递增build号，保持主版本号不变，用于测试打包，与发布版本分开管理。
-   自动读取、修改并写回 `pubspec.yaml` 文件。
-   递增 `major`、`minor` 或 `patch` 时，会自动重置后续的版本号和构建号（例如，增加 `minor` 会将 `patch` 重置为 0，`build` 重置为 1）。

### 使用方法

```bash
# 增加测试版本号（仅递增build号，用于测试）
dart scripts/increment_version.dart test

# 增加构建号 (默认)
dart scripts/increment_version.dart build

# 增加补丁版本号
dart scripts/increment_version.dart patch

# 增加次版本号
dart scripts/increment_version.dart minor

# 增加主版本号
dart scripts/increment_version.dart major
```

### 源码解析

```dart:d:\KaKaRoot\Flutter_Thunderstorm\scripts\increment_version.dart
#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// 自动增加Flutter项目版本号的脚本
/// 使用方法：dart scripts/increment_version.dart [test|major|minor|patch|build]
/// test: 测试版本，只递增build号，与发布版本分开
void main(List<String> args) async {
  // 强制设置输出编码为UTF-8，解决Windows下乱码问题
  stdout.encoding = utf8;
  final pubspecFile = File('pubspec.yaml');
  
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml file not found');
    exit(1);
  }

  // 读取pubspec.yaml内容
  final content = await pubspecFile.readAsString();
  final lines = content.split('\n');
  
  // 查找版本行
  int versionLineIndex = -1;
  String currentVersionLine = '';
  
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('version:')) {
      versionLineIndex = i;
      currentVersionLine = lines[i];
      break;
    }
  }
  
  if (versionLineIndex == -1) {
    print('Error: Version information not found in pubspec.yaml');
    exit(1);
  }
  
  // 解析当前版本号
  final versionMatch = RegExp(r'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)').firstMatch(currentVersionLine);
  
  if (versionMatch == null) {
    print('Error: Version format incorrect, should be major.minor.patch+build');
    exit(1);
  }
  
  int major = int.parse(versionMatch.group(1)!);
  int minor = int.parse(versionMatch.group(2)!);
  int patch = int.parse(versionMatch.group(3)!);
  int build = int.parse(versionMatch.group(4)!);
  
  print('Current version: $major.$minor.$patch+$build');
  
  // 根据参数决定增加哪个版本号
  String incrementType = args.isNotEmpty ? args[0].toLowerCase() : 'build';
  
  switch (incrementType) {
    case 'major':
      major++;
      minor = 0;
      patch = 0;
      build = 1;
      break;
    case 'minor':
      minor++;
      patch = 0;
      build = 1;
      break;
    case 'patch':
      patch++;
      build = 1;
      break;
    case 'test':
      // 测试版本只递增build号，保持主版本号不变
      build++;
      break;
    case 'build':
    default:
      build++;
      break;
  }
  
  final newVersion = '$major.$minor.$patch+$build';
  print('New version: $newVersion');
  
  // 更新版本行
  lines[versionLineIndex] = 'version: $newVersion';
  
  // 写回文件
  await pubspecFile.writeAsString(lines.join('\n'));
  
  print('Version updated to: $newVersion');
}
```

## 二、核心构建逻辑 (`release_build.dart`)

这个 Dart 脚本是自动化构建的核心，它按顺序执行了完整的构建流程。

### 功能

1.  **调用版本号脚本**：根据传入的参数（`test`, `patch`, `minor`, `major`）调用 `increment_version.dart`。
2.  **执行 Flutter 命令**：依次执行 `flutter clean`、`flutter pub get` 和 `flutter build apk --release`。
3.  **错误处理**：在每一步都检查进程的退出码，如果失败则中止脚本并打印错误信息。
4.  **结果输出**：构建成功后，打印 APK 的路径、大小和修改时间。
5.  **跨平台兼容**：自动检测 `flutter` 或 `flutter.bat` 命令，增强在 Windows 上的兼容性。

### 源码解析

```dart:d:\KaKaRoot\Flutter_Thunderstorm\scripts\release_build.dart
#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// 发布版本一键构建脚本
/// 集成版本号增加、清理、依赖获取和APK构建
/// 使用方法：dart scripts/release_build.dart [test|patch|minor|major]
void main(List<String> args) async {
  // 强制设置输出编码为UTF-8，解决Windows下乱码问题
  stdout.encoding = utf8;
  
  // ... (检测Flutter命令的代码)

  // ... (检查pubspec.yaml和参数的代码)

  try {
    // 步骤1: 增加版本号
    print('Step 1/4: Incrementing version ($versionType)...');
    final versionResult = await Process.run('dart', ['scripts/increment_version.dart', versionType]);
    // ... (错误处理)

    // 步骤2: 清理构建
    print('Step 2/4: Cleaning previous build...');
    final cleanResult = await Process.run(flutterCommand, ['clean'], runInShell: true);
    // ... (错误处理)

    // 步骤3: 获取依赖
    print('Step 3/4: Getting project dependencies...');
    final pubGetResult = await Process.run(flutterCommand, ['pub', 'get'], runInShell: true);
    // ... (错误处理)

    // 步骤4: 构建APK
    print('Step 4/4: Building Release APK...');
    final buildResult = await Process.run(flutterCommand, ['build', 'apk', '--release'], runInShell: true);
    // ... (错误处理)
    
    // 构建成功
    print('Build completed successfully!');
    // ... (显示APK信息)
    
  } catch (e) {
    print('Error: Exception occurred during build process');
    print(e.toString());
    exit(1);
  }
}

// ... (_detectFlutterCommand 函数的实现)
```

## 三、用户交互层：PowerShell 脚本

为了让非技术人员也能方便地使用，我们提供了 PowerShell 封装脚本。

### `release_build_fixed.ps1` (PowerShell)

这是我们的主要构建脚本，通过设置编码解决了 Windows 控制台中常见的中文乱码问题。

#### 功能

-   提供交互式菜单，让用户选择 `test`、`patch`、`minor` 或 `major`。
-   `test` 选项（选项0）：用于测试打包，仅递增build号，与发布版本号分开管理。
-   调用 `release_build.dart` 并传入用户的选择。
-   构建完成后自动打开 APK 所在的文件夹。
-   在执行前会检查 `flutter` 和 `dart` 命令是否存在，提供更友好的错误提示。
-   通过设置UTF-8编码解决了中文乱码问题。

#### 源码解析

```powershell:d:\KaKaRoot\Flutter_Thunderstorm\scripts\release_build_fixed.ps1
# 设置控制台编码为 UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ... (标题和路径检查)

# 显示版本类型选择
Write-Host "Please select release version type:" -ForegroundColor Yellow
Write-Host "0. test   - Test version (for testing, separate from release version)" -ForegroundColor Green
# ... (其他选项)
$choice = Read-Host "Please select (0-3, default 1)"

# ... (根据选择设置 $version_type 变量)

# 执行发布构建脚本
& dart "scripts\release_build.dart" $version_type

if ($LASTEXITCODE -eq 0) {
    # ... (成功信息)
    Write-Host "Opening APK folder..." -ForegroundColor Cyan
    Start-Process "explorer" "build\app\outputs\flutter-apk"
} else {
    Write-Host "Release build failed!" -ForegroundColor Red
}
```

## 四、直接使用 Dart 脚本

除了使用 PowerShell 脚本，你也可以直接调用 Dart 脚本进行构建。

### 使用方法

```bash
# 直接调用发布构建脚本
dart scripts/release_build.dart test    # 测试版本（仅递增build号）
dart scripts/release_build.dart patch   # 补丁版本
dart scripts/release_build.dart minor   # 次版本
dart scripts/release_build.dart major   # 主版本

# 或者单独增加版本号
dart scripts/increment_version.dart test   # 测试版本号（仅递增build号）
dart scripts/increment_version.dart build  # 仅增加构建号
```

## 推荐工作流程

-   **测试打包**：
    -   运行 `scripts/release_build_fixed.ps1` 并选择选项0（test）。
    -   或者直接使用 `dart scripts/release_build.dart test`。
    -   测试版本仅递增build号，不影响发布版本号。
-   **日常开发/QA 测试**：
    -   运行 `dart scripts/increment_version.dart build` 仅增加构建号。
    -   然后手动执行 `flutter clean && flutter pub get && flutter build apk --release`。
-   **正式发布**：
    -   运行 `scripts/release_build_fixed.ps1`（推荐）。
    -   根据发布类型选择 `patch`、`minor` 或 `major`。
    -   或者直接使用 `dart scripts/release_build.dart [patch|minor|major]`。

## 五、编码问题解决方案

在 Windows 环境下，我们遇到了中文乱码问题。为了彻底解决这个问题，我们采用了以下策略：

### 问题原因

-   Windows 控制台默认使用 GBK 编码
-   Dart 脚本输出使用 UTF-8 编码
-   编码不匹配导致中文字符显示为乱码

### 解决方案

1.  **Dart 脚本层面**：
    -   在所有 Dart 脚本的 `main` 函数开头添加 `stdout.encoding = utf8;`
    -   将所有中文提示信息改为英文，避免编码问题

2.  **PowerShell 脚本层面**：
    -   设置 `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8`
    -   添加 `chcp 65001` 命令强制设置控制台代码页为 UTF-8

### 修改后的效果

-   所有输出信息均为英文，避免乱码
-   在任何 Windows 环境下都能正常显示
-   保持了脚本的功能完整性

## 总结

通过将 Dart 的跨平台能力与 PowerShell 脚本相结合，我们创建了一套强大而灵活的自动化构建系统。它不仅减少了手动操作，降低了出错风险，还通过解决编码问题确保了在 Windows 环境下的稳定运行。希望这套脚本能为你的 Flutter 开发流程带来便利。


**Q: PowerShell执行策略限制**
A: 使用 `powershell -ExecutionPolicy Bypass -File scripts/release_build_fixed.ps1`

**Q: Dart命令找不到**
A: 确保Flutter SDK已正确安装并添加到PATH环境变量

**Q: 出现中文乱码**
A: 我们已经将所有输出改为英文并在脚本中设置了正确的编码，应该不会再出现乱码问题。如果仍有问题，请使用 `chcp 65001` 设置终端编码

**Q: Flutter命令找不到**
A: 检查Flutter是否已安装并添加到系统PATH，或使用完整路径运行Flutter命令

**Q: test版本和正式版本有什么区别？**
A: test版本仅递增build号（如1.1.15+1 → 1.1.15+2），主版本号保持不变，用于测试打包；正式版本会根据选择递增major、minor或patch版本号并重置build号为1

**Q: 什么时候使用test版本？**
A: 在需要频繁测试打包但不想影响正式发布版本号时使用，比如内部测试、QA验证等场景