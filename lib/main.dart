import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:agripal/screens/splash_screens.dart';
import 'package:agripal/services/smart_recommendation_service.dart';
import 'package:agripal/services/knowledge_service.dart';
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
  
  // تهيئة Firebase
  await Firebase.initializeApp();
  
  // تهيئة Hive للتخزين المحلي
  await Hive.initFlutter();
  
  // تهيئة التواريخ باللغة العربية
  await initializeDateFormatting('ar', null);
  
  // تحميل بيانات البطاطا عند بدء التشغيل
  await SmartRecommendationService.loadPotatoData();
  
  // استرجاع إعدادات الثيم
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
    KnowledgeService.load();
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
        locale: const Locale('ar', 'DZ'),
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: const Color(0xFF7C9473),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF7C9473),
            secondary: Color(0xFFBC9F8B),
          ),
          fontFamily: 'Cairo',
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
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
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1F1F1F),
            elevation: 0,
            centerTitle: true,
          ),
        ),
        themeMode: _getThemeMode(),
        home: const SplashScreens(),
      ),
    );
  }
}