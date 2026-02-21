import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/main.dart';
import 'package:ddd/sw/android/d.dart';

class Search extends StatefulWidget {
  final bool show;
  final TextEditingController controller;
  final Function(String) onFilter;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  const Search({super.key, required this.show, required this.controller, required this.onFilter, required this.onOpen, required this.onClose});
  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  Process? _process;
  Timer? _timer;
  bool _isTracking = false;
  void _toggleTracking() async {
    if (_isTracking) return _stopTracking();
    setState(() => _isTracking = true);
    _process = await D().executeStream('shell');
    _process!.stdout.transform(utf8.decoder).listen((event) {
      final match = RegExp(r'u0 ([^/ \n]+)').firstMatch(event);
      if (match != null && widget.controller.text != match.group(1)) {
        widget.controller.value = widget.controller.value.copyWith(
          text: match.group(1),
          selection: TextSelection.collapsed(offset: match.group(1)!.length),
        );
        widget.onFilter(match.group(1)!);
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _process?.stdin.writeln("dumpsys window | grep mCurrentFocus"));
  }

  void _stopTracking() {
    _timer?.cancel();
    _process?.kill();
    setState(() => _isTracking = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _process?.kill();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (widget.show) {
      return Container(
        width: 360,
        height: 40,
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(21)),
        child: TextField(
          controller: widget.controller,
          textAlignVertical: TextAlignVertical.center,
          style: kText(context),
          onChanged: (value) {
            if (FocusManager.instance.primaryFocus?.hasFocus ?? false) if (_isTracking) _stopTracking();
            widget.onFilter(value);
            setState(() {});
          },
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            prefixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {
                    if (_isTracking) _stopTracking();
                    widget.onClose();
                  },
                  icon: Icon(Symbols.search_rounded, color: colorScheme.primary),
                ),
                if (widget.controller.text.isEmpty || _isTracking)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: _toggleTracking,
                    icon: Icon(Symbols.directions_run_rounded, color: _isTracking ? colorScheme.tertiary : colorScheme.outline, size: 20),
                  ),
              ],
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      widget.controller.clear();
                      widget.onFilter('');
                      setState(() {});
                    },
                    icon: Icon(Symbols.close_rounded, color: colorScheme.outline, size: 18),
                  )
                : null,
          ),
        ),
      );
    }
    return IconButton(
      onPressed: widget.onOpen,
      icon: Icon(Symbols.search_rounded, color: colorScheme.outline),
    );
  }
}
