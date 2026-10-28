import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:agripal/core/constants/app_colors.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path_lib;

// ============================================================
// 🔑 مفتاح API الخاص بك - ضع مفتاحك الحقيقي هنا
// ============================================================
const String DEEPSEEK_API_KEY = 'your api key'; // مفتاحك التجريبي
const String API_BASE_URL = 'https://openrouter.ai/api/v1/chat/completions';
const String API_MODEL = 'deepseek/deepseek-chat'; // أو 'deepseek/deepseek-r1'

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  
  late Database _database;
  bool _isDbReady = false;
  
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  List<Map<String, dynamic>> _conversations = [];
  int _currentConversationIndex = -1;
  bool _isLoading = true;
  bool _isBotTyping = false;
  bool _useAPI = true; // ✅ تفعيل API

  User? _currentUser;
  final _firestore = FirebaseFirestore.instance;

  late AnimationController _typingAnimController;
  late AnimationController _sendBtnController;
  late Animation<double> _sendBtnScale;

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

    _initDatabaseAndApp();
  }

  Future<void> _initDatabaseAndApp() async {
    await _initDatabase();
    await _loadConversationsFromFirestore();
  }

  Future<void> _initDatabase() async {
    try {
      final documentsPath = await getDatabasesPath();
      final path = path_lib.join(documentsPath, 'agricultural_db.db');
      
      _database = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreateDb,
      );
      
      await _loadCsvToDatabase();
      
      setState(() => _isDbReady = true);
      debugPrint('✅ قاعدة البيانات المحلية جاهزة');
    } catch (e) {
      debugPrint('❌ خطأ في قاعدة البيانات: $e');
      setState(() => _isDbReady = false);
    }
  }

  Future<void> _onCreateDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS agricultural_knowledge (
        id TEXT PRIMARY KEY,
        wilaya TEXT,
        category TEXT,
        crop TEXT,
        question_fr TEXT,
        question_ar TEXT,
        question_en TEXT,
        answer_fr TEXT,
        answer_ar TEXT,
        answer_en TEXT,
        keywords TEXT,
        search_text TEXT
      )
    ''');
    
    await db.execute('CREATE INDEX IF NOT EXISTS idx_search_text ON agricultural_knowledge(search_text)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_crop ON agricultural_knowledge(crop)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_wilaya ON agricultural_knowledge(wilaya)');
  }

  Future<void> _loadCsvToDatabase() async {
    try {
      final count = Sqflite.firstIntValue(
        await _database.rawQuery('SELECT COUNT(*) FROM agricultural_knowledge')
      );
      
      if (count != null && count > 0) {
        debugPrint('✅ البيانات موجودة مسبقاً: $count سجل');
        return;
      }
      
      final csvContent = await rootBundle.loadString('assets/data/agricultural_qa_dataset.csv');
      final entries = _parseCsvToEntries(csvContent);
      
      if (entries.isNotEmpty) {
        for (final entry in entries) {
          await _database.insert('agricultural_knowledge', entry, 
            conflictAlgorithm: ConflictAlgorithm.replace);
        }
        debugPrint('✅ تم تحميل ${entries.length} سجل');
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في تحميل CSV: $e');
    }
  }

  List<Map<String, dynamic>> _parseCsvToEntries(String csvContent) {
    final lines = csvContent.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length < 2) return [];

    final headers = _parseCsvLine(lines[0]);
    final entries = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length && i < 5000; i++) {
      final values = _parseCsvLine(lines[i]);
      if (values.length < headers.length) continue;

      final row = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        row[headers[j]] = values[j].replaceAll(RegExp(r'^"|"$'), '').trim();
      }

      final searchText = [
        row['wilaya'], row['crop'], row['category'],
        row['question_fr'], row['question_ar'], row['question_en'],
        row['keywords']
      ].where((s) => s != null && s.isNotEmpty).join(' ').toLowerCase();

      entries.add({
        'id': row['unique_id'] ?? 'entry_$i',
        'wilaya': row['wilaya'] ?? '',
        'category': row['category'] ?? '',
        'crop': row['crop'] ?? '',
        'question_fr': row['question_fr'] ?? '',
        'question_ar': row['question_ar'] ?? '',
        'question_en': row['question_en'] ?? '',
        'answer_fr': row['answer_fr'] ?? '',
        'answer_ar': row['answer_ar'] ?? '',
        'answer_en': row['answer_en'] ?? '',
        'keywords': row['keywords'] ?? '',
        'search_text': searchText,
      });
    }
    return entries;
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    bool inQuotes = false;
    final buffer = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  String _detectLanguage(String text) {
    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) return 'ar';
    if (RegExp(r'^[a-zA-Z\s\?\.]+$').hasMatch(text.trim())) return 'en';
    return 'fr';
  }

  String? _extractWilaya(String query) {
    final wilayas = [
      'أدرار', 'Adrar', 'الشلف', 'Chlef', 'الأغواط', 'Laghouat', 'أم البواقي', 'Oum El Bouaghi',
      'باتنة', 'Batna', 'بجاية', 'Béjaïa', 'بسكرة', 'Biskra', 'بشار', 'Béchar', 'البليدة', 'Blida',
      'البويرة', 'Bouira', 'تمنراست', 'Tamanrasset', 'تبسة', 'Tébessa', 'تلمسان', 'Tlemcen',
      'تيارت', 'Tiaret', 'تيزي وزو', 'Tizi Ouzou', 'الجزائر', 'Alger', 'الجلفة', 'Djelfa',
      'جيجل', 'Jijel', 'سطيف', 'Sétif', 'سعيدة', 'Saïda', 'سكيكدة', 'Skikda', 'سيدي بلعباس', 'Sidi Bel Abbès',
      'عنابة', 'Annaba', 'قالمة', 'Guelma', 'قسنطينة', 'Constantine', 'المدية', 'Médéa',
      'مستغانم', 'Mostaganem', 'المسيلة', 'M\'Sila', 'معسكر', 'Mascara', 'ورقلة', 'Ouargla',
      'وهران', 'Oran', 'البيض', 'El Bayadh', 'إليزي', 'Illizi', 'برج بوعريريج', 'Bordj Bou Arreridj',
      'بومرداس', 'Boumerdès', 'الطارف', 'El Tarf', 'تندوف', 'Tindouf', 'تيسمسيلت', 'Tissemsilt',
      'الوادي', 'El Oued', 'خنشلة', 'Khenchela', 'سوق أهراس', 'Souk Ahras', 'تيبازة', 'Tipaza',
      'ميلة', 'Mila', 'عين الدفلى', 'Aïn Defla', 'النعامة', 'Naâma', 'عين تموشنت', 'Aïn Témouchent',
      'غرداية', 'Ghardaïa', 'غليزان', 'Relizane'
    ];
    final lowerQuery = query.toLowerCase();
    for (final wilaya in wilayas) {
      if (lowerQuery.contains(wilaya.toLowerCase())) return wilaya;
    }
    return null;
  }

  String? _extractCrop(String query) {
    final crops = [
      'بطاطس', 'potato', 'pomme de terre', 'طماطم', 'tomato', 'tomate',
      'قمح', 'wheat', 'blé', 'شعير', 'barley', 'orge', 'زيتون', 'olive',
      'نخيل', 'date', 'palm', 'فول', 'bean', 'haricot', 'عدس', 'lentil'
    ];
    final lower = query.toLowerCase();
    for (final c in crops) {
      if (lower.contains(c.toLowerCase())) return c;
    }
    return null;
  }

  Future<Map<String, dynamic>?> _searchLocalDatabase(String query) async {
    if (!_isDbReady) return null;
    
    try {
      final lang = _detectLanguage(query);
      final wilaya = _extractWilaya(query);
      final crop = _extractCrop(query);
      final lowerQuery = query.toLowerCase();
      
      String sql = '''
        SELECT * FROM agricultural_knowledge 
        WHERE search_text LIKE ?
      ''';
      List<Object?> params = ['%$lowerQuery%'];
      
      if (wilaya != null) {
        sql += ' OR wilaya LIKE ?';
        params.add('%$wilaya%');
      }
      
      if (crop != null) {
        sql += ' OR crop LIKE ?';
        params.add('%$crop%');
      }
      
      final keywords = ['ري', 'سقي', 'سماد', 'تسميد', 'مرض', 'علاج', 'تربة', 'محصول'];
      for (final kw in keywords) {
        if (lowerQuery.contains(kw)) {
          sql += ' OR keywords LIKE ?';
          params.add('%$kw%');
          break;
        }
      }
      
      sql += ' LIMIT 5';
      
      final results = await _database.rawQuery(sql, params);
      
      if (results.isNotEmpty) {
        final best = results.first;
        final answerKey = lang == 'fr' ? 'answer_fr' : lang == 'en' ? 'answer_en' : 'answer_ar';
        String? answer = best[answerKey]?.toString();
        
        if ((answer == null || answer.isEmpty || answer == 'null') && lang != 'ar') {
          answer = best['answer_ar']?.toString();
        }
        
        if (answer != null && answer.isNotEmpty && answer != 'null') {
          return {
            'answer': answer,
            'crop': best['crop'],
            'wilaya': best['wilaya'],
            'source': 'local_db'
          };
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('⚠️ خطأ في البحث المحلي: $e');
      return null;
    }
  }

  // ============================================================
  // 🤖 دالة استدعاء DeepSeek API عبر OpenRouter
  // ============================================================
  Future<String> _callDeepSeekAPI(String question) async {
    try {
      debugPrint('🚀 Calling DeepSeek API with question: $question');
      
      final response = await http.post(
        Uri.parse(API_BASE_URL),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $DEEPSEEK_API_KEY',
          'HTTP-Referer': 'https://agripal.app',
          'X-Title': 'AgriPal Assistant',
        },
        body: jsonEncode({
          'model': API_MODEL,
          'messages': [
            {
              'role': 'system',
              'content': '''أنت خبير زراعي جزائري محترف متخصص في الفلاحة الجزائرية. 
              أجب باللهجة العربية أو الفرنسية أو الإنجليزية حسب سؤال المستخدم.
              قدم إجابات مفصلة ودقيقة مع نصائح عملية.
              استخدم رموزاً تعبيرية مناسبة 🌾🍅🥔🌱💧.
              إذا سئل عن ولاية معينة، قدم معلومات خاصة بتلك المنطقة.
              كن ودوداً ومحفزاً للمزارعين.
              لا تخرج عن المجال الزراعي.
              إذا لم تكن متأكداً، قل ذلك بصراحة وقدم مصادر موثوقة.'''
            },
            {
              'role': 'user',
              'content': question,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 1500,
          'top_p': 0.9,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];
        debugPrint('✅ API Response received successfully');
        return reply.toString();
      } else {
        debugPrint('⚠️ API Error ${response.statusCode}: ${response.body}');
        return await _generateFallbackResponse(question);
      }
    } catch (e) {
      debugPrint('❌ API Exception: $e');
      return await _generateFallbackResponse(question);
    }
  }

  // ============================================================
  // 📚 الإجابات المحلية (Fallback) - نفس الإجابات المحسنة السابقة
  // ============================================================
  
  String? _getDirectKeywordResponse(String query) {
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('مرحبا') || lowerQuery.contains('السلام') || lowerQuery.contains('اهلا')) {
      return '🌾 **وعليكم السلام ورحمة الله وبركاتة** 🌾\n\nأهلاً بك في المستشار الفلاحي الذكي! أنا هنا لمساعدتك في:\n• 🌱 إرشادات زراعية دقيقة حسب منطقتك\n• 💧 جداول الري والتسميد\n• 🩺 تشخيص الأمراض والحلول العملية\n• 📅 مواعيد الزراعة المناسبة\n\n**كيف أقدر أساعدك اليوم؟**';
    }
    
    if (lowerQuery.contains('شكرا')) {
      return '🌱 **العفو، هذا واجبي!** 🌱\n\nسعيد بأني قدرت أساعدك. أنا هنا دائماً لأي استفسار زراعي. وفقك الله في مزرعتك وجعلها عامرة بالخير والبركة. 🤲';
    }
    
    if (lowerQuery.contains('طماطم')) {
      if (lowerQuery.contains('زرع') || lowerQuery.contains('زراعة')) {
        return '🍅 **دليل زراعة الطماطم في الجزائر** 🍅\n\n'
            '**【 مواعيد الزراعة حسب المنطقة 】**\n'
            '▸ **المناطق الساحلية** (الجزائر، وهران، عنابة): منتصف فبراير - مارس\n'
            '▸ **المناطق الداخلية** (سطيف، باتنة، المسيلة): مارس - أوائل أبريل\n'
            '▸ **المناطق الصحراوية**: سبتمبر - أكتوبر (ضروري تحت البيوت البلاستيكية)\n'
            '▸ **البيوت البلاستيكية**: من أغسطس إلى ديسمبر\n\n'
            '**【 تجهيز التربة 】**\n'
            '• الحرث العميق: 25-30 سم\n'
            '• إضافة السماد البلدي المتخمر: 30-40 طن/هكتار\n'
            '• إضافة السوبر فوسفات: 300 كغ/هكتار\n\n'
            '💡 **نصيحة**: استخدم بذوراً معتمدة من وزارة الفلاحة.';
      }
      
      if (lowerQuery.contains('ري') || lowerQuery.contains('سقي')) {
        return '💧 **برنامج ري الطماطم المثالي** 💧\n\n'
            '**【 مراحل النمو واحتياجات الماء 】**\n'
            '• **مرحلة الشتل (أول 15 يوم)**: رية خفيفة كل 2-3 أيام\n'
            '• **مرحلة النمو الخضري (15-45 يوم)**: كل 4-5 أيام\n'
            '• **مرحلة التزهير (45-60 يوم)**: كل 5-6 أيام\n'
            '• **مرحلة عقد الثمار (60-90 يوم)**: كل 7 أيام\n\n'
            '✅ **الري بالتنقيط** هو الأفضل لأنه يوفر 40-50% من الماء.\n\n'
            '⚠️ **تنبيه**: لا تروي في منتصف النهار، وتجنب رش الماء على الأوراق.';
      }
      
      return '🍅 **معلومات سريعة عن الطماطم** 🍅\n\n'
          '• أفضل وقت للزراعة: فبراير-مارس\n'
          '• مدة النمو: 70-90 يوم\n'
          '• الري: 3-4 مرات أسبوعياً\n'
          '• الإنتاج المتوقع: 30-60 طن/هكتار\n\n'
          'للمزيد، اسألني عن "زراعة الطماطم" أو "ري الطماطم" أو "أمراض الطماطم".';
    }
    
    if (lowerQuery.contains('ري') || lowerQuery.contains('سقي')) {
      return '💧 **الدليل الكامل للري الزراعي** 💧\n\n'
          '**【 أفضل أنظمة الري 】**\n'
          '✅ **الري بالتنقيط**: يوفر 50-70% من المياه\n'
          '✅ **الري بالرشاشات**: مناسب للحبوب\n'
          '✅ **الري السطحي**: تقليدي لكنه يهدر الماء\n\n'
          '**【 أفضل مواعيد الري 】**\n'
          '🌅 الصباح الباكر (5-8 صباحاً): أفضل وقت\n'
          '🌙 المساء: وقت مقبول لكن يزيد الأمراض\n'
          '☀️ منتصف النهار: ممنوع تماماً\n\n'
          '**【 احتياجات المحاصيل 】**\n'
          '🍅 الطماطم: 3-4 مرات/أسبوع\n'
          '🥔 البطاطس: 2-3 مرات/أسبوع\n'
          '🌾 القمح: كل 10-15 يوماً';
    }
    
    if (lowerQuery.contains('سماد') || lowerQuery.contains('تسميد')) {
      return '🌱 **الدليل الشامل للتسميد الزراعي** 🌱\n\n'
          '**【 أنواع الأسمدة 】**\n'
          '🐄 عضوي (بلدي): يحسن بنية التربة - 30-40 طن/هكتار\n'
          '🌾 يوريا 46%: للنمو الخضري - 150-250 كغ/هكتار\n'
          '🪨 سوبر فوسفات: للجذور والإزهار - 300 كغ/هكتار\n'
          '🧂 سلفات البوتاسيوم: لجودة الثمار - 150-250 كغ/هكتار\n\n'
          '**【 نصائح ذهبية 】**\n'
          '✓ حلل تربتك أولاً\n'
          '✓ لا تسمد في الطقس الحار (>35°C)\n'
          '✓ التسميد العضوي يحسن طعم وجودة المحصول';
    }
    
    return null;
  }

  Future<String> _generateFallbackResponse(String question) async {
    final lowerQuestion = question.toLowerCase().trim();
    
    if (lowerQuestion.length < 2) {
      return '🌾 مرحباً! كيف أقدر أساعدك في زراعتك اليوم؟';
    }
    
    final directResponse = _getDirectKeywordResponse(lowerQuestion);
    if (directResponse != null) {
      return directResponse;
    }
    
    final localResult = await _searchLocalDatabase(lowerQuestion);
    if (localResult != null) {
      String response = '📚 **من قاعدة البيانات الزراعية:**\n\n';
      response += localResult['answer'];
      return response;
    }
    
    return '🌾 **المستشار الفلاحي**\n\n'
        'عذراً، لم أجد إجابة دقيقة لـ "$question"\n\n'
        '**【 أسئلة مقترحة 】**\n'
        '▸ "مواعيد زراعة الطماطم"\n'
        '▸ "برنامج ري البطاطس"\n'
        '▸ "تسميد القمح"\n'
        '▸ "علاج أمراض الطماطم"\n'
        '▸ "كيف أحسن تربتي"\n\n'
        'أعد صياغة سؤالك بطريقة أوضح وسأجيبك بالتفصيل إن شاء الله. 🌾';
  }

  // ============================================================
  // 🧠 الدالة الرئيسية للحصول على رد (API + Fallback)
  // ============================================================
  Future<String> _getResponse(String question) async {
    if (_useAPI) {
      try {
        final apiResponse = await _callDeepSeekAPI(question);
        if (apiResponse.isNotEmpty && !apiResponse.contains('error')) {
          return apiResponse;
        }
      } catch (e) {
        debugPrint('⚠️ API failed, using fallback: $e');
      }
    }
    return await _generateFallbackResponse(question);
  }

  // باقي دوال Firebase و UI
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

  Future<void> _createNewConversation() async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newConv = <String, dynamic>{
      'id': id,
      'title': 'محادثة جديدة ${_conversations.length + 1}',
      'messages': <Map<String, dynamic>>[
        <String, dynamic>{
          'role': 'bot',
          'message': '🌾 **مرحباً بك في المستشار الفلاحي!** 🌾\n\nأنا خبيرك الزراعي الذكي، أساعدك في:\n\n• 🍅 **المحاصيل**: طماطم، بطاطس، قمح، زيتون، نخيل\n• 💧 **الري**: جداول، كميات، أنظمة (تنقيط، رشاشات)\n• 🌱 **التسميد**: عضوي، كيماوي، برامج حسب المحصول\n• 🩺 **الأمراض**: تشخيص، علاج، وقاية\n• 🧪 **التربة**: تحليل، تحسين، معالجة المشاكل\n\n**اسألني بكل ثقة، وأنا هنا لخدمتك!** 🌟',
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

  void _sendMessage() async {
    final text = _questionController.text.trim();
    if (text.isEmpty || _currentConversationIndex == -1 || _conversations.isEmpty) return;

    _sendBtnController.forward().then((_) => _sendBtnController.reverse());
    _questionController.clear();

    final userMessage = text;
    final convId = _conversations[_currentConversationIndex]['id'] as String;

    int getIdx() => _conversations.indexWhere((c) => c['id'] == convId);

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

    // 🟢 هنا الاستدعاء الرئيسي للـ API
    String reply;
    try {
      reply = await _getResponse(userMessage);
    } catch (e) {
      reply = '⚠️ حدث خطأ تقني: $e\nالرجاء المحاولة مرة أخرى.';
    }

    if (!mounted) return;

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

    final finalIdx = getIdx();
    if (finalIdx != -1) await _saveConversationToFirestore(finalIdx);
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

  // ============================================================
  // UI Methods
  // ============================================================

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
          const Flexible(
            child: Text(
              'المستشار الفلاحي',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // مؤشر API
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _useAPI ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _useAPI ? 'AI' : 'Offline',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      actions: [
        // زر toggle API
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            icon: Icon(
              _useAPI ? Icons.wifi : Icons.wifi_off,
              size: 18,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _useAPI = !_useAPI;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_useAPI ? '✅ تم تفعيل AI' : '⚠️ تم التبديل إلى الوضع المحلي'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'تبديل وضع AI',
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_comment_rounded, size: 18, color: Colors.white),
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
              colors: [AppColors.primary, AppColors.accent, const Color(0xFF81C784)],
            ),
          ),
        ),
      ),
    );
  }

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
                  child: const Icon(Icons.history_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(height: 12),
                const Text(
                  'المحادثات السابقة',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_conversations.length} محادثة',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
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
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(color: AppColors.primary.withValues(alpha: 0.3)) : null,
                  ),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.2),
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _switchConversation(index),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
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

  Widget _buildMessageList() {
    if (_currentConversationIndex == -1 || _conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final rawList = _conversations[_currentConversationIndex]['messages'] as List;
    final messages = rawList.map((m) => Map<String, dynamic>.from(m as Map)).toList();

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
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimController,
              builder: (_, __) {
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

  Widget _buildMessageBubble(String message, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[_botAvatar(), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.82)],
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
                    color: isUser ? AppColors.primary.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.07),
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
            BoxShadow(color: AppColors.accent.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))
          ],
        ),
        child: const Icon(Icons.eco_rounded, size: 17, color: Colors.white),
      );

  Widget _userAvatar() => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.person_rounded, size: 17, color: Colors.white),
      );

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, -3))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4EE),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
                ),
                child: TextField(
                  controller: _questionController,
                  focusNode: _inputFocusNode,
                  textDirection: TextDirection.rtl,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF2D4A2D)),
                  decoration: InputDecoration(
                    hintText: 'اسألني عن الري، التسميد، الأمراض...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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
                        ? LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade400])
                        : LinearGradient(
                            colors: [AppColors.accent, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _isBotTyping
                        ? []
                        : [
                            BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))
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

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _typingAnimController.dispose();
    _sendBtnController.dispose();
    _database.close();
    super.dispose();
  }
}
