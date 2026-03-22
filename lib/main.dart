import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart'; // ✅ أضفنا هذا
import 'package:agripal/screens/splash_screens.dart';

enum AppTheme { light, dark, system }

class AppThemeProvider extends InheritedWidget {
  final Function(AppTheme) onThemeChanged;
  final AppTheme currentTheme;

  const AppThemeProvider({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
    required super.child,
  });

  static AppThemeProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppThemeProvider>();
  }

  @override
  bool updateShouldNotify(AppThemeProvider old) {
    return currentTheme != old.currentTheme;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter(); // ✅ لازم يكون قبل أي openBox
  final prefs = await SharedPreferences.getInstance();
  final themeIndex = prefs.getInt('themeMode') ?? 0;
  runApp(MyApp(initialTheme: AppTheme.values[themeIndex]));
}

class MyApp extends StatefulWidget {
  final AppTheme initialTheme;
  const MyApp({super.key, required this.initialTheme});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppTheme _currentTheme;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;
  }

  void changeTheme(AppTheme theme) async {
    setState(() => _currentTheme = theme);
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('themeMode', theme.index);
  }

  ThemeMode _getThemeMode() {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeProvider(
      onThemeChanged: changeTheme,
      currentTheme: _currentTheme,
      child: MaterialApp(
        title: 'AgriPal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(0xFF7C9473),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF7C9473),
            secondary: Color(0xFFBC9F8B),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF9CCC8C),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF9CCC8C),
            secondary: Color(0xFFD9B8A4),
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1F1F1F),
          ),
        ),
        themeMode: _getThemeMode(),
        home: const SplashScreens(),
      ),
    );
  }
}