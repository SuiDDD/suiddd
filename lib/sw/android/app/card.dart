import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ddd/sw/android/app/service.dart';
import 'package:ddd/lang/l.dart';

class AppInfoCard extends StatefulWidget {
  final AppInfo appInfo;
  final bool selectionMode;
  final List<AppInfo> selected;
  final Function(AppInfo) onTap;
  final Map<String, String> status;
  final String path;
  final L l;
  final Map<String, ImageProvider> imageCache;
  const AppInfoCard({super.key, required this.appInfo, required this.selectionMode, required this.selected, required this.onTap, required this.status, required this.path, required this.l, required this.imageCache});
  @override
  State<AppInfoCard> createState() => _AppInfoCardState();
}

class _AppInfoCardState extends State<AppInfoCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  void _copy(String text, String label) {
    if (widget.selectionMode) return;
    final String content = '$label:$text';
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.l.copied}: $content'),
        behavior: SnackBarBehavior.floating,
        width: 340,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _capsule(String label, String value, Color color, ThemeData theme) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: () => _copy(value, label),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value, ThemeData theme) {
    return InkWell(
      onTap: () => _copy(value, label),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$label: ",
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600),
            ),
            Text(value, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final a = widget.appInfo;
    final iconFile = File('${widget.path}${Platform.pathSeparator}Icons${Platform.pathSeparator}${a.appName}-${a.packageName}.png');
    final isSelected = widget.selected.any((s) => s.packageName == a.packageName);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant.withValues(alpha: 0.2), width: isSelected ? 2 : 1),
      ),
      color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.12) : theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () => widget.onTap(a),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 110,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: widget.imageCache[a.packageName] != null ? Image(image: widget.imageCache[a.packageName]!, fit: BoxFit.contain) : (iconFile.existsSync() ? Image.file(iconFile, fit: BoxFit.contain) : Icon(Icons.android_rounded, size: 36, color: theme.colorScheme.outlineVariant)),
                  ),
                  if (a.systemApp == '1')
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: theme.colorScheme.surfaceContainerLow, width: 1.5),
                        ),
                        child: const Text(
                          "S",
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 280,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => _copy(a.appName, widget.l.apps),
                      child: Text(
                        a.appName,
                        style: theme.textTheme.titleSmall?.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => _copy(a.packageName, widget.l.process_name),
                      child: Text(
                        a.packageName,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(spacing: 6, runSpacing: 4, children: [_capsule(widget.l.version, a.version, theme.colorScheme.primary, theme), _capsule("SDK", a.targetSdk, theme.colorScheme.secondary, theme), _capsule("UID", a.uid, theme.colorScheme.tertiary, theme), _capsule(widget.l.package_size, a.packageSize, theme.colorScheme.onSurfaceVariant, theme)]),
                  ],
                ),
              ),
              const VerticalDivider(width: 32, indent: 8, endIndent: 8, thickness: 1),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoItem(widget.l.apk_path, a.apkPath, theme),
                      const SizedBox(height: 6),
                      _infoItem(widget.l.data_path, a.dataPath, theme),
                      const SizedBox(height: 6),
                      Row(children: [_infoItem(widget.l.first_install, a.firstInstallTime, theme), _infoItem(widget.l.last_update, a.lastUpdateTime, theme)]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
