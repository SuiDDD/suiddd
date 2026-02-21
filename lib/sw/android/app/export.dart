import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/sw/android/app/service.dart';
import 'monitor.dart';

class Export extends StatelessWidget {
  final List<AppInfo> selectedApps;
  final Future<dynamic> Function(List<String>) adb;
  final Function(List<String>) onStart;
  final Function(String) onStatusUpdate;
  const Export({super.key, required this.selectedApps, required this.adb, required this.onStart, required this.onStatusUpdate});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool enabled = selectedApps.isNotEmpty;
    return IconButton(
      onPressed: enabled
          ? () async {
              const int chunkSize = 10;
              for (var i = 0; i < selectedApps.length; i += chunkSize) {
                final end = (i + chunkSize < selectedApps.length) ? i + chunkSize : selectedApps.length;
                final chunk = selectedApps.sublist(i, end);
                final pkgs = chunk.map((a) => a.packageName).join(',');
                await adb(['shell', 'am', 'broadcast', '-a', 'rstplugin-export_apk', '--es', 'package', pkgs]);
              }
              Monitor.start(onStartProcess: onStart, onStatusUpdate: onStatusUpdate);
            }
          : null,
      icon: Icon(Symbols.apk_document_rounded, color: enabled ? colorScheme.primary : colorScheme.outline),
    );
  }
}
