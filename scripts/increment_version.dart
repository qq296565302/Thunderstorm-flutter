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