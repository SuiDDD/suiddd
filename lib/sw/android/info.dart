import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/sw/android/app/main.dart';
import 'package:ddd/sw/android/file/file.dart';
import 'package:ddd/main.dart';
import 'package:ddd/lang/l.dart';
import 'package:ddd/sw/android/d.dart';
import 'package:ddd/sw/android/quickset.dart';

const String as = 'shell';
const String ass = 'su -c';

class AInfo extends StatefulWidget {
  const AInfo({super.key});
  @override
  State<AInfo> createState() => AInfoState();
}

class AInfoState extends State<AInfo> {
  final D _adb = D();
  final List<Map<String, dynamic>> _deviceInfoItems = [];
  late L l;
  List<String> _devices = [];
  StreamSubscription? _deviceSub;
  @override
  void initState() {
    super.initState();
    _initDeviceTracking();
  }

  @override
  void dispose() {
    _deviceSub?.cancel();
    super.dispose();
  }

  void _initDeviceTracking() {
    _fetchDevices();
    _deviceSub = Stream.periodic(const Duration(seconds: 2)).listen((_) => _fetchDevices());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l = L.of(context)!;
    if (_deviceInfoItems.isEmpty) {
      _deviceInfoItems.addAll(
        [
          [l.model, "shell getprop ro.product.brand", "shell getprop ro.product.model"],
          [l.architecture, "shell getprop ro.product.cpu.abi"],
          [l.android, "shell getprop ro.build.version.release", "shell getprop ro.build.version.sdk"],
          [l.vndk, "shell getprop ro.vndk.version"],
          [l.slot, "shell getprop ro.boot.slot_suffix"],
          [l.bl_lock, "shell getprop ro.boot.verifiedbootstate"],
          ["SELinux", "shell getenforce"],
          [l.screen_resolution, "shell wm size"],
          [l.display_density, "shell wm density"],
          [l.security_patch, "shell getprop ro.build.version.security_patch"],
          [l.build_version, "shell getprop ro.build.fingerprint"],
          [l.kernel_version, "shell uname -a"],
        ].map((e) => {"name": e[0], "command": e[1], "sdk_command": e.length > 2 ? e[2] : "", "result": "", "color": Colors.black}).toList(),
      );
    }
  }

  void _clearInfo() {
    for (var item in _deviceInfoItems) {
      item["result"] = "";
      item["color"] = Colors.black;
    }
  }

  Future<void> _fetchDevices() async {
    final List<String> currentDevices = await _adb.listDevices();
    if (!mounted) return;
    if (currentDevices.join(',') != _devices.join(',')) {
      setState(() {
        _devices = currentDevices;
        if (_devices.isEmpty) _clearInfo();
      });
      if (_devices.isNotEmpty) executeCommands();
    }
  }

  Future<void> executeCommands() async {
    if (!mounted || _devices.isEmpty || _adb.deviceId == null) return;
    await Future.wait(
      _deviceInfoItems.map((info) async {
        final cmd = info["command"] as String;
        String res = (await _adb.execute(cmd, l)).trim();
        if (!mounted || _devices.isEmpty || _adb.deviceId == null) return;
        Color color = Colors.black;
        if (res.isEmpty || res.contains('Error')) {
          res = '';
        } else {
          switch (cmd) {
            case "shell getprop ro.product.brand":
              final model = (await _adb.execute(info["sdk_command"], l)).trim();
              res = "$res $model";
              break;
            case "shell getprop ro.build.version.release":
              final sdk = (await _adb.execute(info["sdk_command"], l)).trim();
              res = "$res($sdk)";
              break;
            case "shell getprop ro.boot.slot_suffix":
              res = res.replaceAll('_', '').toUpperCase();
              break;
            case "shell getprop ro.boot.verifiedbootstate":
              color = res == "orange" ? Colors.orange : (res == "green" ? Colors.green : Colors.black);
              res = res == "orange" ? l.unlocked : (res == "green" ? l.locked : res);
              break;
            case "shell getenforce":
              res = res == "Enforcing" ? l.enforcing : (res == "Permissive" ? l.permissive : res);
              break;
            case "shell wm size":
              res = res.split(':').last.trim();
              break;
            case "shell wm density":
              res = res.replaceAll("Physical density: ", l.physical_density).replaceAll("Override density: ", l.override_density);
              break;
            case "shell uname -a":
              res = RegExp(r'Linux\s+\S+\s+(\S+)').firstMatch(res)?.group(1) ?? res;
              break;
          }
        }
        setState(() {
          info["result"] = res;
          info["color"] = color;
        });
      }),
    );
  }

  Widget _deviceInfo() => infoCard(
    ListView.builder(
      shrinkWrap: true,
      itemCount: _deviceInfoItems.length,
      itemBuilder: (context, i) {
        final item = _deviceInfoItems[i];
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 1,
              child: Text(item["name"]!, style: kText(context), overflow: TextOverflow.ellipsis),
            ),
            Flexible(
              flex: 2,
              child: SelectableText(
                item["result"]!,
                style: kText(context).copyWith(color: item["color"]),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        );
      },
    ),
  );
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final tileColor = Theme.of(context).colorScheme.surfaceContainerHigh;
    final textColor = _devices.isEmpty ? Theme.of(context).colorScheme.onSurface.withAlpha(76) : Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Container(
          height: screenHeight / 3,
          margin: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(9)),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                Expanded(child: _deviceInfo()),
                Expanded(
                  child: QuickSettingsTiles(adbClient: _adb, l: l, hasDevices: _devices.isNotEmpty),
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned(
                left: 6,
                top: 6,
                child: _buildTile(
                  icon: Symbols.apps_rounded,
                  text: l.apps,
                  color: textColor,
                  onTap: _devices.isEmpty ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AApps())),
                  tileColor: tileColor,
                ),
              ),
              Positioned(
                left: 102,
                top: 6,
                child: _buildTile(
                  icon: Symbols.folder_rounded,
                  text: l.files,
                  color: textColor,
                  onTap: _devices.isEmpty ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AFiles())),
                  tileColor: tileColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile({required IconData icon, required String text, required Color color, required GestureTapCallback? onTap, required Color tileColor}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(9)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(text, style: kText(context).copyWith(fontSize: 14, color: color)),
        ],
      ),
    ),
  );
}
