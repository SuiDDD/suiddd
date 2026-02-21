import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ddd/lang/l.dart';
import 'package:ddd/sw/android/d.dart';
import 'package:ddd/sw/android/file/file_pull.dart';
import 'package:ddd/sw/android/file/file_push.dart';
import 'package:ddd/sw/android/file/file_refresh.dart';
import 'package:ddd/sw/android/file/file_create.dart';
import 'package:ddd/sw/android/file/file_rename.dart';
import 'package:ddd/sw/android/file/file_delete.dart';
import 'package:ddd/sw/android/file/file_properties.dart';
import 'package:ddd/sw/android/file/file_panel.dart';

class FileInfo {
  final String name, permissions, date, time;
  final int hardLinks, size;
  final bool isDirectory;
  FileInfo({required this.name, required this.permissions, required this.hardLinks, required this.size, required this.date, required this.time, required this.isDirectory});
}

class AFiles extends StatefulWidget {
  const AFiles({super.key});
  @override
  State<AFiles> createState() => _AFilesState();
}

class _AFilesState extends State<AFiles> {
  final D _ddb = D();
  List<FileInfo> _left = [], _right = [];
  final List<String> _path = ['/sdcard/', '/sdcard/'];
  bool _loaded = false;
  int _activePanel = 0;
  final Set<String> _selectedLeft = {}, _selectedRight = {};
  String _escapeArg(String a) => (a.contains(' ') || a.contains('"') || a.contains("'")) ? "'${a.replaceAll("'", r"'\''")}'" : a;
  Future<ProcessResult> adb(List<String> args) async {
    final cmd = args.map(_escapeArg).join(' ');
    final r = await _ddb.execute(cmd, L.of(context)!);
    return r.startsWith('Error:') ? ProcessResult(1, 0, '', r.substring(6)) : ProcessResult(0, 0, r, '');
  }

  Future<void> loadPanel(int idx, String p) async {
    try {
      var clean = p.trim();
      if (!clean.endsWith('/')) clean = '$clean/';
      final r = await adb(['shell', 'ls', '-la', clean]);
      final list = r.exitCode == 0 ? _parse(r.stdout.toString()) : <FileInfo>[];
      if (!mounted) return;
      setState(() => idx == 0 ? _left = list : _right = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => idx == 0 ? _left = [] : _right = []);
    }
  }

  Future<void> loadAll() async {
    await Future.wait([loadPanel(0, _path[0]), loadPanel(1, _path[1])]);
    if (mounted) setState(() => _loaded = true);
  }

  List<FileInfo> _parse(String out) {
    final list = <FileInfo>[];
    for (var line in out.split('\n').where((l) => l.trim().isNotEmpty && !l.trim().startsWith('total'))) {
      final p = line.split(RegExp(r'\s+'));
      if (p.length < 8) continue;
      final name = p.sublist(7).join(' ').trim();
      if (name == '.' || name == '..' || name.isEmpty) continue;
      list.add(FileInfo(name: name, permissions: p[0], hardLinks: int.tryParse(p[1]) ?? 0, size: int.tryParse(p[4]) ?? 0, date: p.length > 5 ? p[5] : '', time: p.length > 6 ? p[6] : '', isDirectory: p[0].startsWith('d')));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => loadAll());
  }

  @override
  Widget build(BuildContext c) {
    final sel = _activePanel == 0 ? _selectedLeft : _selectedRight;
    final files = _activePanel == 0 ? _left : _right;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilePull(idx: _activePanel, path: _path[_activePanel], selected: sel, adb: adb, onSuccess: () => loadPanel(_activePanel, _path[_activePanel])),
            FilePush(idx: _activePanel, path: _path[_activePanel], adb: adb, onSuccess: () => loadPanel(_activePanel, _path[_activePanel])),
            FileRefresh(onRefresh: loadAll),
            FileCreate(idx: _activePanel, path: _path[_activePanel], adb: adb, onSuccess: () => loadPanel(_activePanel, _path[_activePanel])),
            FileRename(idx: _activePanel, path: _path[_activePanel], selected: sel, adb: adb, onSuccess: () => loadPanel(_activePanel, _path[_activePanel])),
            FileDelete(idx: _activePanel, path: _path[_activePanel], selected: sel, adb: adb, onSuccess: () => loadPanel(_activePanel, _path[_activePanel])),
            FileProperties(idx: _activePanel, path: _path[_activePanel], selected: sel, files: files, adb: adb, onSuccess: () => loadPanel(_activePanel, _path[_activePanel])),
          ],
        ),
      ),
      body: Row(
        children: [
          Expanded(
            child: FilePanel(
              idx: 0,
              path: _path[0],
              files: _left,
              selected: _selectedLeft,
              loaded: _loaded,
              onPathChanged: (p) {
                _path[0] = p;
                loadPanel(0, p);
              },
              onActive: () => setState(() => _activePanel = 0),
              adb: adb,
            ),
          ),
          Container(width: 1, color: Colors.grey[200]),
          Expanded(
            child: FilePanel(
              idx: 1,
              path: _path[1],
              files: _right,
              selected: _selectedRight,
              loaded: _loaded,
              onPathChanged: (p) {
                _path[1] = p;
                loadPanel(1, p);
              },
              onActive: () => setState(() => _activePanel = 1),
              adb: adb,
            ),
          ),
        ],
      ),
    );
  }
}
