# 构建脚本使用说明

## 版本号管理

### 为什么版本号不会自动变化？

Flutter项目的版本号定义在 `pubspec.yaml` 文件中：

```yaml
version: 1.0.0+1
```

格式说明：`主版本号.次版本号.补丁版本号+构建号`

- **主版本号 (major)**: 重大功能更新或不兼容的API变更
- **次版本号 (minor)**: 新功能添加，向后兼容
- **补丁版本号 (patch)**: Bug修复，向后兼容
- **构建号 (build)**: 每次构建的唯一标识

在Android中：
- `versionName` 对应 `1.0.0` (前三个数字)
- `versionCode` 对应 `1` (构建号)

### 自动版本号管理解决方案

我们提供了以下工具来自动管理版本号：

## 1. 版本号增加脚本

### 使用方法

```bash
# 增加构建号 (默认，推荐日常使用)
dart scripts/increment_version.dart
dart scripts/increment_version.dart build

# 增加补丁版本号 (修复bug时使用)
dart scripts/increment_version.dart patch

# 增加次版本号 (添加新功能时使用)
dart scripts/increment_version.dart minor

# 增加主版本号 (重大更新时使用)
dart scripts/increment_version.dart major
```

### 示例

```bash
# 当前版本: 1.0.0+1
dart scripts/increment_version.dart build
# 新版本: 1.0.0+2

dart scripts/increment_version.dart patch
# 新版本: 1.0.1+1

dart scripts/increment_version.dart minor
# 新版本: 1.1.0+1

dart scripts/increment_version.dart major
# 新版本: 2.0.0+1
```

## 2. 一键构建脚本

### Windows批处理版本

双击运行 `scripts/build_apk.bat` 或在命令行中执行：

```cmd
scripts\build_apk.bat
```

### PowerShell版本

```powershell
powershell -ExecutionPolicy Bypass -File scripts/build_apk.ps1
```

### 脚本功能

1. **自动版本号管理**: 构建前可选择增加版本号
2. **清理构建**: 自动执行 `flutter clean`
3. **依赖更新**: 自动执行 `flutter pub get`
4. **APK构建**: 执行 `flutter build apk --release`
5. **结果展示**: 显示构建结果和APK文件位置
6. **文件夹打开**: 可选择自动打开APK文件夹

## 3. 一键发布构建脚本

### 新增功能：集成发布构建命令

我们新增了一键发布构建脚本，将多个步骤集成为一个命令：

#### 使用方法

```bash
# 方法1: 使用批处理脚本（可能出现中文乱码）
scripts\release_build.bat

# 方法2: 使用PowerShell脚本（推荐，解决乱码问题）
scripts\release_build_fixed.ps1

# 方法3: 直接调用Dart脚本
dart scripts/release_build.dart patch   # 补丁版本
dart scripts/release_build.dart minor   # 次版本
dart scripts/release_build.dart major   # 主版本
```

**注意：** 脚本会提示选择版本类型（patch/minor/major），其他步骤自动执行无需用户交互。

#### 解决中文乱码问题

如果在Windows终端中遇到中文乱码，推荐使用以下解决方案：

1. **使用PowerShell脚本**（推荐）：
   ```powershell
   scripts\release_build_fixed.ps1
   ```

2. **设置终端编码**：
   ```cmd
   chcp 65001
   scripts\release_build.bat
   ```

3. **使用英文界面**：
   直接使用Dart脚本避免界面显示问题：
   ```bash
   dart scripts/release_build.dart patch
   ```

#### 脚本功能

一键发布构建脚本会执行以下步骤：
1. **选择版本类型** - 用户选择版本类型（patch/minor/major）
2. **增加版本号** - 根据选择的类型增加版本号
3. **清理构建** - 执行 `flutter clean`
4. **获取依赖** - 执行 `flutter pub get`
5. **构建APK** - 执行 `flutter build apk --release`
6. **显示结果** - 显示APK文件位置和大小信息
7. **自动打开** - 自动打开APK文件夹

## 4. 推荐工作流程

### 日常开发构建

```bash
# 方法1: 使用一键构建脚本
scripts\build_apk.bat

# 方法2: 手动步骤
dart scripts/increment_version.dart build
flutter clean
flutter pub get
flutter build apk --release
```

### 发布版本构建（推荐使用新的一键脚本）

```bash
# 新方法: 一键发布构建（推荐）
scripts\release_build.bat

# 或者直接指定版本类型
dart scripts/release_build.dart patch   # 补丁版本
dart scripts/release_build.dart minor   # 次版本
dart scripts/release_build.dart major   # 主版本

# 传统方法: 手动步骤
dart scripts/increment_version.dart patch  # 或 minor/major
flutter clean
flutter pub get
flutter build apk --release
```

## 5. 版本号策略建议

- **日常测试构建**: 只增加构建号 (`build`)
- **Bug修复**: 增加补丁版本号 (`patch`)
- **新功能**: 增加次版本号 (`minor`)
- **重大更新**: 增加主版本号 (`major`)

## 6. 注意事项

1. **Google Play Store**: 每次上传新APK时，`versionCode`必须比之前的版本大
2. **版本回退**: 如果需要回退版本号，请手动编辑 `pubspec.yaml`
3. **团队协作**: 建议在版本控制中提交版本号变更
4. **自动化CI/CD**: 可以将这些脚本集成到CI/CD流水线中

## 7. 故障排除

### 常见问题

**Q: 脚本提示找不到 pubspec.yaml**
A: 请确保在Flutter项目根目录运行脚本

**Q: 版本号格式错误**
A: 确保 pubspec.yaml 中的版本号格式为 `major.minor.patch+build`

**Q: PowerShell执行策略限制**
A: 使用 `powershell -ExecutionPolicy Bypass -File scripts/build_apk.ps1`

**Q: Dart命令找不到**
A: 确保Flutter SDK已正确安装并添加到PATH环境变量

**Q: 出现中文乱码**
A: 使用PowerShell脚本 `scripts\release_build_fixed.ps1` 或设置终端编码 `chcp 65001`

**Q: Flutter命令找不到**
A: 检查Flutter是否已安装并添加到系统PATH，或使用完整路径运行Flutter命令