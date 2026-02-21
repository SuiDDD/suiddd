import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class Uninstall extends StatelessWidget {
  final List<String> selectedPackages;
  final Future<void> Function(List<String>) adb;
  final VoidCallback onSuccess;
  const Uninstall({super.key, required this.selectedPackages, required this.adb, required this.onSuccess});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool enabled = selectedPackages.isNotEmpty;
    return IconButton(
      onPressed: !enabled
          ? null
          : () async {
              for (final p in selectedPackages) {
                await adb(['uninstall', p]);
              }
              onSuccess();
            },
      icon: Icon(Symbols.delete_rounded, color: enabled ? colorScheme.primary : colorScheme.outline),
    );
  }
}
