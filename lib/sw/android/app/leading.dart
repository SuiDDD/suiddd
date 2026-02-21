import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class Leading extends StatelessWidget {
  final bool selectionMode;
  final VoidCallback onClear;
  const Leading({super.key, required this.selectionMode, required this.onClear});
  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: selectionMode ? onClear : () => Navigator.pop(context), icon: Icon(selectionMode ? Symbols.close_rounded : Symbols.arrow_back_rounded));
  }
}
