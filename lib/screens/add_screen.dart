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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان رئيسي
            const Text(
              'ما الذي تريد إضافته؟',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'اختر نوع الإضافة لتبدأ',
              style: TextStyle(fontSize: 16, color: AppColors.accent),
            ),
            const SizedBox(height: 30),
            // بطاقة الري
            _buildCategoryCard(
              context: context,
              icon: Icons.water_drop,
              title: 'الري',
              description: 'إضافة بيانات الري، مواعيده، كمياته',
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 15),
            // بطاقة الأسمدة
            _buildCategoryCard(
              context: context,
              icon: Icons.agriculture,
              title: 'الأسمدة',
              description: 'إضافة أنواع الأسمدة، كمياتها، تواريخ التسميد',
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 15),
            // بطاقة نوع المحصول
            _buildCategoryCard(
              context: context,
              icon: Icons.eco,
              title: 'نوع المحصول',
              description: 'إضافة المحاصيل، أصنافها، تواريخ الزراعة',
              color: Colors.orange.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          // هنا نضيف التنقل للصفحة المناسبة مستقبلاً
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('سيتم فتح صفحة $title قريباً'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // الأيقونة في دائرة ملونة
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 40,
                  color: color,
                ),
              ),
              const SizedBox(width: 20),
              // العنوان والوصف
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // سهم للتوجيه
              Icon(Icons.arrow_forward_ios, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}