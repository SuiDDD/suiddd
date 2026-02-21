import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/sw/android/file/file.dart';
import 'package:ddd/main.dart';

class FilePanel extends StatefulWidget {
  final int idx;
  final String path;
  final List<FileInfo> files;
  final Set<String> selected;
  final bool loaded;
  final Function(String) onPathChanged;
  final VoidCallback onActive;
  final Future<dynamic> Function(List<String>) adb;
  const FilePanel({super.key, required this.idx, required this.path, required this.files, required this.selected, required this.loaded, required this.onPathChanged, required this.onActive, required this.adb});
  @override
  State<FilePanel> createState() => _FilePanelState();
}

class _FilePanelState extends State<FilePanel> {
  bool _isEditing = false;
  final TextEditingController _ctl = TextEditingController();
  String _fmtSize(int s) => s < 1024 ? '$s B' : '${(s / (1024 * 1024)).toStringAsFixed(2)} MB';
  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (d) async {
        for (final f in d.files) {
          var dest = widget.path.trim().endsWith('/') ? widget.path.trim() : '${widget.path.trim()}/';
          await widget.adb(['push', f.path, '$dest${f.name}']);
        }
        widget.onPathChanged(widget.path);
      },
      child: GestureDetector(
        onTapDown: (_) => widget.onActive(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Symbols.arrow_upward_rounded),
                    onPressed: () {
                      var p = widget.path.endsWith('/') ? widget.path.substring(0, widget.path.length - 1) : widget.path;
                      widget.onPathChanged(p.substring(0, p.lastIndexOf('/') + 1));
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _isEditing = true;
                        _ctl.text = widget.path;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.grey[50],
                        child: _isEditing
                            ? TextField(
                                controller: _ctl,
                                onSubmitted: (v) {
                                  setState(() => _isEditing = false);
                                  widget.onPathChanged(v.endsWith('/') ? v : '$v/');
                                },
                              )
                            : Text(widget.path, style: kText(context), maxLines: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.loaded
                  ? ListView.builder(
                      itemCount: widget.files.length,
                      itemBuilder: (context, i) {
                        final f = widget.files[i];
                        final sel = widget.selected.contains(f.name);
                        return ListTile(
                          selected: sel,
                          leading: Icon(f.isDirectory ? Symbols.folder_rounded : Symbols.insert_drive_file_rounded),
                          title: Text(f.name, style: kText(context)),
                          trailing: Text(_fmtSize(f.size)),
                          onTap: () => f.isDirectory ? widget.onPathChanged('${widget.path}${f.name}/') : null,
                          onLongPress: () => setState(() => sel ? widget.selected.remove(f.name) : widget.selected.add(f.name)),
                        );
                      },
                    )
                  : const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }
}
