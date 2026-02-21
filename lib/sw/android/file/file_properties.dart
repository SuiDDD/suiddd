import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/sw/android/file/file.dart';
import 'package:ddd/lang/l.dart';
import 'package:ddd/main.dart';
import 'package:ddd/sw/android/su.dart';

class FileProperties extends StatelessWidget {
  final int idx;
  final String path;
  final Set<String> selected;
  final List<FileInfo> files;
  final Future<dynamic> Function(List<String>) adb;
  final VoidCallback onSuccess;
  const FileProperties({super.key, required this.idx, required this.path, required this.selected, required this.files, required this.adb, required this.onSuccess});
  Future<void> _editPerms(BuildContext context, String p, String cur) async {
    final l = L.of(context)!;
    List<bool> checks = List.filled(9, false);
    bool suid = false, sgid = false, sticky = false;
    for (int i = 1; i < cur.length && i <= 9; i++) {
      if (i % 3 == 1) {
        checks[i - 1] = cur[i] == 'r';
      } else if (i % 3 == 2)
        checks[i - 1] = cur[i] == 'w';
      else {
        checks[i - 1] = {'x', 's', 't'}.contains(cur[i]);
        if (i == 3) {
          suid = {'s', 'S'}.contains(cur[i]);
        } else if (i == 6)
          sgid = {'s', 'S'}.contains(cur[i]);
        else if (i == 9)
          sticky = {'t', 'T'}.contains(cur[i]);
      }
    }
    bool isDir = cur.startsWith('d');
    bool subF = false, subD = false;
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(l.properties),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Table(
                  border: TableBorder.all(color: Colors.grey[300]!),
                  children: [
                    TableRow(
                      children: [
                        const SizedBox(),
                        Center(child: Text(l.read)),
                        Center(child: Text(l.write)),
                        Center(child: Text(l.execute)),
                      ],
                    ),
                    for (int i = 0; i < 3; i++)
                      TableRow(
                        children: [
                          Center(child: Text([l.owner, l.group, l.other][i])),
                          for (int j = 0; j < 3; j++) Checkbox(value: checks[i * 3 + j], onChanged: (v) => setS(() => checks[i * 3 + j] = v ?? false)),
                        ],
                      ),
                    TableRow(
                      children: [
                        Center(child: Text(l.special_permissions)),
                        Checkbox(value: suid, onChanged: (v) => setS(() => suid = v ?? false)),
                        Checkbox(value: sgid, onChanged: (v) => setS(() => sgid = v ?? false)),
                        Checkbox(value: sticky, onChanged: (v) => setS(() => sticky = v ?? false)),
                      ],
                    ),
                  ],
                ),
                if (isDir)
                  Row(
                    children: [
                      Checkbox(value: subF, onChanged: (v) => setS(() => subF = v ?? false)),
                      Text(l.sub_file),
                      Checkbox(value: subD, onChanged: (v) => setS(() => subD = v ?? false)),
                      Text(l.sub_folder),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(context, false), child: Text(l.cancel)),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l.confirm)),
          ],
        ),
      ),
    );
    if (r != true) return;
    int o = (checks[0] ? 4 : 0) + (checks[1] ? 2 : 0) + (checks[2] ? 1 : 0);
    int g = (checks[3] ? 4 : 0) + (checks[4] ? 2 : 0) + (checks[5] ? 1 : 0);
    int t = (checks[6] ? 4 : 0) + (checks[7] ? 2 : 0) + (checks[8] ? 1 : 0);
    int s = (suid ? 4 : 0) + (sgid ? 2 : 0) + (sticky ? 1 : 0);
    final m = '$s$o$g$t';
    if (isDir && (subF || subD)) {
      if (subF && subD) {
        await adb(['shell', 'su', '-c', 'chmod', '-R', m, p]);
      } else if (subF) {
        await adb(['shell', 'su', '-c', 'chmod', m, p]);
        await adb(['shell', 'su', '-c', 'find', p, '-type', 'f', '-exec', 'chmod', m, '{}', '+']);
      } else {
        await adb(['shell', 'su', '-c', 'chmod', m, p]);
        await adb(['shell', 'su', '-c', 'find', p, '-type', 'd', '-exec', 'chmod', m, '{}', '+']);
      }
    } else {
      await adb(['shell', 'su', '-c', 'chmod', m, p]);
    }
    onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Symbols.edit_attributes_rounded),
      onPressed: () async {
        if (selected.isEmpty) return;
        final l = L.of(context)!;
        final nav = Navigator.of(context);
        var base = path.trim().endsWith('/') ? path.trim() : '${path.trim()}/';
        List<Widget> rows = [];
        for (final name in selected) {
          final res = await adb(['shell', 'ls', '-lad', '$base$name']);
          if (res.exitCode != 0 || !context.mounted) continue;
          final p = res.stdout.toString().trim().split(RegExp(r'\s+'));
          if (p.length < 8) continue;
          rows.add(
            Row(
              children: [
                Expanded(
                  child: Text(name, style: kText(context).copyWith(color: Colors.blue)),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => ASU.pr('chmod', context, l, (c) => _editPerms(context, '$base$name', p[0])),
                    child: Text(p[0], style: const TextStyle(decoration: TextDecoration.underline)),
                  ),
                ),
                Expanded(child: Text(p[4])),
                Expanded(child: Text('${p[5]} ${p[6]}')),
              ],
            ),
          );
        }
        if (!context.mounted || rows.isEmpty) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(child: Column(children: rows)),
            ),
            actions: [ElevatedButton(onPressed: () => nav.pop(), child: Text(l.confirm))],
          ),
        );
      },
    );
  }
}
