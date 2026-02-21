import 'dart:io';

class Monitor {
  static Future<void> start({required Function(List<String>) onStartProcess, required Function(String) onStatusUpdate}) async {
    final process = await onStartProcess(['shell', 'while true; do cat /storage/emulated/0/Android/data/com.rstplugin/files/apk_extract/1.txt; sleep 0.3; done']);
    process.stdout.listen((data) {
      final content = String.fromCharCodes(data);
      if (content.isNotEmpty) onStatusUpdate(content);
    });
  }

  static Future<void> pull(String name, String pkg, Function(List<String>) onStart) async {
    final exeDir = Directory(Platform.resolvedExecutable).parent.path;
    final dir = '$exeDir${Platform.pathSeparator}data${Platform.pathSeparator}apk_extract';
    if (!Directory(dir).existsSync()) Directory(dir).createSync(recursive: true);
    final apk = '$dir${Platform.pathSeparator}_${pkg}_.apk';
    final p = await onStart(['pull', '/storage/emulated/0/Android/data/com.rstplugin/files/apk_extract/_${pkg}_.apk', apk]);
    p.stderr.listen((d) async {
      if (String.fromCharCodes(d).contains('No such file')) {
        await onStart(['pull', '/storage/emulated/0/Android/data/com.rstplugin/files/apk_extract/_${pkg}_.apks', '${apk}s']);
      }
    });
  }
}
