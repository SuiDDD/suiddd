import 'dart:io';
import 'package:flutter/material.dart';

class AppInfo {
  final String appName, version, packageName, apkPath, packageSize, dataPath, uid, firstInstallTime, lastUpdateTime, targetSdk, systemApp;
  AppInfo({required this.appName, required this.version, required this.packageName, required this.apkPath, required this.packageSize, required this.dataPath, required this.uid, required this.firstInstallTime, required this.lastUpdateTime, required this.targetSdk, required this.systemApp});
}

class Service {
  static final Map<String, ImageProvider> imageCache = {};
  static Future<Map<String, dynamic>> load(Future<dynamic> Function(List<String>) adb) async {
    final startResult = await adb(['shell', 'am', 'start', '-n', 'com.rstplugin/.MainActivity']);
    if (startResult.stdout.toString().contains('Error') || startResult.stderr.toString().contains('Error')) return {'error': 'plugin_missing'};
    await Future.delayed(const Duration(seconds: 1));
    final broadcast = await adb(['shell', 'am', 'broadcast', '-a', 'rstplugin-export_app_info']);
    if (!broadcast.stdout.toString().contains('Broadcast completed')) return {'error': 'broadcast_failed'};
    bool ok = false;
    for (int i = 0; i < 3; i++) {
      final grep = await adb(['shell', 'grep', '-E', '01001111.*01001011', '/storage/emulated/0/Android/data/com.rstplugin/files/app_info/1.txt']);
      if (grep.stdout.toString().trim() == '01001111 01001011') {
        ok = true;
        break;
      }
      if (i < 2) await Future.delayed(const Duration(seconds: 3));
    }
    if (!ok) return {'error': 'verification_failed'};
    final exeDir = Directory(Platform.resolvedExecutable).parent.path;
    final baseDir = '$exeDir${Platform.pathSeparator}data';
    final path = '$baseDir${Platform.pathSeparator}app_info';
    await adb(['pull', '/storage/emulated/0/Android/data/com.rstplugin/files/app_info', baseDir]);
    final f = File('$path${Platform.pathSeparator}1.txt');
    if (!(await f.exists())) return {'error': 'file_missing'};
    final lines = (await f.readAsString()).split('\n').where((l) => l.trim().isNotEmpty).toList();
    final apps = <AppInfo>[];
    for (int i = 0; i + 10 < lines.length; i += 11) {
      final app = AppInfo(appName: lines[i], version: lines[i + 1], packageName: lines[i + 2], packageSize: lines[i + 3], targetSdk: lines[i + 4], uid: lines[i + 5], systemApp: lines[i + 6], apkPath: lines[i + 7], dataPath: lines[i + 8], firstInstallTime: lines[i + 9], lastUpdateTime: lines[i + 10]);
      apps.add(app);
      final icon = File('$path${Platform.pathSeparator}Icons${Platform.pathSeparator}${app.appName}-${app.packageName}.png');
      if (icon.existsSync()) imageCache[app.packageName] = FileImage(icon);
    }
    apps.sort((a, b) => a.appName.compareTo(b.appName));
    return {'path': path, 'apps': apps};
  }
}
