import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ddd/lang/l.dart';
import 'package:ddd/main.dart';
import 'package:ddd/splash.dart';
import 'aadb.dart';

class D {
  static final _instance = D._internal();
  factory D() => _instance;
  D._internal();
  String? _deviceId;
  String? get deviceId => Platform.isAndroid ? AADB().deviceId : _deviceId;
  set deviceId(String? v) {
    if (Platform.isAndroid)
      AADB().deviceId = v;
    else
      _deviceId = v;
  }

  String get _adbPath => SplashScreen.adbPath!;
  Future<List<String>> listDevices() async {
    if (Platform.isAndroid) return await AADB().listDevices();
    final result = await Process.run(_adbPath, ['devices'], runInShell: true);
    if (result.exitCode != 0) return [];
    final lines = result.stdout.toString().split('\n');
    final List<String> currentDevices = [];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[1] == 'device') currentDevices.add(parts[0]);
    }
    if (currentDevices.isEmpty)
      _deviceId = null;
    else if (_deviceId == null || !currentDevices.contains(_deviceId))
      _deviceId = currentDevices.first;
    return currentDevices;
  }

  Future<bool> connectAndroid(String ip) async {
    if (!Platform.isAndroid) return false;
    return await AADB().connect(ip);
  }

  Future<String> execute(String command, L l) async {
    if (Platform.isAndroid) return await AADB().execute(command);
    if (deviceId == null) return '';
    final result = await Process.run(_adbPath, ['-s', deviceId!, ...command.trim().split(RegExp(r'\s+'))], runInShell: true);
    return result.exitCode == 0 ? (result.stdout.toString().trim().isEmpty ? 'N/A' : result.stdout.toString().trim()) : '';
  }

  Future<dynamic> executeStream(String command) async {
    if (Platform.isAndroid) return AADB().executeStream(command);
    List<String> args = deviceId != null ? ['-s', deviceId!] : [];
    args.addAll(command.trim().split(RegExp(r'\s+')));
    return await Process.start(_adbPath, args, runInShell: true);
  }
}

class DeviceSelector extends StatefulWidget {
  final Function()? onDeviceSelected;
  const DeviceSelector({super.key, this.onDeviceSelected});
  @override
  State<DeviceSelector> createState() => _DeviceSelectorState();
}

class _DeviceSelectorState extends State<DeviceSelector> {
  final _adb = D();
  final _ipController = TextEditingController();
  List<String> _devices = [];
  Process? _tracker;
  bool _connecting = false;
  late L l;
  @override
  void initState() {
    super.initState();
    _fetch();
    if (!Platform.isAndroid) _initTracker();
  }

  @override
  void dispose() {
    _tracker?.kill();
    _ipController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    l = L.of(context)!;
  }

  void _initTracker() async {
    _tracker = await _adb.executeStream('track-devices');
    _tracker?.stdout.transform(utf8.decoder).listen((data) {
      if (mounted) _fetch();
    });
  }

  Future<void> _fetch() async {
    final devices = await _adb.listDevices();
    if (mounted) setState(() => _devices = devices);
  }

  Future<void> _handleConnect() async {
    if (_ipController.text.isEmpty) return;
    setState(() => _connecting = true);
    final ok = await _adb.connectAndroid(_ipController.text.trim());
    if (mounted) {
      setState(() => _connecting = false);
      if (ok) {
        _ipController.clear();
        _fetch();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (Platform.isAndroid)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: InputDecoration(hintText: "192.168.x.x:5555", isDense: true),
                  ),
                ),
                _connecting
                    ? const SizedBox(
                        width: 48,
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                      )
                    : IconButton(icon: const Icon(Icons.add_link), onPressed: _handleConnect),
              ],
            ),
          ),
        if (_devices.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.no_device, style: kText(context).copyWith(color: Colors.red)),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              final isSelected = _adb.deviceId == device;
              return ListTile(
                selected: isSelected,
                dense: true,
                title: Text(
                  device,
                  style: kText(context).copyWith(color: isSelected ? Theme.of(context).colorScheme.primary : null, fontWeight: isSelected ? FontWeight.bold : FontWeight.w300),
                ),
                onTap: () {
                  setState(() => _adb.deviceId = device);
                  widget.onDeviceSelected?.call();
                },
              );
            },
          ),
      ],
    );
  }
}
