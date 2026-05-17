import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:agripal/core/constants/app_colors.dart';

const String _kGeminiApiKey = 'AIzaSyD-9Ch1Z9E8DiQRqmuerVIxOhpX7YAzkzM';

final Uri _kGeminiUrl = Uri.parse(
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_kGeminiApiKey',
);
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

  // ── State ──────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _conversations = [];
  int _currentConversationIndex = -1;
  bool _isLoading = true;
  bool _isBotTyping = false;

  // ── RAG Knowledge Base ─────────────────────────────────────────────────────
  Map<String, dynamic> _knowledgeBase = {};

  // ── Firebase ───────────────────────────────────────────────────────────────
  User? _currentUser;
  final _firestore = FirebaseFirestore.instance;

  // ── Animations ─────────────────────────────────────────────────────────────
  late AnimationController _typingAnimController;
  late AnimationController _sendBtnController;
  late Animation<double> _sendBtnScale;

  // ────────────────────────────────── INIT ──────────────────────────────────

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;

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

    _initApp();
  }

  Future<void> _initApp() async {
    await Future.wait([
      _loadKnowledgeBase(),
      _loadConversationsFromFirestore(),
    ]);
  }

  // ────────────────────────────────── RAG: تحميل قاعدة المعرفة ─────────────

  Future<void> _loadKnowledgeBase() async {
    try {
      // ✅ نحمّلو كل ملفات JSON من assets/data
      final List<String> jsonFiles = [
        'assets/data/agriculture_knowledge.json',
        'assets/data/fertilizers_guide.json',
        'assets/data/irrigation_guide.json',
        'assets/data/plant_diseases_guide.json',
        'assets/data/potato_encyclopedia_dz.json',
        'assets/data/soil_and_agriculture_guide.json',
        'assets/data/soil_data.json',
      ];

      final Map<String, dynamic> combined = {};

      for (final path in jsonFiles) {
        try {
          final raw = await rootBundle.loadString(path);
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            combined.addAll(Map<String, dynamic>.from(decoded));
          } else if (decoded is List) {
            final key = path.split('/').last.replaceAll('.json', '');
            combined[key] = decoded;
          }
        } catch (e) {
          debugPrint('⚠️ تعذّر تحميل $path: $e');
        }
      }

      // ✅ نحمّلو كذلك CSV توصيات المحاصيل
      try {
        final csv = await rootBundle.loadString('assets/data/Crop_recommendation.csv');
        combined['crop_recommendation_csv'] = csv;
      } catch (_) {}

      // ✅ نحمّلو treatment.md
      try {
        final md = await rootBundle.loadString('assets/data/treatment.md');
        combined['treatment_guide'] = md;
      } catch (_) {}

      setState(() => _knowledgeBase = combined);
      debugPrint('✅ قاعدة المعرفة جاهزة: ${combined.keys.length} مصدر');
    } catch (e) {
      debugPrint('❌ خطأ في تحميل قاعدة المعرفة: $e');
    }
  }

  // ────────────────────────────────── RAG: البحث الذكي ─────────────────────

  /// يرجع أهم chunks من قاعدة المعرفة حسب سؤال المستخدم
  String _retrieveRelevantContext(String query) {
    final lowerQuery = query.toLowerCase();
    final List<String> relevantChunks = [];

    // كلمات مفتاحية لكل موضوع
    final Map<String, List<String>> topicKeywords = {
      'irrigation': ['ري', 'ماء', 'سقي', 'تنقيط', 'رش', 'irrigation', 'water'],
      'fertilizers': ['سماد', 'أسمدة', 'تسميد', 'نيتروجين', 'فوسفور', 'fertilizer', 'npk'],
      'diseases': ['مرض', 'فطر', 'بكتيريا', 'آفة', 'disease', 'pest', 'علاج', 'رش مبيد'],
      'soil': ['تربة', 'طين', 'رمل', 'soil', 'ph', 'خصوبة'],
      'potato': ['بطاطس', 'بطاطا', 'potato'],
      'tomato': ['طماطم', 'tomato'],
      'wheat': ['قمح', 'شعير', 'حبوب', 'wheat', 'barley'],
      'treatment': ['علاج', 'treatment', 'مبيد', 'دواء'],
      'crop_recommendation': ['توصية', 'محصول', 'crop', 'recommend', 'ماذا أزرع'],
    };

    // نحدد المواضيع المرتبطة بالسؤال
    final Set<String> matchedTopics = {};
    topicKeywords.forEach((topic, keywords) {
      for (final kw in keywords) {
        if (lowerQuery.contains(kw)) {
          matchedTopics.add(topic);
          break;
        }
      }
    });

    // إذا ما لقيناش موضوع محدد، نرجع معلومات عامة
    if (matchedTopics.isEmpty) {
      matchedTopics.addAll(['irrigation', 'fertilizers', 'soil']);
    }

    // نستخرج المعلومات المناسبة من قاعدة المعرفة
    _knowledgeBase.forEach((key, value) {
      bool isRelevant = matchedTopics.any((topic) => key.toLowerCase().contains(topic));

      if (isRelevant) {
        String chunk = '';
        if (value is String) {
          // نأخذ أول 800 حرف فقط
          chunk = value.length > 800 ? value.substring(0, 800) : value;
        } else if (value is Map) {
          chunk = _extractFromMap(value, lowerQuery);
        } else if (value is List) {
          chunk = _extractFromList(value, lowerQuery);
        }

        if (chunk.isNotEmpty) {
          relevantChunks.add('📚 من مصدر [$key]:\n$chunk');
        }
      }
    });

    if (relevantChunks.isEmpty) return '';

    // نحدد بـ 3000 حرف max لكلام الـ context
    final combined = relevantChunks.take(4).join('\n\n---\n\n');
    return combined.length > 3000 ? combined.substring(0, 3000) : combined;
  }

  String _extractFromMap(Map map, String query) {
    final result = StringBuffer();
    map.forEach((k, v) {
      final keyStr = k.toString().toLowerCase();
      if (query.split(' ').any((word) => word.length > 3 && keyStr.contains(word))) {
        result.write('$k: ${v.toString().substring(0, math.min(v.toString().length, 300))}\n');
      }
    });
    if (result.isEmpty) {
      // نرجع أول 3 عناصر عشوائية
      int count = 0;
      map.forEach((k, v) {
        if (count < 3) {
          result.write('$k: ${v.toString().substring(0, math.min(v.toString().length, 150))}\n');
          count++;
        }
      });
    }
    return result.toString();
  }

  String _extractFromList(List list, String query) {
    final result = StringBuffer();
    int count = 0;
    for (final item in list) {
      if (count >= 5) break;
      final str = item.toString();
      if (query.split(' ').any((w) => w.length > 3 && str.toLowerCase().contains(w))) {
        result.write('• ${str.substring(0, math.min(str.length, 200))}\n');
        count++;
      }
    }
    return result.toString();
  }

  // ────────────────────────────────── GEMINI API ────────────────────────────

  Future<String> _askGemini(String userQuestion, List<Map<String, dynamic>> history) async {
    // ✅ نتحققو من المفتاح أول
    if (_kGeminiApiKey.isEmpty) {
      return '⚙️ لم يتم إعداد مفتاح Gemini API بعد.\nافتح chatbot_screen.dart واستبدل YOUR_GEMINI_API_KEY بمفتاحك من aistudio.google.com';
    }
    try {
      // ✅ 1. نجيبو السياق من RAG
      final context = _retrieveRelevantContext(userQuestion);

      // ✅ 2. نبني system prompt زراعي جزائري
      final systemPrompt = '''أنت "المستشار الفلاحي"، خبير زراعي متخصص في الفلاحة الجزائرية.
تتحدث بالعربية الجزائرية الدارجة أو الفصحى البسيطة حسب سؤال المستخدم.
أجوبتك علمية، عملية، ومفيدة للفلاح الجزائري.
استخدم المعلومات من قاعدة المعرفة أدناه عند الإجابة.

🌱 قاعدة المعرفة الزراعية المتاحة:
${context.isNotEmpty ? context : 'استخدم معرفتك العامة بالزراعة الجزائرية.'}

📋 قواعد الإجابة:
- أجب مباشرة وبشكل عملي
- استخدم نقاط واضحة عند الحاجة
- اذكر الكميات والمواعيد تحديداً إن أمكن
- إذا السؤال مش زراعي، وجّه المستخدم برفق
- لا تتجاوز 300 كلمة في الإجابة''';

      // ✅ 3. نبني تاريخ المحادثة (آخر 6 رسائل فقط)
      final List<Map<String, dynamic>> contents = [];

      // نضيفو system كأول رسالة user (Gemini ما يدعمش system role مباشرة)
      contents.add({
        'role': 'user',
        'parts': [{'text': systemPrompt}]
      });
      contents.add({
        'role': 'model',
        'parts': [{'text': 'فهمت، أنا المستشار الفلاحي وجاهز للمساعدة! 🌱'}]
      });

      // نضيفو آخر 6 رسائل من التاريخ
      final recentHistory = history.length > 6 ? history.sublist(history.length - 6) : history;
      for (final msg in recentHistory) {
        if (msg['role'] == 'user') {
          contents.add({'role': 'user', 'parts': [{'text': msg['message']}]});
        } else if (msg['role'] == 'bot') {
          contents.add({'role': 'model', 'parts': [{'text': msg['message']}]});
        }
      }

      // نضيفو السؤال الحالي
      contents.add({'role': 'user', 'parts': [{'text': userQuestion}]});

      // ✅ 4. نرسلو للـ API
     final response = await http.post(
  _kGeminiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
            'topP': 0.9,
          },
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
          ],
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null && text.toString().isNotEmpty) {
          return text.toString().trim();
        }
      }

      debugPrint('❌ Gemini Error ${response.statusCode}: ${response.body}');
      // نبيّنو سبب الخطأ للمستخدم بدل رسالة مبهمة
      if (response.statusCode == 400) return '⚠️ مفتاح Gemini API غلط أو منتهي. تحقق من _kGeminiApiKey في الكود.';
      if (response.statusCode == 429) return '⚠️ تجاوزت الحد المسموح لـ Gemini API. انتظر قليلاً.';
      return _getFallbackResponse(userQuestion);
    } catch (e) {
      debugPrint('❌ خطأ في Gemini: $e');
      return _getFallbackResponse(userQuestion);
    }
  }

  /// رد احتياطي من RAG فقط إذا فشل Gemini
  String _getFallbackResponse(String query) {
    final context = _retrieveRelevantContext(query);
    if (context.isNotEmpty) {
      return '⚠️ الاتصال بالذكاء الاصطناعي فشل مؤقتاً، هذه معلومات من قاعدة بياناتنا:\n\n$context';
    }
    return '⚠️ عذراً، ما نقدرش نتصل بالسيرفر حالياً. تحقق من الاتصال بالإنترنت وجرب مجدداً. 🌱';
  }

  // ────────────────────────────────── FIRESTORE ─────────────────────────────

  CollectionReference? get _conversationsRef {
    if (_currentUser == null) return null;
    return _firestore
        .collection('farmers')
        .doc(_currentUser!.uid)
        .collection('chat_conversations');
  }

  Future<void> _loadConversationsFromFirestore() async {
    try {
      if (_conversationsRef == null) {
        setState(() => _isLoading = false);
        _createNewConversation();
        return;
      }

      final snapshot = await _conversationsRef!
          .orderBy('lastUpdated', descending: true)
          .limit(20)
          .get();

      final loaded = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return <String, dynamic>{
          'id': doc.id,
          'title': data['title'] ?? 'محادثة',
          'lastUpdated': (data['lastUpdated'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
          'messages': <Map<String, dynamic>>[
            ...(data['messages'] as List? ?? [])
                .map((m) => Map<String, dynamic>.from(m as Map))
          ],
        };
      }).toList();

      if (loaded.isEmpty) {
        setState(() => _isLoading = false);
        _createNewConversation();
      } else {
        setState(() {
          _conversations = loaded;
          _currentConversationIndex = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل المحادثات: $e');
      setState(() => _isLoading = false);
      _createNewConversation();
    }
  }

  Future<void> _saveConversationToFirestore(int index) async {
    try {
      if (_conversationsRef == null || index >= _conversations.length) return;
      final conv = _conversations[index];
      final docId = conv['id'] as String;
      final messages = (conv['messages'] as List)
          .map((m) => {'role': m['role'], 'message': m['message']})
          .toList();

      await _conversationsRef!.doc(docId).set({
        'title': conv['title'],
        'lastUpdated': Timestamp.fromMillisecondsSinceEpoch(conv['lastUpdated'] as int),
        'messages': messages,
        'userId': _currentUser?.uid,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ خطأ في حفظ المحادثة: $e');
    }
  }

  // ────────────────────────────────── CONVERSATIONS ─────────────────────────

  Future<void> _createNewConversation() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newConv = <String, dynamic>{
      'id': id,
      'title': 'محادثة جديدة ${_conversations.length + 1}',
      'messages': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'bot',
          'message': 'مرحبا بك في المستشار الفلاحي! 🌿\nاسألني عن أي شيء يخص زراعتك: تربة، ري، أسمدة، أمراض النباتات، أو توصيات المحاصيل.',
        }
      ],
      'lastUpdated': DateTime.now().millisecondsSinceEpoch,
    };

    setState(() {
      _conversations.insert(0, newConv);
      _currentConversationIndex = 0;
    });

    await _saveConversationToFirestore(0);
    _scrollToBottom();
  }

  Future<void> _deleteConversation(int index) async {
    try {
      final id = _conversations[index]['id'] as String;
      await _conversationsRef?.doc(id).delete();
    } catch (e) {
      debugPrint('خطأ في حذف المحادثة: $e');
    }

    setState(() {
      _conversations.removeAt(index);
      if (_conversations.isEmpty) {
        _createNewConversation();
      } else {
        _currentConversationIndex = 0;
      }
    });
  }

  void _switchConversation(int index) {
    setState(() => _currentConversationIndex = index);
    Navigator.pop(context);
    _scrollToBottom();
  }

  // ────────────────────────────────── MESSAGING ─────────────────────────────

  void _sendMessage() async {
    final text = _questionController.text.trim();
    if (text.isEmpty || _currentConversationIndex == -1 || _conversations.isEmpty) return;

    _sendBtnController.forward().then((_) => _sendBtnController.reverse());
    _questionController.clear();

    final userMessage = text;

    // ✅ نستعمل الـ ID مش الـ index باش نتفاداو مشكلة التبديل بين المحادثات
    final convId = _conversations[_currentConversationIndex]['id'] as String;

    // ── Helper آمن: يرجع index من ID ──
    int getIdx() => _conversations.indexWhere((c) => c['id'] == convId);

    // ── Helper آمن: يرجع messages كـ List<Map<String,dynamic>> ──
    List<Map<String, dynamic>> getMsgs() {
      final i = getIdx();
      if (i == -1) return [];
      final raw = _conversations[i]['messages'];
      if (raw is List<Map<String, dynamic>>) return raw;
      final converted = (raw as List)
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();
      _conversations[i]['messages'] = converted;
      return converted;
    }

    // ✅ 1. نضيفو رسالة المستخدم فوراً
    setState(() {
      final i = getIdx();
      if (i == -1) return;
      getMsgs().add(<String, dynamic>{
        'role': 'user',
        'message': userMessage,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _conversations[i]['lastUpdated'] = DateTime.now().millisecondsSinceEpoch;
      _isBotTyping = true;
    });

    _scrollToBottom();

    // ✅ 2. نحدّثو العنوان من أول رسالة
    final userMsgsCount = getMsgs().where((m) => m['role'] == 'user').length;
    if (userMsgsCount == 1) {
      setState(() {
        final i = getIdx();
        if (i != -1) {
          _conversations[i]['title'] =
              userMessage.length > 30 ? userMessage.substring(0, 30) + '...' : userMessage;
        }
      });
    }

    // ✅ 3. نطلبو الرد من Gemini + RAG
    String reply;
    try {
      final history = List<Map<String, dynamic>>.from(getMsgs());
      reply = await _askGemini(userMessage, history);
    } catch (e) {
      reply = 'حدث خطأ غير متوقع: ' + e.toString();
    }

    if (!mounted) return;

    // ✅ 4. نضيفو رد البوت
    setState(() {
      _isBotTyping = false;
      final i = getIdx();
      if (i == -1) return;
      getMsgs().add(<String, dynamic>{
        'role': 'bot',
        'message': reply,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _conversations[i]['lastUpdated'] = DateTime.now().millisecondsSinceEpoch;
    });

    _scrollToBottom();

    // ✅ 5. نحفظو في Firestore
    final finalIdx = getIdx();
    if (finalIdx != -1) await _saveConversationToFirestore(finalIdx);
  }

  // ────────────────────────────────── HELPERS ───────────────────────────────

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

  // ────────────────────────────────── BUILD ─────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F2),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
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

  // ── AppBar ─────────────────────────────────────────────────────────────────

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

  // ── Drawer ─────────────────────────────────────────────────────────────────

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
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_conversations.length} محادثة',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
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
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? AppColors.primary : Colors.grey[800],
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

  // ── Message List ───────────────────────────────────────────────────────────

  Widget _buildMessageList() {
    if (_currentConversationIndex == -1 || _conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    // ✅ آمن: نحوّل النوع باش ما يصيرش crash
    final rawList = _conversations[_currentConversationIndex]['messages'] as List;
    final messages = rawList
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      itemCount: messages.length + (_isBotTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && _isBotTyping) {
          return _buildTypingIndicator();
        }
        final msg = messages[index];
        final text = msg['message']?.toString() ?? '';
        return _buildMessageBubble(text, msg['role'] == 'user');
      },
    );
  }

  // ── Typing Indicator ───────────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 8),
      child: Row(
        children: [
          _botAvatar(),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    offset: const Offset(0, 2))
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimController,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase =
                        (_typingAnimController.value + i * 0.33) % 1.0;
                    final y = -4.0 * math.sin(phase * math.pi);
                    return Transform.translate(
                      offset: Offset(0, y),
                      child: Container(
                        width: 7,
                        height: 7,
                        margin:
                            const EdgeInsets.symmetric(horizontal: 2),
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

  // ── Message Bubble ─────────────────────────────────────────────────────────

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
            if (!isUser) ...[_botAvatar(), const SizedBox(width: 8)],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72),
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
            if (isUser) ...[const SizedBox(width: 8), _userAvatar()],
          ],
        ),
      ),
    );
  }

  Widget _botAvatar() => Container(
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
                offset: const Offset(0, 2))
          ],
        ),
        child: const Icon(Icons.eco_rounded, size: 17, color: Colors.white),
      );

  Widget _userAvatar() => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10)),
        child:
            const Icon(Icons.person_rounded, size: 17, color: Colors.white),
      );

  // ── Input Bar ──────────────────────────────────────────────────────────────

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, -3))
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
                      color: AppColors.accent.withValues(alpha: 0.25)),
                ),
                child: TextField(
                  controller: _questionController,
                  focusNode: _inputFocusNode,
                  textDirection: TextDirection.rtl,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(
                      fontSize: 15, color: Color(0xFF2D4A2D)),
                  decoration: InputDecoration(
                    hintText: 'اسألني عن الري، التسميد، الأمراض...',
                    hintStyle:
                        TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 11),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ScaleTransition(
              scale: _sendBtnScale,
              child: GestureDetector(
                onTap: _isBotTyping ? null : _sendMessage,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: _isBotTyping
                        ? LinearGradient(
                            colors: [Colors.grey.shade300, Colors.grey.shade400])
                        : LinearGradient(
                            colors: [AppColors.accent, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isBotTyping
                        ? []
                        : [
                            BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4))
                          ],
                  ),
                  child: Icon(
                    _isBotTyping ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _typingAnimController.dispose();
    _sendBtnController.dispose();
    super.dispose();
  }
}