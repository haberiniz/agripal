import 'package:flutter/material.dart';
import 'package:agripal/core/constants/app_colors.dart'; // تأكد أن المسار صحيح

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'bot',
      'message': 'مرحبا بك في المستشار الفلاحي! كيف يمكنني مساعدتك اليوم؟'
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المستشار الفلاحي'),
        backgroundColor: AppColors.primary, // نفس لون الـ AppBar في HomeScreen
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(
                  message['message']!,
                  message['role']! == 'user',
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSoft.withOpacity(0.3), // خلفية ناعمة
              border: Border(
                top: BorderSide(color: AppColors.accent.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'اكتب سؤالك هنا...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _sendMessage,
                  backgroundColor: AppColors.primary, // نفس اللون الأساسي
                  mini: true,
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.accent.withOpacity(0.2),
              child: Icon(Icons.person, size: 18, color: AppColors.accent),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.backgroundSoft,
                borderRadius: BorderRadius.circular(15).copyWith(
                  bottomLeft: isUser ? const Radius.circular(15) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(15),
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: isUser ? Colors.white : AppColors.accent,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  void _sendMessage() {
    if (_questionController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'message': _questionController.text,
      });
    });

    String userQuestion = _questionController.text;
    _questionController.clear();

    // رد مؤقت (نفس الشي)
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _messages.add({
          'role': 'bot',
          'message': 'شكراً على سؤالك: "$userQuestion"\nهذا رد مؤقت. سنضيف المنطق الحقيقي لاحقاً.',
        });
      });
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }
}