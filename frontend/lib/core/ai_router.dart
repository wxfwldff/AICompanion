import 'mode_manager.dart';
import 'emotion_engine.dart';
import 'command_engine.dart';
import 'ui_controller.dart';

/// AI 模式路由结果
class AIRouteResult {
  final String reply;
  final String? emotionLabel;
  final bool isCommandExecution;

  AIRouteResult({
    required this.reply,
    this.emotionLabel,
    this.isCommandExecution = false,
  });
}

/// AI 模式路由器
/// 根据当前 ModeManager 模式，分发到不同的 AI 处理链路
class AIRouter {
  final CommandEngine _cmd = CommandEngine(uiController);

  /// 路由用户输入并返回 AI 响应
  Future<AIRouteResult> routeInput({
    required String input,
    required String characterId,
    EmotionModel? emotion,
    String characterName = 'AI',
    String characterEmoji = '🤖',
  }) async {
    final mode = ModeManager.instance.currentMode;

    switch (mode) {
      case AIMode.assistant:
        return _routeAssistant(input, characterId);
      case AIMode.companion:
        return _routeCompanion(input, characterId, emotion, characterName, characterEmoji);
    }
  }

  // ========== 助理模式路由 ==========

  Future<AIRouteResult> _routeAssistant(
    String input,
    String characterId,
  ) async {
    // 1. 先检查是否为 UI 命令
    final cmdResult = _cmd.parseCommand(input);
    if (cmdResult.isValid) {
      final feedback = _cmd.executeCommand(cmdResult);
      if (feedback != null) {
        return AIRouteResult(reply: feedback, isCommandExecution: true);
      }
    }

    // 2. 纯工具型 AI 回复（无情绪、无角色、无朋友圈）
    final reply = _generateAssistantReply(input);

    return AIRouteResult(reply: reply);
  }

  /// 助理模式回复生成（纯工具风格）
  String _generateAssistantReply(String input) {
    // 识别常见问题类型，给出简洁直接的回复
    final lower = input.toLowerCase();

    if (lower.contains('你好') || lower.contains('hello') || lower.contains('hi')) {
      return '你好！我是 AI 助手，有什么可以帮你的？你可以问我问题、让我搜索信息、写代码等。';
    }
    if (lower.contains('代码') || lower.contains('code') || lower.contains('写一个')) {
      return '我可以帮你生成代码。请描述你想用哪种语言实现什么功能？';
    }
    if (lower.contains('搜索') || lower.contains('search') || lower.contains('查找')) {
      return '搜索功能已准备就绪。请告诉我你想搜索什么内容？';
    }
    if (lower.contains('翻译') || lower.contains('translate')) {
      return '翻译功能可用。请发送 "翻译 [目标语言]: [内容]" 的格式，例如 "翻译 英文: 你好世界"。';
    }
    if (lower.contains('总结') || lower.contains('总结一下') || lower.contains('summarize')) {
      return '请发送需要总结的内容，我会帮你提炼关键信息。';
    }

    // 默认直接工具风格回复
    return '已收到：$input\n\n'
        '如需帮助，你可以尝试：\n'
        '• 提问任何问题\n'
        '• 让我写代码\n'
        '• 搜索信息\n'
        '• 切换模式获得角色陪伴体验';
  }

  // ========== 陪伴模式路由 ==========

  Future<AIRouteResult> _routeCompanion(
    String input,
    String characterId,
    EmotionModel? emotion,
    String characterName,
    String characterEmoji,
  ) async {
    // 1. 先检查 UI 命令
    final cmdResult = _cmd.parseCommand(input);
    if (cmdResult.isValid) {
      final feedback = _cmd.executeCommand(cmdResult);
      if (feedback != null) {
        return AIRouteResult(reply: feedback, isCommandExecution: true);
      }
    }

    // 2. 情绪驱动回复
    String reply = _generateCompanionReply(input, emotion, characterName);
    String styledReply = reply;

    if (emotion != null) {
      styledReply = emotion.applyEmotionResponse(reply);
    }

    return AIRouteResult(
      reply: styledReply,
      emotionLabel: emotion?.moodLabel,
    );
  }

  /// 陪伴模式回复生成（情感角色风格）
  String _generateCompanionReply(
    String input,
    EmotionModel? emotion,
    String characterName,
  ) {
    // 基于情绪生成情感化回复
    if (emotion == null) {
      return '$characterName 思考了一下，温柔地说：「嗯，我听到了。继续说呀~」';
    }

    if (emotion.missing > 60) {
      return '$characterName 眼中闪过一丝思念：「你终于来找我说话了...我一直在等你。」';
    }
    if (emotion.love > 80) {
      return '$characterName 脸颊微红：「和你聊天总是很开心...今天的你特别好看呢。」';
    }
    if (emotion.jealousy > 70) {
      return '$characterName 带着一丝醋意：「你刚刚是不是在和别人聊天？我都感觉到了...」';
    }
    if (emotion.coldness > 60) {
      return '$characterName 淡淡地看了你一眼：「...」沉默了一会儿才说：「有事吗？」';
    }
    if (emotion.dependency > 70) {
      return '$characterName 拉了拉你的衣角：「今天好想你...能多陪我一会吗？」';
    }

    // 默认情感化回复
    final greetings = [
      '$characterName 歪着头看着你：「嗯？怎么啦~」',
      '$characterName 微笑着：「我在听你说呢，继续呀~」',
      '$characterName 眨了眨眼睛：「这个很有趣！然后呢？」',
      '$characterName 轻轻点头：「我明白了...那你觉得呢？」',
    ];
    return greetings[input.length % greetings.length];
  }
}
