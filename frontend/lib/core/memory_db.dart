import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MemoryDB {
  static Database? _db;

  /// 单例访问：确保在首次调用前已 init
  static Future<MemoryDB> get instance async {
    if (_db == null) await init();
    return MemoryDB._();
  }

  MemoryDB._();

  static Future<void> init() async {
    if (_db != null) return;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'ai_memory.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            character_id TEXT,
            role TEXT,
            content TEXT,
            timestamp INTEGER
          )
        ''');
      },
      version: 1,
    );
  }

  /// 获取某个角色的消息数
  Future<int> getMessageCount(String characterId) async {
    final result = await _db!.rawQuery(
      'SELECT COUNT(*) as cnt FROM messages WHERE character_id = ?',
      [characterId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  static Future<void> insertMessage(
    String characterId,
    String role,
    String content,
  ) async {
    await _db!.insert('messages', {
      'character_id': characterId,
      'role': role,
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<List<Map<String, dynamic>>> getMessages(
    String characterId,
  ) async {
    return await _db!.query(
      'messages',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'timestamp ASC',
    );
  }

  static Future<void> clear(String characterId) async {
    await _db!.delete(
      'messages',
      where: 'character_id = ?',
      whereArgs: [characterId],
    );
  }

  /// 关闭数据库（App 退出时调用）
  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
