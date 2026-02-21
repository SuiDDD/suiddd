import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/lang/l.dart';

class FileCreate extends StatelessWidget {
  final int idx;
  final String path;
  final Future<dynamic> Function(List<String>) adb;
  final VoidCallback onSuccess;
  const FileCreate({super.key, required this.idx, required this.path, required this.adb, required this.onSuccess});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Symbols.create_new_folder_rounded),
      onPressed: () async {
        final ctl = TextEditingController();
        bool isDir = true;
        final l = L.of(context)!;
        final r = await showDialog<bool>(
          context: context,
          builder: (_) => StatefulBuilder(
            builder: (ctx, setState) => AlertDialog(
              title: Text(l.create),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctl,
                    decoration: InputDecoration(hintText: l.name),
                  ),
                  Row(
                    children: [
                      Text(l.folder),
                      Switch(value: isDir, onChanged: (v) => setState(() => isDir = v)),
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l.confirm)),
              ],
            ),
          ),
        );
        if (r != true || ctl.text.trim().isEmpty) return;
        var dest = path.trim().endsWith('/') ? path.trim() : '${path.trim()}/';
        final remote = '$dest${ctl.text.trim()}${isDir ? '/' : ''}';
        isDir ? await adb(['shell', 'mkdir', '-p', remote]) : await adb(['shell', 'touch', remote]);
        onSuccess();
      },
    );
  }
}
