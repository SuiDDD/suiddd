import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

class FilePush extends StatelessWidget {
  final int idx;
  final String path;
  final Future<ProcessResult> Function(List<String>) adb;
  final VoidCallback onSuccess;
  const FilePush({super.key, required this.idx, required this.path, required this.adb, required this.onSuccess});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Symbols.download_rounded),
      onPressed: () async {
        final res = await FilePicker.platform.pickFiles(allowMultiple: true);
        if (res == null) return;
        var destDir = path.trim().endsWith('/') ? path.trim() : '${path.trim()}/';
        for (final p in res.paths.where((p) => p != null)) {
          final name = p!.split(Platform.pathSeparator).last;
          await adb(['push', p, '$destDir$name']);
        }
        onSuccess();
      },
    );
  }
}
