import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

class Install extends StatelessWidget {
  final Future<void> Function(List<String>) adb;
  const Install({super.key, required this.adb});
  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['apk'], allowMultiple: true);
        if (result != null) {
          for (final p in result.paths.whereType<String>()) {
            await adb(['install', p]);
          }
        }
      },
      icon: const Icon(Symbols.apk_install_rounded),
    );
  }
}
