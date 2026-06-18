import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Companion 模式独立数据库
///
/// 存储角色级完整记忆体系：
/// - 聊天记录（每个角色独立）
/// - Emotion 状态（五维情绪）
/// - Moments 朋友圈
/// - Proactive 主动消息记录
/// - 角色 Persona 数据（性格/设定）
///
/// ❌ 不存储：工具调用记录、纯问答内容
class CompanionMemoryDB {
  static Database? _db;

  static Future<Database> get db async {
    if (_db == null) await _init();
    return _db!;
  }

  static Future<void> _init() async {
    if (_db != null) return;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'companion_memory.db'),
      onCreate: (db, version) async {
        // 聊天记录（按角色隔离）
        await db.execute('''
          CREATE TABLE chats (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            character_id TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
        // 情绪状态（每个角色一行）
        await db.execute('''
          CREATE TABLE emotions (
            character_id TEXT PRIMARY KEY,
            love INTEGER DEFAULT 50,
            jealousy INTEGER DEFAULT 10,
            dependency INTEGER DEFAULT 20,
            coldness INTEGER DEFAULT 0,
            missing INTEGER DEFAULT 10,
            updated_at INTEGER NOT NULL
          )
        ''');
        // 朋友圈
        await db.execute('''
          CREATE TABLE moments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            character_id TEXT NOT NULL,
            text TEXT,
            image_url TEXT,
            emotion_state TEXT,
            timestamp INTEGER NOT NULL
          )
        ''');
        // 主动消息记录
        await db.execute('''
          CREATE TABLE proactive_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            character_id TEXT NOT NULL,
            message TEXT NOT NULL,
            context TEXT,
            timestamp INTEGER NOT NULL
          )
        ''');
        // 角色人格数据
        await db.execute('''
          CREATE TABLE personas (
            character_id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            emoji TEXT DEFAULT '🤖',
            personality TEXT,
            background TEXT,
            traits TEXT,
            greeting TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
      },
      version: 1,
    );
  }

  // ========== 聊天 ==========

  /// 保存聊天消息
  static Future<void> saveChat({
    required String characterId,
    required String role,
    required String content,
  }) async {
    final d = await db;
    await d.insert('chats', {
      'character_id': characterId,
      'role': role,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 获取某个角色的聊天历史
  static Future<List<Map<String, dynamic>>> getChatByCharacter({
    required String characterId,
    int limit = 200,
  }) async {
    final d = await db;
    return await d.query(
      'chats',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'timestamp ASC',
      limit: limit,
    );
  }

  /// 删除某个角色的聊天记录
  static Future<void> clearChat(String characterId) async {
    final d = await db;
    await d.delete('chats',
        where: 'character_id = ?', whereArgs: [characterId]);
  }

  // ========== 情绪 ==========

  /// 保存角色情绪状态
  static Future<void> saveEmotionState({
    required String characterId,
    required Map<String, int> emotionMap,
  }) async {
    final d = await db;
    await d.insert('emotions', {
      'character_id': characterId,
      'love': emotionMap['love'] ?? 50,
      'jealousy': emotionMap['jealousy'] ?? 10,
      'dependency': emotionMap['dependency'] ?? 20,
      'coldness': emotionMap['coldness'] ?? 0,
      'missing': emotionMap['missing'] ?? 10,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 加载角色情绪状态
  static Future<Map<String, dynamic>?> loadEmotionState(String characterId) async {
    final d = await db;
    final rows = await d.query('emotions',
        where: 'character_id = ?', whereArgs: [characterId]);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  // ========== 朋友圈 ==========

  /// 保存朋友圈动态
  static Future<void> saveMoment({
    required String characterId,
    required String text,
    String? imageUrl,
    String? emotionState,
  }) async {
    final d = await db;
    await d.insert('moments', {
      'character_id': characterId,
      'text': text,
      'image_url': imageUrl,
      'emotion_state': emotionState,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 获取角色的朋友圈历史
  static Future<List<Map<String, dynamic>>> getMomentsByCharacter(
    String characterId, {
    int limit = 50,
  }) async {
    final d = await db;
    return await d.query(
      'moments',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // ========== 主动消息日志 ==========

  /// 记录主动消息
  static Future<void> saveProactiveLog({
    required String characterId,
    required String message,
    String? context,
  }) async {
    final d = await db;
    await d.insert('proactive_logs', {
      'character_id': characterId,
      'message': message,
      'context': context,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 获取主动消息历史
  static Future<List<Map<String, dynamic>>> getProactiveLogs(
    String characterId, {
    int limit = 50,
  }) async {
    final d = await db;
    return await d.query(
      'proactive_logs',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
  }

  // ========== 角色人格 ==========

  /// 保存/更新角色人格数据
  static Future<void> savePersona({
    required String characterId,
    required String name,
    String emoji = '🤖',
    String? personality,
    String? background,
    String? traits,
    String? greeting,
  }) async {
    final d = await db;
    await d.insert('personas', {
      'character_id': characterId,
      'name': name,
      'emoji': emoji,
      'personality': personality,
      'background': background,
      'traits': traits,
      'greeting': greeting,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 加载角色人格数据
  static Future<Map<String, dynamic>?> loadPersona(String characterId) async {
    final d = await db;
    final rows = await d.query('personas',
        where: 'character_id = ?', whereArgs: [characterId]);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  // ========== 聚合查询 ==========

  /// 获取某个角色的完整人格记忆（聊天 + 情绪 + 朋友圈 + 人格）
  static Future<Map<String, dynamic>> getFullPersonaMemory(
    String characterId, {
    int chatLimit = 100,
    int momentLimit = 20,
  }) async {
    final chats = await getChatByCharacter(
      characterId: characterId,
      limit: chatLimit,
    );
    final emotion = await loadEmotionState(characterId);
    final moments = await getMomentsByCharacter(
      characterId,
      limit: momentLimit,
    );
    final persona = await loadPersona(characterId);
    final proactiveLogs = await getProactiveLogs(
      characterId,
      limit: 20,
    );

    return {
      'characterId': characterId,
      'persona': persona,
      'emotion': emotion,
      'chats': chats,
      'moments': moments,
      'proactiveLogs': proactiveLogs,
    };
  }

  // ========== 清理 ==========

  /// 删除指定角色的所有数据
  static Future<void> clearCharacterData(String characterId) async {
    final d = await db;
    await d.delete('chats',
        where: 'character_id = ?', whereArgs: [characterId]);
    await d.delete('emotions',
        where: 'character_id = ?', whereArgs: [characterId]);
    await d.delete('moments',
        where: 'character_id = ?', whereArgs: [characterId]);
    await d.delete('proactive_logs',
        where: 'character_id = ?', whereArgs: [characterId]);
    await d.delete('personas',
        where: 'character_id = ?', whereArgs: [characterId]);
  }

  /// 清空所有数据
  static Future<void> clearAll() async {
    final d = await db;
    await d.delete('chats');
    await d.delete('emotions');
    await d.delete('moments');
    await d.delete('proactive_logs');
    await d.delete('personas');
  }

  /// 关闭数据库
  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
