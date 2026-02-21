import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ddd/sw/android/d.dart';
import 'package:ddd/sw/android/info.dart';
import 'package:ddd/splash.dart';
import 'package:ddd/set.dart';
import 'package:ddd/lang/l.dart';

class LanguageNotifier extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;
  void setLocale(Locale l) {
    _locale = l;
    notifyListeners();
  }
}

class ThemeColorNotifier extends ChangeNotifier {
  Color? _primaryColor;
  Color? get primaryColor => _primaryColor;
  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp(languageNotifier: LanguageNotifier(), themeColorNotifier: ThemeColorNotifier()));
}

class MyApp extends StatefulWidget {
  final LanguageNotifier languageNotifier;
  final ThemeColorNotifier themeColorNotifier;
  const MyApp({super.key, required this.languageNotifier, required this.themeColorNotifier});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  Color? _primaryColor;
  @override
  void initState() {
    super.initState();
    _load();
    widget.languageNotifier.addListener(_updateLocale);
    widget.themeColorNotifier.addListener(_updateColor);
  }

  @override
  void dispose() {
    widget.languageNotifier.removeListener(_updateLocale);
    widget.themeColorNotifier.removeListener(_updateColor);
    super.dispose();
  }

  void _updateLocale() => setState(() => _locale = widget.languageNotifier.locale);
  void _updateColor() => setState(() => _primaryColor = widget.themeColorNotifier.primaryColor);
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final l = p.getString('languageCode');
    final c = p.getString('countryCode');
    if (l != null) widget.languageNotifier.setLocale(c?.isNotEmpty == true ? Locale(l, c) : Locale(l));
    final colorValue = p.getInt('primaryColor');
    if (colorValue != null) widget.themeColorNotifier.setPrimaryColor(Color(colorValue));
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: _primaryColor ?? Colors.teal),
      scaffoldBackgroundColor: Colors.white,
      fontFamily: Platform.isWindows ? 'Microsoft YaHei' : null,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(),
    ),
    localizationsDelegates: L.localizationsDelegates,
    supportedLocales: L.supportedLocales,
    locale: _locale,
    home: SplashScreen(languageNotifier: widget.languageNotifier, themeColorNotifier: widget.themeColorNotifier),
  );
}

class DeviceInfo extends StatefulWidget {
  const DeviceInfo({super.key, required this.languageNotifier, required this.themeColorNotifier});
  final LanguageNotifier languageNotifier;
  final ThemeColorNotifier themeColorNotifier;
  @override
  State<DeviceInfo> createState() => _DeviceInfoState();
}

class _DeviceInfoState extends State<DeviceInfo> {
  final GlobalKey<AInfoState> _ainfoKey = GlobalKey<AInfoState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  void _onDeviceSelected() {
    _ainfoKey.currentState?.executeCommands();
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    key: _scaffoldKey,
    drawer: AppDrawer(languageNotifier: widget.languageNotifier, themeColorNotifier: widget.themeColorNotifier, onDeviceSelected: _onDeviceSelected),
    body: Stack(
      children: [
        AInfo(key: _ainfoKey),
        Positioned(left: 0, top: 0, bottom: 0, child: SidebarTrigger(scaffoldKey: _scaffoldKey)),
      ],
    ),
  );
}

class AppDrawer extends StatelessWidget {
  final LanguageNotifier languageNotifier;
  final ThemeColorNotifier themeColorNotifier;
  final VoidCallback onDeviceSelected;
  const AppDrawer({super.key, required this.languageNotifier, required this.themeColorNotifier, required this.onDeviceSelected});
  @override
  Widget build(BuildContext context) => Drawer(
    width: 220,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          Expanded(child: DeviceSelector(onDeviceSelected: onDeviceSelected)),
        ],
      ),
    ),
  );
  Widget _buildHeader(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Symbols.adb_rounded, fill: 1, color: Theme.of(context).colorScheme.primary),
        ),
        IconButton(
          icon: const Icon(Symbols.settings_rounded, fill: 0),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SettingsScreen(languageNotifier: languageNotifier, themeColorNotifier: themeColorNotifier),
            ),
          ),
        ),
      ],
    ),
  );
}

class SidebarTrigger extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const SidebarTrigger({super.key, required this.scaffoldKey});
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onDoubleTap: () {
      final state = scaffoldKey.currentState;
      if (state != null && !state.isDrawerOpen) state.openDrawer();
    },
    child: Container(width: 20, color: Colors.transparent),
  );
}

TextStyle kText(BuildContext context) => Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w300);
Card infoCard(Widget c) => Card(
  elevation: 0,
  color: Colors.transparent,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
  child: c,
);
Widget emptyCard() => infoCard(const SizedBox.shrink());
