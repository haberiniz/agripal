import 'package:flutter/material.dart';
import 'package:agripal/core/constants/app_colors.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة جديدة'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle, size: 80, color: AppColors.primary),
            SizedBox(height: 20),
            Text(
              'صفحة الإضافة',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'هنا تقدر تضيف حقول جديدة',
              style: TextStyle(fontSize: 16, color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}