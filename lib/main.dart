import 'package:flutter/material.dart';
import 'package:agripal/screens/splash_screens.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agripal/core/constants/app_colors.dart'; // ✅ لازم يكون هنا في الأول

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AgripalApp());
}

class AgripalApp extends StatelessWidget {
  const AgripalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agripal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
      ),
      home: const SplashScreens(),
    );
  }
}
