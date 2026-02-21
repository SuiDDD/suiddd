import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/lang/l.dart';

class FileDelete extends StatelessWidget {
  final int idx;
  final String path;
  final Set<String> selected;
  final Future<dynamic> Function(List<String>) adb;
  final VoidCallback onSuccess;
  const FileDelete({super.key, required this.idx, required this.path, required this.selected, required this.adb, required this.onSuccess});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Symbols.delete_rounded),
      onPressed: () async {
        if (selected.isEmpty) return;
        final l = L.of(context)!;
        if (await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(l.delete),
                content: Text('${l.delete} ${selected.length} ${l.items}?'),
                actions: [
                  ElevatedButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l.confirm)),
                ],
              ),
            ) !=
            true) {
          return;
        }
        final base = path.trim().endsWith('/') ? path.trim() : '${path.trim()}/';
        for (final name in selected) {
          await adb(['shell', 'rm', '-rf', '$base$name']);
        }
        selected.clear();
        onSuccess();
      },
    );
  }
}
