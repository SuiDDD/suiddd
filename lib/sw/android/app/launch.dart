import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class Launch extends StatelessWidget {
  final String? package;
  final Future<void> Function(List<String>) adb;
  const Launch({super.key, this.package, required this.adb});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: package == null ? null : () => adb(['shell', 'monkey', '-p', package!, '-c', 'android.intent.category.LAUNCHER', '1']),
      icon: Icon(Symbols.power_settings_new_rounded, color: package != null ? colorScheme.primary : colorScheme.outline),
    );
  }
}
