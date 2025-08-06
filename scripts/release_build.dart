#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// 发布版本一键构建脚本
/// 集成版本号增加、清理、依赖获取和APK构建
/// 使用方法：dart scripts/release_build.dart [patch|minor|major]
void main(List<String> args) async {
  // 强制设置输出编码为UTF-8，解决Windows下乱码问题
  stdout.encoding = utf8;
  // 检测Flutter命令
  String flutterCommand = await _detectFlutterCommand();
  if (flutterCommand.isEmpty) {
    print('Error: Flutter command not found, please ensure Flutter is installed and added to PATH');
    exit(1);
  }
  print('================================');
  print('    Flutter Clinet 发布构建');
  print('================================');
  print('');
  
  // 检查是否在项目根目录
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml file not found, please run this script in Flutter project root directory');
    exit(1);
  }

  // 确定版本号增加类型
  String versionType = args.isNotEmpty ? args[0].toLowerCase() : 'patch';
  if (!['patch', 'minor', 'major'].contains(versionType)) {
    print('Error: Version type must be patch, minor, or major');
    print('Usage: dart scripts/release_build.dart [patch|minor|major]');
    exit(1);
  }

  try {
    // Step 1: Increment version number
    print('Step 1/4: Incrementing version number ($versionType)...');
    final versionResult = await Process.run(
      'dart', 
      ['scripts/increment_version.dart', versionType],
      workingDirectory: Directory.current.path,
    );
    
    if (versionResult.exitCode != 0) {
      print('Error: Failed to increment version number');
      print(versionResult.stderr);
      exit(1);
    }
    
    print(versionResult.stdout);
    print('');

    // Step 2: Clean build
    print('Step 2/4: Cleaning previous build...');
    final cleanResult = await Process.run(
      flutterCommand, 
      ['clean'],
      workingDirectory: Directory.current.path,
      runInShell: true,
    );
    
    if (cleanResult.exitCode != 0) {
      print('Warning: Issue encountered during build cleanup');
      print(cleanResult.stderr);
    } else {
      print('Cleanup completed');
    }
    print('');

    // Step 3: Get dependencies
    print('Step 3/4: Getting project dependencies...');
    final pubGetResult = await Process.run(
      flutterCommand, 
      ['pub', 'get'],
      workingDirectory: Directory.current.path,
      runInShell: true,
    );
    
    if (pubGetResult.exitCode != 0) {
      print('Error: Failed to get dependencies');
      print(pubGetResult.stderr);
      exit(1);
    }
    
    print('Dependencies retrieved successfully');
    print('');

    // Step 4: Build APK
    print('Step 4/4: Building Release APK...');
    print('This may take a few minutes, please be patient...');
    print('');
    
    final buildResult = await Process.run(
      flutterCommand, 
      ['build', 'apk', '--release'],
      workingDirectory: Directory.current.path,
      runInShell: true,
    );
    
    if (buildResult.exitCode != 0) {
      print('Error: APK build failed');
      print(buildResult.stderr);
      exit(1);
    }
    
    // Build successful
    print('');
    print('================================');
    print('        Build completed successfully!');
    print('================================');
    print('APK file location: build/app/outputs/flutter-apk/app-release.apk');
    
    // 获取APK文件信息
    final apkFile = File('build/app/outputs/flutter-apk/app-release.apk');
    if (apkFile.existsSync()) {
      final fileStat = await apkFile.stat();
      final fileSizeMB = (fileStat.size / (1024 * 1024)).toStringAsFixed(2);
      print('APK file size: ${fileSizeMB} MB');
      print('Modified time: ${fileStat.modified}');
    }
    
    print('');
    print('Release build completed! Version type: $versionType');
    
  } catch (e) {
    print('Error: Exception occurred during build process');
    print(e.toString());
    exit(1);
  }
}

/// 检测Flutter命令
/// 在Windows系统中可能需要使用flutter.bat
Future<String> _detectFlutterCommand() async {
  // 尝试不同的Flutter命令
  final commands = ['flutter', 'flutter.bat'];
  
  for (String command in commands) {
    try {
      final result = await Process.run(
        command, 
        ['--version'],
        runInShell: true,
      );
      
      if (result.exitCode == 0) {
        return command;
      }
    } catch (e) {
      // 继续尝试下一个命令
      continue;
    }
  }
  
  return ''; // 没有找到可用的Flutter命令
}