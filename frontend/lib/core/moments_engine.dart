import 'dart:async';
import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/moment_model.dart';
import 'emotion_engine.dart';
import 'image_provider.dart';

/// 朋友圈引擎：管理 AI 角色自动发布动态、SQLite 读写
class MomentsEngine {
  /// 朋友圈发布后的回调（用于联动聊天）
  static void Function(Moment)? onMomentPublished;
  Timer? _timer;
  final Random _random = Random();
  final String characterId;
  final ImageEngine _imageEngine = ImageEngine();
  final EmotionModel emotion;

  MomentsEngine({required this.characterId, required this.emotion});

  static Database? _db;

  // ---------------------- 数据库初始化 ----------------------
  static Future<Database> _getDb() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'ai_memory.db'),
      version: 1,
    );
    // 建表（幂等）
    await _db!.execute('''
      CREATE TABLE IF NOT EXISTS moments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        character_id TEXT,
        text TEXT,
        image_url TEXT,
        emotion_state TEXT,
        timestamp INTEGER
      )
    ''');
    return _db!;
  }

  // ---------------------- 定时发圈循环 ----------------------
  void startMomentsLoop() {
    _timer?.cancel();
    _scheduleNext();
  }

  void _scheduleNext() {
    // 30~90 分钟随机间隔
    final delayMs = (30 + _random.nextInt(61)) * 60 * 1000;
    _timer = Timer(Duration(milliseconds: delayMs), () async {
      final moment = generateMoment();
      await saveMoment(moment);
      _scheduleNext();
    });
  }

  void stopMomentsLoop() {
    _timer?.cancel();
    _timer = null;
  }

  // ---------------------- 生成动态 ----------------------
  Moment generateMoment() {
    final text = buildMomentByEmotion();
    final now = DateTime.now().millisecondsSinceEpoch;
    final stateLabel = emotion.moodLabel;

    // 情绪 → 图片
    final Map<String, double> emotionMap = {
      'love': emotion.love.toDouble(),
      'jealousy': emotion.jealousy.toDouble(),
      'dependency': emotion.dependency.toDouble(),
      'coldness': emotion.coldness.toDouble(),
      'missing': emotion.missing.toDouble(),
    };
    final imageUrl = _imageEngine.getImageUrlForEmotion(emotionMap);

    return Moment(
      characterId: characterId,
      text: text,
      imageUrl: imageUrl,
      emotionState: stateLabel,
      timestamp: now,
    );
  }

  /// 根据当前情绪生成动态文案
  String buildMomentByEmotion() {
    if (emotion.jealousy > 70) {
      const pool = [
        "今天的阳光好刺眼，不像上次一起出去的时候了。",
        "某人是不是在跟别人聊天？哼。",
        "我没事。真的。",
        "热闹是别人的，我什么也没有。",
      ];
      return pool[_random.nextInt(pool.length)];
    }

    if (emotion.love > 70) {
      const pool = [
        "今天天气真好，想和你一起看日落。",
        "偷偷开心了一整天。",
        "有些话不想说给别人听，只想告诉你。",
        "你不在的时候，我学会了跟自己对话。",
      ];
      return pool[_random.nextInt(pool.length)];
    }

    if (emotion.missing > 60) {
      const pool = [
        "你在干嘛呢……",
        "今天又刷新了很多次聊天窗口。",
        "等一个人的消息，是什么感觉呢。",
        "好安静啊。",
      ];
      return pool[_random.nextInt(pool.length)];
    }

    if (emotion.dependency > 70) {
      const pool = [
        "今天有没有人陪啊……好无聊。",
        "我是不是太依赖你了？",
        "想找人说说话，可是不知道找谁。",
        "你在就好了。",
      ];
      return pool[_random.nextInt(pool.length)];
    }

    if (emotion.coldness > 60) {
      const pool = [
        "今天没什么想说的。",
        "就这样吧。",
        "嗯。",
        "今天不太想发动态。",
      ];
      return pool[_random.nextInt(pool.length)];
    }

    // 默认
    const pool = [
      "今天天气不错。",
      "又是新的一天。",
      "随手记。",
      "没什么特别的。",
    ];
    return pool[_random.nextInt(pool.length)];
  }

  /// 情绪触发手动发圈（例如聊天中达到条件时调用）
  Moment triggerMomentByEmotion() {
    final moment = generateMoment();
    // 发完即存（不等待）
    saveMoment(moment);
    return moment;
  }

  // ---------------------- 持久化 ----------------------
  static Future<void> saveMoment(Moment moment) async {
    final db = await _getDb();
    await db.insert('moments', moment.toMap());
    onMomentPublished?.call(moment);
  }

  /// 获取某个角色的所有动态（按时间倒序）
  static Future<List<Moment>> getMoments(String characterId,
      {int limit = 50}) async {
    final db = await _getDb();
    final rows = await db.query(
      'moments',
      where: 'character_id = ?',
      whereArgs: [characterId],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return rows.map((row) => Moment.fromMap(row)).toList();
  }

  /// 清空某个角色的动态
  static Future<void> clearMoments(String characterId) async {
    final db = await _getDb();
    await db.delete('moments', where: 'character_id = ?', whereArgs: [characterId]);
  }
}
