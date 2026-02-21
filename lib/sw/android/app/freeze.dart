import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/sw/android/app/service.dart';
import 'package:ddd/lang/l.dart';
import 'package:ddd/sw/android/su.dart';

class AppFreezeManager {
  final Future<dynamic> Function(List<String> args) onAdbCommand;
  final Future<dynamic> Function(List<String> args) onStartProcess;
  AppFreezeManager({required this.onAdbCommand, required this.onStartProcess});
  Future<void> _executePm(String cmd, String packageName, String userId, bool useRoot) async {
    if (useRoot) {
      await onAdbCommand(['shell', 'su', '-c', 'pm $cmd${userId == 'all' ? '' : ' --user $userId'} $packageName']);
    } else {
      final args = ['shell', 'pm', cmd];
      if (userId != 'all') args.addAll(['--user', userId]);
      args.add(packageName);
      await onAdbCommand(args);
    }
  }

  Future<void> selectUserForAction(BuildContext context, String packageName) async {
    final p = await onStartProcess(['shell', 'pm', 'list', 'users']);
    final String output = await p.stdout.transform(utf8.decoder).join();
    final List<Map<String, String>> users = [];
    final List<String> lines = output.split('\n');
    final RegExp reg = RegExp(r'UserInfo\{(\d+):(.+?)(?=[:}])');
    for (final String line in lines) {
      if (line.contains('UserInfo{')) {
        final Match? match = reg.firstMatch(line);
        if (match != null) users.add({'id': match.group(1) ?? '0', 'name': match.group(2) ?? 'Unknown'});
      }
    }
    if (!context.mounted) return;
    final l = L.of(context)!;
    final allList = [
      ...users,
      {'id': 'all', 'name': l.all_users},
    ];
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(l.specifyUser),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.spaceEvenly,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: allList.map((u) {
                final isAll = u['id'] == 'all';
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(isAll ? Symbols.group_rounded : Symbols.person_rounded),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showAppStatusDialog(context, packageName, u['id']!);
                      },
                    ),
                    Text(u['name']!, textAlign: TextAlign.center),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showAppStatusDialog(BuildContext context, String packageName, String userId) async {
    final l = L.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        bool useRoot = false, suspendS = true, freezeS = true, hideS = true;
        return StatefulBuilder(
          builder: (BuildContext sbc, StateSetter setDialogState) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('root'),
                    Checkbox(
                      value: useRoot,
                      onChanged: (bool? v) {
                        final newValue = v ?? false;
                        if (newValue) {
                          ASU.pr('shell su -c', context, l, (cmd) async {
                            setDialogState(() => useRoot = newValue);
                          });
                        } else {
                          setDialogState(() => useRoot = newValue);
                        }
                      },
                    ),
                  ],
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_buildActionBtn(suspendS ? Symbols.play_arrow_rounded : Symbols.pause_rounded, suspendS ? l.resume : l.pause, () => setDialogState(() => suspendS = !suspendS)), _buildActionBtn(freezeS ? Symbols.thermostat_rounded : Symbols.ac_unit_rounded, freezeS ? l.unfreeze : l.freeze, () => setDialogState(() => freezeS = !freezeS)), if (useRoot) _buildActionBtn(hideS ? Symbols.visibility_rounded : Symbols.visibility_off_rounded, hideS ? l.unhide : l.hide, () => setDialogState(() => hideS = !hideS))]),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    if (suspendS) {
                      await _executePm('unsuspend', packageName, userId, useRoot);
                    } else {
                      await _executePm('suspend', packageName, userId, useRoot);
                    }
                    if (freezeS) {
                      await _executePm('enable', packageName, userId, useRoot);
                    } else {
                      await _executePm('disable-user', packageName, userId, useRoot);
                    }
                    if (useRoot) {
                      await onAdbCommand(['shell', 'su', '-c', 'pm ${hideS ? 'unhide' : 'hide'} $packageName']);
                    }
                  },
                  child: Text(l.confirm),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onPressed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(icon), onPressed: onPressed),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Future<void> showBatchAppActions(BuildContext context, List<AppInfo> selected, String userId) async {
    final l = L.of(context)!;
    bool useRoot = false;
    Widget batchButton(IconData icon, String text, String cmd, String rootCmd, VoidCallback action) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon),
          onPressed: () {
            Navigator.pop(context);
            if (useRoot) {
              ASU.pr('shell su -c "$rootCmd"', context, l, (c) async {
                for (final app in selected) {
                  await onAdbCommand(['shell', 'su', '-c', '$rootCmd ${app.packageName}']);
                }
              });
            } else {
              action();
            }
          },
        ),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext sbc, StateSetter setDialogState) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('root'),
                  Checkbox(
                    value: useRoot,
                    onChanged: (bool? v) {
                      final newValue = v ?? false;
                      if (newValue) {
                        ASU.pr('shell su -c', context, l, (cmd) async {
                          setDialogState(() => useRoot = newValue);
                        });
                      } else {
                        setDialogState(() => useRoot = newValue);
                      }
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  batchButton(Symbols.pause_rounded, l.pause, 'suspend', 'pm suspend', () {
                    for (final a in selected) {
                      _executePm('suspend', a.packageName, userId, false);
                    }
                  }),
                  batchButton(Symbols.play_arrow_rounded, l.resume, 'unsuspend', 'pm unsuspend', () {
                    for (final a in selected) {
                      _executePm('unsuspend', a.packageName, userId, false);
                    }
                  }),
                  batchButton(Symbols.ac_unit_rounded, l.freeze, 'disable-user', 'pm disable-user', () {
                    for (final a in selected) {
                      _executePm('disable-user', a.packageName, userId, false);
                    }
                  }),
                  batchButton(Symbols.thermostat_rounded, l.unfreeze, 'enable', 'pm enable', () {
                    for (final a in selected) {
                      _executePm('enable', a.packageName, userId, false);
                    }
                  }),
                  if (useRoot) ...[
                    batchButton(Symbols.visibility_off_rounded, l.hide, 'hide', 'pm hide', () {
                      for (final a in selected) {
                        _executePm('hide', a.packageName, userId, true);
                      }
                    }),
                    batchButton(Symbols.visibility_rounded, l.unhide, 'unhide', 'pm unhide', () {
                      for (final a in selected) {
                        _executePm('unhide', a.packageName, userId, true);
                      }
                    }),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
