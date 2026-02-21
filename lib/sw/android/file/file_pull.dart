import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

class FilePull extends StatelessWidget {
  final int idx;
  final String path;
  final Set<String> selected;
  final Future<ProcessResult> Function(List<String>) adb;
  final VoidCallback onSuccess;
  const FilePull({super.key, required this.idx, required this.path, required this.selected, required this.adb, required this.onSuccess});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Symbols.upload_file_rounded),
      onPressed: () async {
        if (selected.isEmpty) return;
        final localDir = await FilePicker.platform.getDirectoryPath();
        if (localDir == null || localDir.isEmpty) return;
        final base = path.trim().endsWith('/') ? path.trim() : '${path.trim()}/';
        for (final name in selected) {
          final remote = '$base$name';
          final localTarget = Platform.isWindows ? '$localDir\\$name' : '$localDir/$name';
          await adb(['pull', remote, localTarget]);
        }
        selected.clear();
        onSuccess();
      },
    );
  }
}
