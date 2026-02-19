import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agripal/screens/splash_screens.dart';
import 'package:agripal/core/constants/app_colors.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'AgriPal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
        ),
      ),
      home: const SplashScreens(),
    );
  }
}
