#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// 发布版本一键构建脚本
/// 集成版本号增加、清理、依赖获取和APK构建
/// 使用方法：dart scripts/release_build.dart [patch|minor|major]
void main(List<String> args) async {
  // 检测Flutter命令
  String flutterCommand = await _detectFlutterCommand();
  if (flutterCommand.isEmpty) {
    print('错误: 找不到Flutter命令，请确保Flutter已安装并添加到PATH');
    exit(1);
  }
  print('================================');
  print('    雷雨新闻客户端 发布构建');
  print('================================');
  print('');
  
  // 检查是否在项目根目录
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('错误: 找不到 pubspec.yaml 文件，请在Flutter项目根目录运行此脚本');
    exit(1);
  }

  // 确定版本号增加类型
  String versionType = args.isNotEmpty ? args[0].toLowerCase() : 'patch';
  if (!['patch', 'minor', 'major'].contains(versionType)) {
    print('错误: 版本类型必须是 patch、minor 或 major');
    print('使用方法: dart scripts/release_build.dart [patch|minor|major]');
    exit(1);
  }

  try {
    // 步骤1: 增加版本号
    print('步骤 1/4: 增加版本号 ($versionType)...');
    final versionResult = await Process.run(
      'dart', 
      ['scripts/increment_version.dart', versionType],
      workingDirectory: Directory.current.path,
    );
    
    if (versionResult.exitCode != 0) {
      print('错误: 版本号增加失败');
      print(versionResult.stderr);
      exit(1);
    }
    
    print(versionResult.stdout);
    print('');

    // 步骤2: 清理构建
    print('步骤 2/4: 清理之前的构建...');
    final cleanResult = await Process.run(
      flutterCommand, 
      ['clean'],
      workingDirectory: Directory.current.path,
      runInShell: true,
    );
    
    if (cleanResult.exitCode != 0) {
      print('警告: 清理构建时出现问题');
      print(cleanResult.stderr);
    } else {
      print('清理完成');
    }
    print('');

    // 步骤3: 获取依赖
    print('步骤 3/4: 获取项目依赖...');
    final pubGetResult = await Process.run(
      flutterCommand, 
      ['pub', 'get'],
      workingDirectory: Directory.current.path,
      runInShell: true,
    );
    
    if (pubGetResult.exitCode != 0) {
      print('错误: 获取依赖失败');
      print(pubGetResult.stderr);
      exit(1);
    }
    
    print('依赖获取完成');
    print('');

    // 步骤4: 构建APK
    print('步骤 4/4: 构建Release APK...');
    print('这可能需要几分钟时间，请耐心等待...');
    print('');
    
    final buildResult = await Process.run(
      flutterCommand, 
      ['build', 'apk', '--release'],
      workingDirectory: Directory.current.path,
      runInShell: true,
    );
    
    if (buildResult.exitCode != 0) {
      print('错误: APK构建失败');
      print(buildResult.stderr);
      exit(1);
    }
    
    // 构建成功
    print('');
    print('================================');
    print('        构建成功完成!');
    print('================================');
    print('APK文件位置: build/app/outputs/flutter-apk/app-release.apk');
    
    // 获取APK文件信息
    final apkFile = File('build/app/outputs/flutter-apk/app-release.apk');
    if (apkFile.existsSync()) {
      final fileStat = await apkFile.stat();
      final fileSizeMB = (fileStat.size / (1024 * 1024)).toStringAsFixed(2);
      print('APK文件大小: ${fileSizeMB} MB');
      print('修改时间: ${fileStat.modified}');
    }
    
    print('');
    print('发布构建完成！版本类型: $versionType');
    
  } catch (e) {
    print('错误: 构建过程中发生异常');
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