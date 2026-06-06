// lib/core/database/database_helper.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('agripal_knowledge.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('PRAGMA journal_mode = WAL'); // ✅ أداء أفضل
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // ✅ جدول الأسئلة والأجوبة الزراعية
    await db.execute('''
      CREATE TABLE qa_entries (
        id TEXT PRIMARY KEY,
        wilaya TEXT NOT NULL,
        category TEXT,
        crop TEXT,
        question_fr TEXT,
        question_ar TEXT,
        question_en TEXT,
        answer_fr TEXT,
        answer_ar TEXT,
        answer_en TEXT,
        keywords TEXT,
        search_vector TEXT,  // ✅ حقل مفهرس للبحث السريع
        created_at INTEGER DEFAULT (strftime('%s', 'now'))
      )
    ''');

    // ✅ فهارس لتسريع البحث
    await db.execute('CREATE INDEX idx_wilaya ON qa_entries(wilaya)');
    await db.execute('CREATE INDEX idx_crop ON qa_entries(crop)');
    await db.execute('CREATE INDEX idx_category ON qa_entries(category)');
    await db.execute('CREATE INDEX idx_keywords ON qa_entries(keywords)');
    
    // ✅ فهرس مركب للبحث المتقدم
    await db.execute('CREATE INDEX idx_search ON qa_entries(wilaya, crop, search_vector)');
    
    // ✅ فهرس نصي كامل (Full-Text Search) - اختياري لكن موصى به
    await db.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS qa_fts USING fts5(
        question_fr, question_ar, question_en,
        answer_fr, answer_ar, answer_en,
        keywords, crop, wilaya,
        content='qa_entries', content_rowid='rowid'
      )
    ''');
  }

  // ✅ إدخال دفعة من البيانات (Bulk Insert)
  Future<int> bulkInsert(List<Map<String, dynamic>> entries) async {
    final db = await database;
    int count = 0;
    
    await db.transaction((txn) async {
      for (final entry in entries) {
        await txn.insert('qa_entries', entry, 
          conflictAlgorithm: ConflictAlgorithm.replace);
        count++;
      }
    });
    
    return count;
  }

  // ✅ بحث ذكي مع دعم الولاية واللغة والأولوية
  Future<List<Map<String, dynamic>>> search({
    required String query,
    String? wilaya,
    String? crop,
    String language = 'ar', // 'ar', 'fr', 'en'
    int limit = 5,
  }) async {
    final db = await database;
    final lowerQuery = query.toLowerCase().trim();
    
    // ✅ تحديد عمود الإجابة حسب اللغة
    final answerCol = language == 'ar' ? 'answer_ar' : 
                      language == 'en' ? 'answer_en' : 'answer_fr';
    final questionCol = language == 'ar' ? 'question_ar' : 
                        language == 'en' ? 'question_en' : 'question_fr';

    // ✅ بناء استعلام بحث ذكي
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    // 1. بحث في الأسئلة باستخدام LIKE مع كلمات مفتاحية
    final words = lowerQuery.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    if (words.isNotEmpty) {
      final likeConditions = words.map((w) => 
        '($questionCol LIKE ? OR keywords LIKE ? OR crop LIKE ?)'
      ).join(' AND ');
      whereClauses.add(likeConditions);
      for (final w in words) {
        whereArgs.addAll(['%$w%', '%$w%', '%$w%']);
      }
    }

    // 2. تصفية حسب الولاية
    if (wilaya != null && wilaya.isNotEmpty) {
      whereClauses.add('wilaya LIKE ?');
      whereArgs.add('%$wilaya%');
    }

    // 3. تصفية حسب المحصول
    if (crop != null && crop.isNotEmpty) {
      whereClauses.add('crop LIKE ?');
      whereArgs.add('%$crop%');
    }

    // ✅ الاستعلام النهائي مع ترتيب بالأولوية
    final orderBy = '''
      CASE 
        WHEN $questionCol LIKE '$lowerQuery' THEN 3
        WHEN keywords LIKE '%$lowerQuery%' THEN 2
        WHEN crop LIKE '%$lowerQuery%' THEN 1
        ELSE 0
      END DESC,
      created_at DESC
    ''';

    final results = await db.query(
      'qa_entries',
      columns: ['id', 'wilaya', 'crop', 'category', questionCol, answerCol, 'keywords'],
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );

    return results;
  }

  // ✅ بحث باستخدام FTS5 (أسرع للنصوص الطويلة)
  Future<List<Map<String, dynamic>>> searchFTS({
    required String query,
    String? wilaya,
    String language = 'ar',
    int limit = 5,
  }) async {
    final db = await database;
    final answerCol = language == 'ar' ? 'answer_ar' : 
                      language == 'en' ? 'answer_en' : 'answer_fr';
    final questionCol = language == 'ar' ? 'question_ar' : 
                        language == 'en' ? 'question_en' : 'question_fr';

    // ✅ تنظيف الاستعلام لـ FTS5
    final cleanQuery = query.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ').trim();
    if (cleanQuery.isEmpty) return [];

    String ftsQuery = cleanQuery.split(' ').map((w) => '$w*').join(' ');
    
    // ✅ استعلام FTS مع JOIN للجدول الرئيسي
    final results = await db.rawQuery('''
      SELECT qe.id, qe.wilaya, qe.crop, qe.category, 
             qe.$questionCol as question, qe.$answerCol as answer, qe.keywords,
             bm25(qa_fts) as relevance
      FROM qa_fts
      JOIN qa_entries qe ON qa_fts.rowid = qe.rowid
      WHERE qa_fts MATCH ?
      ${wilaya != null ? 'AND qe.wilaya LIKE ?' : ''}
      ORDER BY relevance ASC, qe.created_at DESC
      LIMIT ?
    ''', wilaya != null ? ['$ftsQuery', '%$wilaya%', limit] : ['$ftsQuery', limit]);

    return results;
  }

  // ✅ التحقق مما إذا كانت قاعدة البيانات مملوءة
  Future<bool> isDatabasePopulated() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM qa_entries');
    return (result.first['count'] as int) > 0;
  }

  // ✅ مسح وإعادة تعبئة القاعدة (للتحديث)
  Future<void> refreshDatabase(List<Map<String, dynamic>> entries) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('qa_entries');
      await txn.delete('qa_fts'); // مسح FTS أيضاً
    });
    await bulkInsert(entries);
    
    // ✅ إعادة بناء فهرس FTS
    await db.execute('''
      INSERT INTO qa_fts(rowid, question_fr, question_ar, question_en, 
                        answer_fr, answer_ar, answer_en, keywords, crop, wilaya)
      SELECT rowid, question_fr, question_ar, question_en,
             answer_fr, answer_ar, answer_en, keywords, crop, wilaya
      FROM qa_entries
    ''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}