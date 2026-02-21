import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ddd/main.dart';
import 'package:material_symbols_icons/symbols.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.languageNotifier, required this.themeColorNotifier});
  final LanguageNotifier languageNotifier;
  final ThemeColorNotifier themeColorNotifier;
  static String? adbPath;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _log = <String>[];
  final _scrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    _initLogic();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initLogic() async {
    if (Platform.isAndroid) {
      _logAdd('S System: Android ${Platform.operatingSystemVersion}');
      _logAdd('S Engine: NativeADB Initialized');
      SplashScreen.adbPath = 'NativeADB';
      return _goto();
    }
    final prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString('custom_adb_path');
    if (savedPath != null && await _verifyAdb(savedPath)) {
      SplashScreen.adbPath = savedPath;
      return _goto();
    }
    if (await _verifyAdb('adb')) {
      SplashScreen.adbPath = 'adb';
      return _goto();
    }
    _showPathPickerDialog();
  }

  Future<bool> _verifyAdb(String path) async {
    _logAdd('S Checking ADB: $path');
    try {
      final r = await Process.run(path, ['version']);
      if (r.exitCode == 0 && r.stdout.toString().contains('Android Debug Bridge version')) {
        final m = RegExp(r'version (\d+\.\d+\.\d+)').firstMatch(r.stdout.toString());
        _logAdd('S ADB OK: ${m?.group(1) ?? "Detected"}');
        return true;
      }
    } catch (_) {}
    _logAdd('E ADB invalid at: $path');
    return false;
  }

  Future<void> _showPathPickerDialog() async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('ADB Not Found'),
        content: const Text('Please select the ADB executable path manually to continue.'),
        actions: [
          TextButton(
            onPressed: () async {
              String? result = await FilePicker.platform.pickFiles(type: FileType.any).then((res) => res?.files.single.path);
              if (result != null) {
                if (await _verifyAdb(result)) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('custom_adb_path', result);
                  SplashScreen.adbPath = result;
                  if (context.mounted) Navigator.pop(context);
                  _goto();
                } else {
                  _logAdd('E Selected file is not a valid ADB executable');
                }
              }
            },
            child: const Text('Select ADB Path'),
          ),
        ],
      ),
    );
  }

  void _goto() => Future.delayed(const Duration(milliseconds: 500), () {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => DeviceInfo(languageNotifier: widget.languageNotifier, themeColorNotifier: widget.themeColorNotifier),
      ),
    );
  });
  void _logAdd(String m) {
    if (!mounted) return;
    setState(() => _log.add(m));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Widget _icon(String m) {
    final color = m.startsWith('S ') ? Colors.green : (m.startsWith('E ') ? Colors.red : Colors.grey);
    return Icon(Symbols.circle_rounded, size: 9, color: color);
  }

  String _text(String m) => (m.startsWith('S ') || m.startsWith('E ')) ? m.substring(2) : m;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _log
                  .map(
                    (m) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _icon(m),
                        const SizedBox(width: 5),
                        Text(_text(m), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    ),
  );
}
