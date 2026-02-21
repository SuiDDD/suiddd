import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class SelectAll extends StatelessWidget {
  final bool enabled;
  final bool isAllSelected;
  final VoidCallback onToggle;
  const SelectAll({super.key, required this.enabled, required this.isAllSelected, required this.onToggle});
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: enabled ? onToggle : null,
      icon: Icon(isAllSelected ? Symbols.deselect_rounded : Symbols.select_all_rounded, color: isAllSelected ? colorScheme.primary : colorScheme.outline),
    );
  }
}
