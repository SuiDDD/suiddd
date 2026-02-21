import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/sw/android/d.dart';
import 'package:ddd/lang/l.dart';

class QuickSettingsTiles extends StatefulWidget {
  const QuickSettingsTiles({super.key, required this.adbClient, required this.l, required this.hasDevices});
  final D adbClient;
  final L l;
  final bool hasDevices;
  @override
  State<QuickSettingsTiles> createState() => _QuickSettingsTilesState();
}

class _QuickSettingsTilesState extends State<QuickSettingsTiles> {
  bool _wifiEnabled = false, _mobileDataEnabled = false, _bluetoothEnabled = false, _autoRotateEnabled = false, _powerSavingEnabled = false, _darkModeEnabled = false;
  String _wifiInfo = 'WLAN', _fullSsid = '', _deviceTime = '--:--', _deviceDate = '----/--/--';
  IconData _currentWifiIcon = Symbols.wifi_rounded, _currentMobileIcon = Symbols.android_cell_4_bar_rounded;
  Timer? _refreshTimer;
  final GlobalKey wifiKey = GlobalKey();
  late final L wl;
  @override
  void initState() {
    super.initState();
    wl = widget.l;
    _refreshStatus();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshStatus());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshStatus() async {
    if (!widget.hasDevices) return;
    final results = await Future.wait([widget.adbClient.execute('shell settings get global wifi_on', wl), widget.adbClient.execute('shell settings get global gsm.sim.state', wl), widget.adbClient.execute('shell settings get global mobile_data', wl), widget.adbClient.execute('shell settings get global bluetooth_on', wl), widget.adbClient.execute('shell settings get system accelerometer_rotation', wl), widget.adbClient.execute('shell settings get global low_power', wl), widget.adbClient.execute('shell settings get secure ui_night_mode', wl), widget.adbClient.execute('shell dumpsys wifi', wl), widget.adbClient.execute('shell date +%H:%M', wl), widget.adbClient.execute('shell date +%Y/%m/%d', wl)]);
    if (!mounted) return;
    setState(() {
      _wifiEnabled = results[0].trim() == '1';
      _currentMobileIcon = results[1].trim().contains('LOADED,LOADED') ? Symbols.android_cell_dual_4_bar_rounded : Symbols.android_cell_4_bar_rounded;
      _mobileDataEnabled = results[2].trim() == '1';
      _bluetoothEnabled = results[3].trim() == '1';
      _autoRotateEnabled = results[4].trim() == '1';
      _powerSavingEnabled = results[5].trim() == '1';
      _darkModeEnabled = results[6].trim() == '2';
      if (_wifiEnabled) {
        final wifiLines = results[7].split('\n');
        for (final line in wifiLines) {
          if (line.contains('mWifiInfo')) {
            final ssidMatch = RegExp(r'SSID: "([^"]*)"').firstMatch(line);
            if (ssidMatch != null) {
              _fullSsid = ssidMatch.group(1) ?? '';
              _wifiInfo = _fullSsid.isEmpty ? wl.wlan : _fullSsid;
              break;
            }
          }
        }
      }
      _deviceTime = results[8].trim();
      _deviceDate = results[9].trim();
    });
  }

  Future<void> _toggleWifi() async {
    await widget.adbClient.execute('shell svc wifi ${_wifiEnabled ? "disable" : "enable"}', wl);
    _refreshStatus();
  }

  Future<void> _toggleMobileData() async {
    await widget.adbClient.execute('shell svc data ${_mobileDataEnabled ? "disable" : "enable"}', wl);
    _refreshStatus();
  }

  Future<void> _toggleBluetooth() async {
    await widget.adbClient.execute('shell svc bluetooth ${_bluetoothEnabled ? "disable" : "enable"}', wl);
    _refreshStatus();
  }

  Future<void> _toggleAutoRotate() async {
    await widget.adbClient.execute('shell settings put system accelerometer_rotation ${_autoRotateEnabled ? 0 : 1}', wl);
    _refreshStatus();
  }

  Future<void> _togglePowerSaving() async {
    await widget.adbClient.execute('shell settings put global low_power ${_powerSavingEnabled ? 0 : 1}', wl);
    _refreshStatus();
  }

  Future<void> _toggleDarkMode() async {
    await widget.adbClient.execute('shell cmd uimode night ${_darkModeEnabled ? "no" : "yes"}', wl);
    _refreshStatus();
  }

  Widget _buildCompactTile(IconData icon, String tooltip, bool enabled, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: enabled ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(icon, size: 18, color: enabled ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _deviceTime,
                style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 42, color: theme.colorScheme.primary),
              ),
              Text(_deviceDate, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Row(mainAxisSize: MainAxisSize.min, children: [_buildCompactTile(_currentWifiIcon, _wifiInfo, _wifiEnabled, _toggleWifi), _buildCompactTile(_currentMobileIcon, wl.mobile_data, _mobileDataEnabled, _toggleMobileData), _buildCompactTile((_bluetoothEnabled ? Symbols.bluetooth_rounded : Symbols.bluetooth_disabled_rounded), wl.bluetooth, _bluetoothEnabled, _toggleBluetooth), _buildCompactTile(Symbols.screen_rotation_alt_rounded, wl.auto_rotate, _autoRotateEnabled, _toggleAutoRotate), _buildCompactTile(Symbols.battery_android_full_rounded, wl.power_saving, _powerSavingEnabled, _togglePowerSaving), _buildCompactTile(Symbols.contrast_rounded, wl.dark_mode, _darkModeEnabled, _toggleDarkMode)]),
        ),
      ],
    );
  }
}
