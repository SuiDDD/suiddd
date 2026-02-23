import 'dart:io';
import 'dart:convert';
import 'package:ddd/lang/l.dart';
import 'package:flutter/material.dart';
import 'package:ddd/sw/android/d.dart';

class AppInfo {
  final String appName, version, packageName, apkPath, packageSize, dataPath, uid, firstInstallTime, lastUpdateTime, targetSdk, systemApp;
  AppInfo({required this.appName, required this.version, required this.packageName, required this.apkPath, required this.packageSize, required this.dataPath, required this.uid, required this.firstInstallTime, required this.lastUpdateTime, required this.targetSdk, required this.systemApp});
}

class Service {
  static final Map<String, ImageProvider> imageCache = {};
  static String? _currentDevice;
  static Future<bool> _setupPortForward(D adb, BuildContext context) async {
    final device = adb.deviceId;
    if (device == null) return false;
    try {
      if (_currentDevice != null && _currentDevice != device) await adb.execute('forward --remove tcp:9999', L.of(context)!);
      await adb.execute('forward tcp:9999 tcp:9999', L.of(context)!);
      _currentDevice = device;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> load(D adb, BuildContext context) async {
    if (!await _setupPortForward(adb, context)) return {'error': 'adb_forward_failed'};
    try {
      final socket = await Socket.connect('127.0.0.1', 9999, timeout: const Duration(seconds: 5));
      socket.write('suiddd-export_app_info|\n');
      await socket.flush();
      final bytes = <int>[];
      await for (final chunk in socket.timeout(const Duration(seconds: 15), onTimeout: (s) => s.close())) {
        bytes.addAll(chunk);
        if (utf8.decode(chunk, allowMalformed: true).contains('DONE')) break;
      }
      socket.destroy();
      final content = utf8.decode(bytes).split('DONE').first.trim();
      if (content.isEmpty) return {'path': '', 'apps': <AppInfo>[]};
      final apps =
          content
              .split('\n\n')
              .map((block) {
                final lines = block.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                return lines.length >= 11 ? AppInfo(appName: lines[0], version: lines[1], packageName: lines[2], packageSize: lines[3], targetSdk: lines[4], uid: lines[5], systemApp: lines[6], apkPath: lines[7], dataPath: lines[8], firstInstallTime: lines[9], lastUpdateTime: lines[10]) : null;
              })
              .whereType<AppInfo>()
              .toList()
            ..sort((a, b) => a.appName.toLowerCase().compareTo(b.appName.toLowerCase()));
      return {'path': '', 'apps': apps};
    } catch (_) {
      return {'error': 'connection_failed'};
    }
  }
}
