import 'package:flutter/material.dart';
import 'package:ddd/lang/l.dart';

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
}
