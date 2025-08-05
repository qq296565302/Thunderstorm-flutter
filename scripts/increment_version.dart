#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// 自动增加Flutter项目版本号的脚本
/// 使用方法：dart scripts/increment_version.dart [major|minor|patch|build]
void main(List<String> args) async {
  final pubspecFile = File('pubspec.yaml');
  
  if (!pubspecFile.existsSync()) {
    print('错误: 找不到 pubspec.yaml 文件');
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
    print('错误: 在 pubspec.yaml 中找不到版本信息');
    exit(1);
  }
  
  // 解析当前版本号
  final versionMatch = RegExp(r'version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)').firstMatch(currentVersionLine);
  
  if (versionMatch == null) {
    print('错误: 版本号格式不正确，应为 major.minor.patch+build');
    exit(1);
  }
  
  int major = int.parse(versionMatch.group(1)!);
  int minor = int.parse(versionMatch.group(2)!);
  int patch = int.parse(versionMatch.group(3)!);
  int build = int.parse(versionMatch.group(4)!);
  
  print('当前版本: $major.$minor.$patch+$build');
  
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
    case 'build':
    default:
      build++;
      break;
  }
  
  final newVersion = '$major.$minor.$patch+$build';
  print('新版本: $newVersion');
  
  // 更新版本行
  lines[versionLineIndex] = 'version: $newVersion';
  
  // 写回文件
  await pubspecFile.writeAsString(lines.join('\n'));
  
  print('版本号已更新到: $newVersion');
  print('\n使用说明:');
  print('- dart scripts/increment_version.dart        # 增加构建号 (默认)');
  print('- dart scripts/increment_version.dart build  # 增加构建号');
  print('- dart scripts/increment_version.dart patch  # 增加补丁版本号');
  print('- dart scripts/increment_version.dart minor  # 增加次版本号');
  print('- dart scripts/increment_version.dart major  # 增加主版本号');
}