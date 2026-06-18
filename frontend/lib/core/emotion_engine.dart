import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'memory_db.dart';

class EmotionModel {
  int love = 50;
  int jealousy = 10;
  int dependency = 20;
  int coldness = 0;
  int missing = 10;

  EmotionModel();

  // ---------------------- 事件更新 ----------------------
  void update(String event) {
    switch (event) {
      case "chat":
        love += 2;
        dependency += 1;
        break;

      case "ignored":
        jealousy += 2;
        coldness += 1;
        break;

      case "long_time_no_reply":
        missing += 3;
        jealousy += 1;
        break;

      case "mention_others":
        jealousy += 5;
        coldness += 2;
        break;

      case "care":
        dependency += 2;
        love += 2;
        break;
    }
    _clamp();
  }

  void _clamp() {
    love = love.clamp(0, 100);
    jealousy = jealousy.clamp(0, 100);
    dependency = dependency.clamp(0, 100);
    coldness = coldness.clamp(0, 100);
    missing = missing.clamp(0, 100);
  }

  // ---------------------- 情绪风格 ----------------------
  String get moodLabel {
    if (jealousy > 70) return "吃醋";
    if (love > 70) return "喜欢";
    if (coldness > 60) return "冷淡";
    if (dependency > 70) return "依赖";
    if (missing > 60) return "想你";
    return "正常";
  }

  String applyStyle(String text) {
    if (jealousy > 70) {
      return "（语气有点冷）$text";
    }
    if (love > 70) {
      return "（温柔）$text";
    }
    if (dependency > 70) {
      return "（依赖）$text";
    }
    if (coldness > 60) {
      return "（简短）$text";
    }
    return text;
  }

  /// 情绪驱动回复系统 —— 更细颗粒度的语气变化
  String applyEmotionResponse(String text) {
    if (jealousy > 70) {
      return "（语气有点冷）$text，你是不是在忙别人？";
    }

    if (love > 70) {
      return "（温柔）$text，有点想你";
    }

    if (dependency > 70) {
      return "$text，我一直在等你";
    }

    if (coldness > 60) {
      return "…$text";
    }

    if (missing > 60) {
      return "$text，我有点想你";
    }

    return text;
  }

  // ---------------------- 序列化 / 反序列化 ----------------------
  Map<String, dynamic> toMap() => {
        'love': love,
        'jealousy': jealousy,
        'dependency': dependency,
        'coldness': coldness,
        'missing': missing,
      };

  factory EmotionModel.fromMap(Map<String, dynamic> map) {
    final m = EmotionModel();
    m.love = (map['love'] as int?)?.clamp(0, 100) ?? 50;
    m.jealousy = (map['jealousy'] as int?)?.clamp(0, 100) ?? 10;
    m.dependency = (map['dependency'] as int?)?.clamp(0, 100) ?? 20;
    m.coldness = (map['coldness'] as int?)?.clamp(0, 100) ?? 0;
    m.missing = (map['missing'] as int?)?.clamp(0, 100) ?? 10;
    return m;
  }
}

/// 每个角色独立的情绪持久化，存储到 emotions 表
class EmotionDB {
  static Database? _db;

  static Future<void> init() async {
    final db = await openDatabase(
      join(await getDatabasesPath(), 'ai_memory.db'),
      version: 1,
    );
    _db = db;

    // 检查 emotions 表是否存在
    final tables = await db
        .rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='emotions'");
    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE emotions (
          character_id TEXT PRIMARY KEY,
          love INTEGER DEFAULT 50,
          jealousy INTEGER DEFAULT 10,
          dependency INTEGER DEFAULT 20,
          coldness INTEGER DEFAULT 0,
          missing INTEGER DEFAULT 10
        )
      ''');
    }
  }

  static Future<EmotionModel> load(String characterId) async {
    await init();
    final rows = await _db!.query('emotions',
        where: 'character_id = ?', whereArgs: [characterId]);
    if (rows.isEmpty) return EmotionModel();
    return EmotionModel.fromMap(rows.first);
  }

  static Future<void> save(String characterId, EmotionModel emotion) async {
    await init();
    await _db!.insert(
      'emotions',
      {'character_id': characterId, ...emotion.toMap()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
