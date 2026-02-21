import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class FileRefresh extends StatelessWidget {
  final VoidCallback onRefresh;
  const FileRefresh({super.key, required this.onRefresh});
  @override
  Widget build(BuildContext context) {
    return IconButton(icon: const Icon(Symbols.refresh_rounded), onPressed: onRefresh);
  }
}
