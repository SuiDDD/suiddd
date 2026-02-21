import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/lang/l.dart';

class FileRename extends StatelessWidget {
  final int idx;
  final String path;
  final Set<String> selected;
  final Future<dynamic> Function(List<String>) adb;
  final VoidCallback onSuccess;
  const FileRename({super.key, required this.idx, required this.path, required this.selected, required this.adb, required this.onSuccess});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Symbols.drive_file_rename_outline_rounded),
      onPressed: () async {
        if (selected.length != 1) return;
        final oldName = selected.first;
        final ctl = TextEditingController(text: oldName);
        final l = L.of(context)!;
        if (await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(l.rename),
                content: TextField(controller: ctl),
                actions: [
                  ElevatedButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l.confirm)),
                ],
              ),
            ) !=
            true) {
          return;
        }
        final newName = ctl.text.trim();
        if (newName.isEmpty || newName == oldName) return;
        final base = path.trim().endsWith('/') ? path.trim() : '${path.trim()}/';
        await adb(['shell', 'mv', '$base$oldName', '$base$newName']);
        selected.clear();
        onSuccess();
      },
    );
  }
}
