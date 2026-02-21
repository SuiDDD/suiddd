import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ddd/lang/l.dart';
import 'package:ddd/main.dart';

class ASU {
  static Future<bool> checkAndRequestPermission(String command, BuildContext context, L l) async {
    if (!command.startsWith("shell su -c")) return true;
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.permission_request),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l.permission_general_request), const SizedBox(height: 8), Text("${l.permission_kernelsu_hint}\n${l.permission_magisk_hint}")]),
        actions: [
          ElevatedButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l.permission_deny)),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l.permission_allow)),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> pr(String command, BuildContext context, L l, Future<void> Function(String) executeFunction) async {
    if (!await checkAndRequestPermission(command, context, l)) return;
    await executeFunction(command);
  }

  static Future<bool> pluginapp(BuildContext context, {bool verificationFailed = false}) async {
    final l = L.of(context)!;
    Future<bool> showReqDialog() async {
      if (!context.mounted) return false;
      final res = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          title: Text(l.hint),
          content: Text(l.plugin_required),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
            ElevatedButton(onPressed: () => Navigator.pop(c, true), child: Text(l.confirm)),
          ],
        ),
      );
      return res ?? false;
    }

    if (verificationFailed) {
      if (!await showReqDialog()) return false;
    } else {
      try {
        final res = await Process.run('adb', ['shell', 'pm', 'list', 'packages', 'com.rstplugin']);
        if (res.stdout.toString().contains('package:com.rstplugin')) return true;
      } catch (_) {}
      if (!await showReqDialog()) return false;
    }
    try {
      final exeDir = Directory(Platform.resolvedExecutable).parent.path;
      final baseDir = '$exeDir${Platform.pathSeparator}data';
      final dir = Directory(baseDir);
      if (!await dir.exists()) await dir.create(recursive: true);
      final path = '$baseDir${Platform.pathSeparator}RSTPlugin.apk';
      final res = await http.get(Uri.parse('https://gitee.com/kunpeng108333999/RSTOOLBOX/releases/download/deps-1.0.6/RSTPlugin.apk'));
      if (res.statusCode != 200) {
        if (context.mounted) _showError(context, 'Download failed:${res.statusCode}');
        return false;
      }
      await File(path).writeAsBytes(res.bodyBytes);
      if (context.mounted) _showSuccess(context, 'Download completed');
      try {
        final installRes = await Process.run('adb', ['install', path]);
        if (context.mounted) {
          if (installRes.exitCode == 0) {
            _showSuccess(context, 'Installation completed');
            return true;
          }
          _showError(context, 'Installation failed: ${installRes.stderr}');
        }
        return false;
      } catch (e) {
        if (context.mounted) _showError(context, 'Install error: $e');
        return false;
      }
    } catch (e) {
      if (context.mounted) _showError(context, 'Download error: $e');
      return false;
    }
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: kText(context)),
        backgroundColor: Colors.red,
      ),
    );
  }

  static void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: kText(context)),
        backgroundColor: Colors.green,
      ),
    );
  }
}
