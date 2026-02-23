import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ddd/lang/l.dart';
import 'package:ddd/main.dart';
import 'package:ddd/sw/android/d.dart';
import 'package:ddd/sw/android/app/card.dart';
import 'package:ddd/sw/android/app/freeze.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'leading.dart';
import 'search.dart';
import 'launch.dart';
import 'uninstall.dart';
import 'export.dart';
import 'install.dart';
import 'select_all.dart';
import 'service.dart';
import 'monitor.dart';

class AApps extends StatefulWidget {
  const AApps({super.key});
  @override
  State<AApps> createState() => _AAppsState();
}

class _AAppsState extends State<AApps> {
  List<AppInfo> _appInfos = [], _filtered = [], _selected = [];
  bool _dataLoaded = false, _selectionMode = false, _showSearchBar = false;
  final Map<String, String> _status = {};
  final Map<String, bool> _pulling = {};
  final _ddbClient = D();
  late AppFreezeManager _freezeManager;
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _freezeManager = AppFreezeManager(onAdbCommand: (args) async => await _adb(args), onStartProcess: (args) => _start(args));
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final res = await Service.load(_ddbClient, context);
    if (!mounted) return;
    if (res.containsKey('error')) {
      final err = res['error'];
      if (err == 'connection_failed') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L.of(context)!.verification_failed, style: kText(context)),
            backgroundColor: Colors.red,
          ),
        );
      }
      if (mounted) setState(() => _dataLoaded = true);
      return;
    }
    setState(() {
      _appInfos = res['apps'];
      _filtered = res['apps'];
      _dataLoaded = true;
      _selected.clear();
    });
  }

  Future<ProcessResult> _adb(List<String> args) async {
    final res = await _ddbClient.execute(args.join(' '), L.of(context)!);
    return res.startsWith('Error:') ? ProcessResult(1, 0, '', res.substring(6)) : ProcessResult(0, 0, res, '');
  }

  Future<Process> _start(List<String> args) async => await _ddbClient.executeStream(args.join(' '));
  void _onStatus(String content) {
    final lines = content.split('\n');
    bool changed = false;
    for (int i = 0; i + 2 < lines.length; i += 3) {
      final pkg = lines[i + 1].trim(), s = lines[i + 2].trim();
      if (_status[pkg] != s) {
        _status[pkg] = s;
        changed = true;
        if (s == '1' && !_pulling.containsKey(pkg)) {
          _pulling[pkg] = true;
          Monitor.pull(lines[i].trim(), pkg, _start);
        }
      }
    }
    if (changed && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: Leading(
          selectionMode: _selectionMode,
          onClear: () => setState(() {
            _selectionMode = false;
            _selected.clear();
          }),
        ),
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Search(
                show: _showSearchBar,
                controller: _searchController,
                onFilter: (q) => setState(() {
                  _filtered = q.isEmpty ? _appInfos : _appInfos.where((a) => a.appName.toLowerCase().contains(q.toLowerCase()) || a.packageName.toLowerCase().contains(q.toLowerCase())).toList();
                }),
                onOpen: () => setState(() => _showSearchBar = true),
                onClose: () => setState(() {
                  _showSearchBar = false;
                  _searchController.clear();
                }),
              ),
              Launch(package: _selected.length == 1 ? _selected.first.packageName : null, adb: _adb),
              IconButton(
                onPressed: _selected.isNotEmpty ? () => _selected.length == 1 ? _freezeManager.selectUserForAction(context, _selected.first.packageName) : _freezeManager.showBatchAppActions(context, _selected, 'all') : null,
                icon: Icon(Symbols.ac_unit_rounded, color: _selected.isNotEmpty ? colorScheme.primary : colorScheme.outline),
              ),
              Uninstall(
                selectedPackages: _selected.map((e) => e.packageName).toList(),
                adb: _adb,
                onSuccess: () {
                  setState(() {
                    _selectionMode = false;
                    _selected.clear();
                  });
                  _refresh();
                },
              ),
              Export(selectedApps: List.from(_selected), adb: _adb, onStart: _start, onStatusUpdate: _onStatus),
              Install(adb: _adb),
              SelectAll(
                enabled: _filtered.isNotEmpty,
                isAllSelected: _selected.length == _filtered.length && _filtered.isNotEmpty,
                onToggle: () => setState(() {
                  if (_selected.length == _filtered.length) {
                    _selected.clear();
                    _selectionMode = false;
                  } else {
                    _selected = List.from(_filtered);
                    _selectionMode = true;
                  }
                }),
              ),
            ],
          ),
        ),
        actions: [const SizedBox(width: 48)],
      ),
      body: _dataLoaded
          ? ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filtered.length,
              separatorBuilder: (c, i) => const SizedBox(height: 6),
              itemBuilder: (c, i) => AppInfoCard(
                appInfo: _filtered[i],
                selectionMode: _selectionMode,
                selected: _selected,
                onTap: (app) => setState(() {
                  final index = _selected.indexWhere((s) => s.packageName == app.packageName);
                  if (index != -1) {
                    _selected.removeAt(index);
                    if (_selected.isEmpty) _selectionMode = false;
                  } else {
                    _selectionMode = true;
                    _selected.add(app);
                  }
                }),
                status: _status,
                l: L.of(context)!,
                imageCache: Service.imageCache,
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
