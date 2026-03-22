import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:agripal/core/constants/app_colors.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  List<Map<String, dynamic>> _conversations = [];
  int _currentConversationIndex = -1;
  bool _isLoading = true; // ✅ loading حقيقي

  String _allArticlesText = '';

  User? _currentUser;
  SharedPreferences? _prefs;
  String _storageKey = 'conversations_temp';

  // ── Animation controllers ──────────────────────────────────────────────────
  late AnimationController _typingAnimController;
  late AnimationController _sendBtnController;
  late Animation<double> _sendBtnScale;
  bool _isBotTyping = false;

  @override
  void initState() {
    super.initState();
    _loadArticles();
    _initChatStorage();

    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _sendBtnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _sendBtnScale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _sendBtnController, curve: Curves.easeInOut),
    );
  }

  // ────────────────────────────────── STORAGE (SharedPreferences) ─────────────

  Future<void> _initChatStorage() async {
    try {
      _currentUser = FirebaseAuth.instance.currentUser;
      _storageKey = _currentUser != null
          ? 'conversations_\${_currentUser!.uid}'
          : 'conversations_temp';
      _prefs = await SharedPreferences.getInstance();
      _loadConversations();
    } catch (e) {
      debugPrint('❌ خطأ في التخزين: $e');
      setState(() { _isLoading = false; });
      _createNewConversation();
    }
  }

  void _loadConversations() {
    try {
      final raw = _prefs?.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        setState(() { _isLoading = false; });
        _createNewConversation();
        return;
      }
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final loaded = decoded.map((item) {
        final conv = Map<String, dynamic>.from(item as Map);
        conv['messages'] = (conv['messages'] as List)
            .map((m) => Map<String, dynamic>.from(m as Map))
            .toList();
        return conv;
      }).toList();

      loaded.sort((a, b) {
        final aTime = (a['lastUpdated'] ?? 0) as int;
        final bTime = (b['lastUpdated'] ?? 0) as int;
        return bTime.compareTo(aTime);
      });

      if (loaded.isEmpty) {
        setState(() { _isLoading = false; });
        _createNewConversation();
      } else {
        setState(() {
          _conversations = loaded;
          _currentConversationIndex = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('خطأ في تحميل المحادثات: $e');
      setState(() { _isLoading = false; });
      _createNewConversation();
    }
  }

  // ✅ حفظ فوري sync — SharedPreferences.setString سريع جداً
  void _saveConversations() {
    try {
      if (_prefs == null) return;
      final data = _conversations.map((conv) => {
        'id': conv['id'],
        'title': conv['title'],
        'lastUpdated': conv['lastUpdated'],
        'messages': (conv['messages'] as List)
            .map((m) => {'role': m['role'], 'message': m['message']})
            .toList(),
      }).toList();
      // setString في SharedPreferences هو sync في الذاكرة — يكتب للقرص في الخلفية تلقائياً
      _prefs!.setString(_storageKey, jsonEncode(data));
    } catch (e) {
      debugPrint('خطأ في حفظ المحادثات: $e');
    }
  }

  Future<void> _createNewConversation() async {
    final newConversation = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': 'محادثة جديدة ${_conversations.length + 1}',
      'messages': [
        {
          'role': 'bot',
          'message': 'مرحبا بك في المستشار الفلاحي! كيف يمكنني مساعدتك اليوم؟'
        }
      ],
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };
    setState(() {
      _conversations.insert(0, newConversation);
      _currentConversationIndex = 0;
    });
    _saveConversations();
    _scrollToBottom();
  }

  Future<void> _deleteConversation(int index) async {
    setState(() {
      _conversations.removeAt(index);
      if (_conversations.isEmpty) {
        _createNewConversation();
      } else {
        _currentConversationIndex = 0;
      }
    });
    _saveConversations();
  }

  void _switchConversation(int index) {
    setState(() {
      _currentConversationIndex = index;
    });
    Navigator.pop(context);
    _scrollToBottom();
  }

  // ────────────────────────────────── ARTICLES ─────────────────────────────────

  Future<void> _loadArticles() async {
    try {
      List<String> fileNames = [
        'irrigation.txt',
        'fertilizers.txt',
        'tomato.txt',
        'general.txt',
      ];
      String combinedText = '';
      for (String fileName in fileNames) {
        String text = await rootBundle
            .loadString('assets/agriculture_articles/$fileName');
        combinedText += '$text\n\n';
      }
      setState(() {
        _allArticlesText = combinedText;
      });
      debugPrint('✅ تم تحميل المقالات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المقالات: $e');
      setState(() {
        _allArticlesText = 'معلومات احتياطية: الري بالتنقيط مفيد للطماطم.';
      });
    }
  }

  String _searchInArticles(String query) {
    if (_allArticlesText.isEmpty) return 'جاري تحميل المعلومات...';
    List<String> keywords =
        query.split(' ').where((w) => w.length > 2).toList();
    if (keywords.isEmpty) return 'السؤال قصير جداً، حاول توضيحه.';
    List<String> paragraphs = _allArticlesText
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();
    Map<int, int> scores = {};
    for (int i = 0; i < paragraphs.length; i++) {
      int score = 0;
      for (String kw in keywords) {
        if (paragraphs[i].contains(kw)) score++;
      }
      if (score > 0) scores[i] = score;
    }
    var sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (sorted.isNotEmpty) {
      String result = '';
      for (int i = 0; i < sorted.length && i < 3; i++) {
        result += '• ${paragraphs[sorted[i].key]}\n\n';
      }
      return result.trim();
    } else {
      return 'لم أجد معلومات عن "$query" في قاعدة المعرفة حالياً. حاول سؤال آخر.';
    }
  }

  // ────────────────────────────────── MESSAGING ────────────────────────────────

  void _sendMessage() async {
    if (_questionController.text.trim().isEmpty ||
        _currentConversationIndex == -1) { return; }

    _sendBtnController.forward().then((_) => _sendBtnController.reverse());

    final userMessage = _questionController.text;
    final convIndex = _currentConversationIndex;
    final currentMessages =
        _conversations[convIndex]['messages'] as List;

    setState(() {
      currentMessages.add({'role': 'user', 'message': userMessage});
      _conversations[convIndex]['lastUpdated'] =
          DateTime.now().millisecondsSinceEpoch;
      _isBotTyping = true;
    });
    _questionController.clear();
    _scrollToBottom();

    // نحسب الرد أولاً — بدون أي await يوقف الـ flow
    final String botReply = _searchInArticles(userMessage);

    await Future.delayed(const Duration(milliseconds: 800));

    // تحقق إن الصفحة لا تزال موجودة
    if (!mounted) { return; }
    if (_currentConversationIndex == -1) { return; }

    setState(() {
      _isBotTyping = false;
      currentMessages.add({'role': 'bot', 'message': botReply});
      if (currentMessages.length == 3) {
        _conversations[convIndex]['title'] =
            userMessage.length > 20
                ? '${userMessage.substring(0, 20)}...'
                : userMessage;
      }
      _conversations[convIndex]['lastUpdated'] =
          DateTime.now().millisecondsSinceEpoch;
    });

    _scrollToBottom();
    // الحفظ في الآخر بدون await — ما يوقفش الـ UI
    _saveConversations();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ────────────────────────────────── BUILD ────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F2),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      // ✅ resizeToAvoidBottomInset يرفع الـ body لما الكيبورد يظهر
      resizeToAvoidBottomInset: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildMessageList()),
                _buildInputBar(),
              ],
            ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.eco_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text(
            'المستشار الفلاحي',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_comment_rounded,
                  size: 18, color: Colors.white),
            ),
            onPressed: _createNewConversation,
            tooltip: 'محادثة جديدة',
          ),
        ),
      ],
      // ✅ شريط gradient ملوّن تحت الـ AppBar
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.accent,
                const Color(0xFF81C784),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Drawer ──────────────────────────────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFF4F7F2),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.accent],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(height: 12),
                const Text(
                  'المحادثات السابقة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_conversations.length} محادثة',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final conv = _conversations[index];
                final isSelected = _currentConversationIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3))
                        : null,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isSelected
                          ? AppColors.primary
                          : Colors.grey.withValues(alpha: 0.2),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                    title: Text(
                      conv['title'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color:
                            isSelected ? AppColors.primary : Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _switchConversation(index),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 18),
                      onPressed: () => _deleteConversation(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Message List ─────────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    final messages =
        _conversations[_currentConversationIndex]['messages'] as List;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      itemCount: messages.length + (_isBotTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && _isBotTyping) {
          return _buildTypingIndicator();
        }
        final msg = messages[index];
        return _buildMessageBubble(
          msg['message'],
          msg['role'] == 'user',
        );
      },
    );
  }

  // ── Typing Indicator ─────────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Row(
        children: [
          _botAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimController,
              builder: (_, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase = (_typingAnimController.value + i * 0.33) % 1.0;
                    final y = -4.0 * math.sin(phase * math.pi);
                    return Transform.translate(
                      offset: Offset(0, y),
                      child: Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Message Bubble ────────────────────────────────────────────────────────────

  Widget _buildMessageBubble(String message, bool isUser) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(isUser ? (1 - value) * 30 : (1 - value) * -30, 0),
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              _botAvatar(),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: 0.82),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUser ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? AppColors.primary.withValues(alpha: 0.22)
                          : Colors.black.withValues(alpha: 0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: isUser ? Colors.white : const Color(0xFF2D4A2D),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              _userAvatar(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _botAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.eco_rounded, size: 17, color: Colors.white),
    );
  }

  Widget _userAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.person_rounded, size: 17, color: Colors.white),
    );
  }

  // ── Input Bar ─────────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    // ✅ SafeArea(top: false) يمنع الـ navigation bar من يغطي خانة الكتابة
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4EE),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.25),
                  ),
                ),
                child: TextField(
                  controller: _questionController,
                  focusNode: _inputFocusNode,
                  textDirection: TextDirection.rtl,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF2D4A2D),
                  ),
                  decoration: InputDecoration(
                    hintText: 'اكتب سؤالك هنا...',
                    hintStyle:
                        TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 11,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // ✅ زر الإرسال مع scale animation
            ScaleTransition(
              scale: _sendBtnScale,
              child: GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.accent, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dispose ───────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    // ✅ حفظ أخير قبل الإغلاق
    _saveConversations();
    _questionController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _typingAnimController.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }
}