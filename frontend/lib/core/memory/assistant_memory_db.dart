import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Assistant 模式独立数据库
///
/// 仅存储工具型问答内容：
/// - 用户问题
/// - AI 回答
/// - 工具调用记录
///
/// ❌ 不存储：情绪、角色人格、朋友圈、主动消息等
class AssistantMemoryDB {
  static Database? _db;

  static Future<Database> get db async {
    if (_db == null) await _init();
    return _db!;
  }

  static Future<void> _init() async {
    if (_db != null) return;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'assistant_memory.db'),
      onCreate: (db, version) async {
        // 仅存问答记录
        await db.execute('''
          CREATE TABLE qa_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            tool_call TEXT,
            timestamp INTEGER NOT NULL
          )
        ''');
        // 会话索引（用于清理）
        await db.execute('''
          CREATE TABLE sessions (
            id TEXT PRIMARY KEY,
            created_at INTEGER NOT NULL,
            last_active INTEGER NOT NULL
          )
        ''');
      },
      version: 1,
    );
  }

  // ========== 公开 API ==========

  /// 保存问答对
  static Future<void> saveQA({
    required String sessionId,
    required String role,
    required String content,
    String? toolCall,
  }) async {
    final d = await db;
    await d.insert('qa_records', {
      'session_id': sessionId,
      'role': role,
      'content': content,
      'tool_call': toolCall,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    // 更新会话活跃时间
    await d.insert('sessions', {
      'id': sessionId,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'last_active': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 获取某个会话的历史记录
  static Future<List<Map<String, dynamic>>> getHistory({
    required String sessionId,
    int limit = 100,
  }) async {
    final d = await db;
    return await d.query(
      'qa_records',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
      limit: limit,
    );
  }

  /// 清空某个会话的所有记录
  static Future<void> clearSession(String sessionId) async {
    final d = await db;
    await d.delete('qa_records',
        where: 'session_id = ?', whereArgs: [sessionId]);
    await d.delete('sessions',
        where: 'id = ?', whereArgs: [sessionId]);
  }

  /// 清空所有会话
  static Future<void> clearAll() async {
    final d = await db;
    await d.delete('qa_records');
    await d.delete('sessions');
  }

  /// 获取所有会话列表
  static Future<List<Map<String, dynamic>>> getSessions() async {
    final d = await db;
    return await d.query('sessions', orderBy: 'last_active DESC');
  }

  /// 关闭数据库
  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
