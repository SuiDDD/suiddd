import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/sw/android/d.dart';
import 'package:ddd/lang/l.dart';
import 'package:ddd/sw/android/info.dart';
import 'package:ddd/sw/android/su.dart';
import 'package:ddd/main.dart';

class AReboot extends StatefulWidget {
  final D adbClient;
  final String as;
  final L l;
  const AReboot({super.key, required this.adbClient, required this.as, required this.l});
  @override
  State<AReboot> createState() => _ARebootState();
}

class _ARebootState extends State<AReboot> {
  bool _isRebooting = false;
  String? _currentRebootingCommand;
  late final List<Map<String, List<Map<String, String>>>> _rebootOptions;
  late final L wl;
  @override
  void initState() {
    super.initState();
    wl = widget.l;
    _rebootOptions = [
      {
        wl.hot_reboot: [
          {"command": "$ass am restart", "description": wl.hot_reboot},
        ],
      },
      {
        wl.soft_reboot: [
          {"command": "$ass pkill -f com.android.systemui", "description": wl.soft_reboot},
        ],
      },
      {
        wl.cold_reboot: [
          {"command": "reboot", "description": wl.cold_reboot},
          {"command": "$as reboot", "description": wl.cold_reboot},
          {"command": "$ass setprop sys.powerctl reboot", "description": wl.cold_reboot},
        ],
      },
      {
        wl.hard_reboot: [
          {"command": "$as reboot -f", "description": wl.hard_reboot},
        ],
      },
      {
        wl.to_shutdown: [
          {"command": "$as reboot -p", "description": wl.to_shutdown},
          {"command": "$ass setprop sys.powerctl shutdown", "description": wl.to_shutdown},
        ],
      },
      {
        wl.to_recovery: [
          {"command": "reboot recovery", "description": wl.to_recovery},
          {"command": "$as reboot recovery", "description": wl.to_recovery},
          {"command": "$ass setprop sys.powerctl reboot,recovery", "description": wl.to_recovery},
        ],
      },
      {
        wl.to_bootloader: [
          {"command": "reboot bootloader", "description": wl.to_bootloader},
          {"command": "$as reboot bootloader", "description": wl.to_bootloader},
          {"command": "$ass setprop sys.powerctl reboot,bootloader", "description": wl.to_bootloader},
        ],
      },
      {
        wl.to_daemon: [
          {"command": "reboot fastboot", "description": wl.to_daemon},
          {"command": "$as reboot fastboot", "description": wl.to_daemon},
          {"command": "$ass setprop sys.powerctl reboot,fastboot", "description": wl.to_daemon},
        ],
      },
      {
        wl.to_rescue: [
          {"command": "reboot edl", "description": wl.to_rescue},
          {"command": "$as reboot edl", "description": wl.to_rescue},
          {"command": "$ass setprop sys.powerctl reboot,edl", "description": wl.to_rescue},
        ],
      },
      {
        wl.to_download: [
          {"command": "reboot download", "description": wl.to_download},
          {"command": "$as reboot download", "description": wl.to_download},
          {"command": "$ass setprop sys.powerctl reboot,download", "description": wl.to_download},
        ],
      },
    ];
  }

  Future<void> _executeRebootCommand(BuildContext context, String command) async {
    Navigator.of(context).pop();
    setState(() {
      _isRebooting = true;
      _currentRebootingCommand = command;
    });
    try {
      await ASU.pr(command, context, widget.l, (cmd) async {
        await widget.adbClient.execute(cmd, widget.l);
      });
    } finally {
      setState(() {
        _isRebooting = false;
        _currentRebootingCommand = null;
      });
    }
  }

  void _showRebootOptions(BuildContext context, String title, List<Map<String, String>> commands) {
    if (_isRebooting) return;
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: commands.map((cmd) {
                final command = cmd["command"]!;
                final description = cmd["description"]!;
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 16, right: 24),
                  title: Text(description),
                  subtitle: Text(command, style: TextStyle(color: Colors.grey, fontSize: 9)),
                  onTap: () => _executeRebootCommand(dialogContext, command),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[TextButton(child: Text(wl.cancel), onPressed: () => Navigator.of(dialogContext).pop())],
        );
      },
    );
  }

  Widget _buildRebootOptionButton(String title, List<Map<String, String>> commands, IconData icon) {
    final bool isCurrentRebooting = _isRebooting && commands.any((cmd) => cmd["command"] == _currentRebootingCommand);
    return ElevatedButton.icon(
      onPressed: _isRebooting ? null : () => _showRebootOptions(context, title, commands),
      icon: isCurrentRebooting ? const SizedBox(width: 24, height: 24) : Icon(icon),
      label: Text(title, style: kText(context)),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9), side: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: Colors.transparent,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Wrap(alignment: WrapAlignment.center, spacing: 4, runSpacing: 4, children: _buildRebootOptionButtons()),
  );
  List<Widget> _buildRebootOptionButtons() {
    final List<Map<String, dynamic>> buttonConfigs = [
      {"title": wl.hot_reboot, "index": 0, "icon": Symbols.autorenew_rounded},
      {"title": wl.soft_reboot, "index": 1, "icon": Symbols.refresh_rounded},
      {"title": wl.cold_reboot, "index": 2, "icon": Symbols.restart_alt_rounded},
      {"title": wl.hard_reboot, "index": 3, "icon": Symbols.power_rounded},
      {"title": wl.to_shutdown, "index": 4, "icon": Symbols.power_off_rounded},
      {"title": wl.to_recovery, "index": 5, "icon": Symbols.medical_services_rounded},
      {"title": wl.to_bootloader, "index": 6, "icon": Symbols.looks_one_rounded},
      {"title": wl.to_daemon, "index": 7, "icon": Symbols.security_rounded},
      {"title": wl.to_rescue, "index": 8, "icon": Symbols.emergency_rounded},
      {"title": wl.to_download, "index": 9, "icon": Symbols.download_rounded},
    ];
    return buttonConfigs.map((config) {
      return _buildRebootOptionButton(config["title"] as String, _rebootOptions[config["index"] as int][config["title"] as String]!, config["icon"] as IconData);
    }).toList();
  }
}
