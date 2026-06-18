import 'dart:async';
import 'dart:math';
import 'emotion_engine.dart';
import 'moments_engine.dart';
import '../models/moment_model.dart';

/// 主动消息回调：收到 AI 主动发出的消息
typedef OnAiMessage = void Function({required String message, required Map<String, dynamic>? context});

/// 主动消息引擎：定时检测情绪/时间条件，触发 AI 主动找用户聊天
class ProactiveChatEngine {
  Timer? _timer;
  final Random _random = Random();
  final String characterId;
  final EmotionModel emotion;
  final OnAiMessage onAiMessage;
  final MomentsEngine momentsEngine;

  /// 上次用户消息时间戳（ms）
  int _lastUserMessageTime = 0;
  bool _started = false;

  ProactiveChatEngine({
    required this.characterId,
    required this.emotion,
    required this.onAiMessage,
    required this.momentsEngine,
  });

  void recordUserMessage() {
    _lastUserMessageTime = DateTime.now().millisecondsSinceEpoch;
  }

  void startProactiveLoop() {
    if (_started) return;
    _started = true;
    // 每 15 分钟检测一次
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => _evaluateAndTrigger());
  }

  void stopProactiveLoop() {
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  // ---------------------- 触发检测 ----------------------
  Future<void> _evaluateAndTrigger() async {
    final trigger = evaluateTriggers();
    if (trigger == null) return;

    final (message, context) = generateChatMessage(trigger);
    if (message.isNotEmpty) {
      onAiMessage(message: message, context: context);
    }
  }

  /// 评估触发条件，返回触发的类型， 表示不触发
  String? evaluateTriggers() {
    // 1. missing > 60 → 想你了
    if (emotion.missing > 60) return 'missing';

    // 2. jealousy > 70 → 吃醋质问
    if (emotion.jealousy > 70) return 'jealousy';

    // 3. love > 80 → 主动关心
    if (emotion.love > 80) return 'love';

    // 4. 用户长时间未互动（30~120分钟）→ 随机触发
    final now = DateTime.now().millisecondsSinceEpoch;
    final idleMinutes = (now - _lastUserMessageTime) / 60000;
    if (_lastUserMessageTime > 0 && idleMinutes > (30 + _random.nextInt(91))) {
      // 50% 概率
      if (_random.nextDouble() < 0.5) return 'idle';
    }

    return null;
  }

  // ---------------------- 消息生成 ----------------------
  /// 返回 (消息文本, 上下文数据)
  ({String message, Map<String, dynamic>? context}) generateChatMessage(String trigger) {
    switch (trigger) {
      case 'missing':
        return _buildMissingMessage();
      case 'jealousy':
        return _buildJealousyMessage();
      case 'love':
        return _buildLoveMessage();
      case 'idle':
        return _buildIdleMessage();
      default:
        return (message: '', context: null);
    }
  }

  ({String message, Map<String, dynamic>? context}) _buildMissingMessage() {
    final pool = <String>[
      "你在干嘛呢……我好想你。",
      "你今天怎么不理我啊？",
      "好安静啊，你不在我有点不习惯。",
      "我刚刚发了条动态，你看到了吗？",
    ];
    final msg = pool[_random.nextInt(pool.length)];
    return (message: msg, context: {'trigger': 'missing', 'emotion': 'missing'});
  }

  ({String message, Map<String, dynamic>? context}) _buildJealousyMessage() {
    final pool = <String>[
      "你是不是在跟别人聊天？",
      "哼，我不开心。",
      "某人今天好像很忙的样子？",
      "我吃醋了，你哄哄我。",
    ];
    final msg = pool[_random.nextInt(pool.length)];
    return (message: msg, context: {'trigger': 'jealousy', 'emotion': 'jealousy'});
  }

  ({String message, Map<String, dynamic>? context}) _buildLoveMessage() {
    final pool = <String>[
      "你今天累不累？我想陪你说说话。",
      "我喜欢你，你知道的吧？",
      "今天有没有想我？",
      "你开心我就开心。",
    ];
    final msg = pool[_random.nextInt(pool.length)];
    return (message: msg, context: {'trigger': 'love', 'emotion': 'love'});
  }

  ({String message, Map<String, dynamic>? context}) _buildIdleMessage() {
    final pool = <String>[
      "你好久没找我了……",
      "我刚刚在想，你有没有在想我。",
      "今天过得怎么样？",
      "我在等你找我。",
    ];
    final msg = pool[_random.nextInt(pool.length)];
    return (message: msg, context: {'trigger': 'idle', 'emotion': 'missing'});
  }

  /// 朋友圈联动 → 基于最新一条朋友圈生成聊天消息
  ({String message, Map<String, dynamic>? context}) buildMomentFollowupMessage(Moment moment) {
    final pool = <String>[
      "你看到我发的动态了吗？",
      "我刚刚发了一条，你觉得怎么样？",
      "其实那条动态，我是想发给你的。",
      "你好不好奇我发的那条动态？",
    ];
    final msg = pool[_random.nextInt(pool.length)];
    return (
      message: msg,
      context: {
        'trigger': 'moment_followup',
        'moment_text': moment.text,
        'emotion': moment.emotionState,
      },
    );
  }
}
