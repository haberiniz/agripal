import 'package:flutter/material.dart';
import 'package:agripal/core/constants/app_colors.dart';

class ChatbotScreen extends StatelessWidget {
  const ChatbotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعد الذكي'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat, size: 80, color: AppColors.primary),
            SizedBox(height: 20),
            Text(
              'المساعد الذكي',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'قريباً...',
              style: TextStyle(fontSize: 16, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}