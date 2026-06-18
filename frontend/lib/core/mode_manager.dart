import 'package:flutter/foundation.dart';

/// AI 运行模式
enum AIMode {
  /// API 问答模式 — 纯工具型，不含情绪/角色/朋友圈
  assistant,

  /// 角色陪伴模式 — 情绪/记忆/朋友圈/主动消息全开
  companion,
}

/// 模式管理器（全局单例）
/// 控制整个 App 的两套 AI 行为路由
class ModeManager {
  // ========== 单例 ==========
  ModeManager._();
  static final ModeManager _instance = ModeManager._();
  static ModeManager get instance => _instance;

  // ========== 状态 ==========
  AIMode _currentMode = AIMode.companion;
  final ValueNotifier<AIMode> modeNotifier = ValueNotifier<AIMode>(AIMode.companion);

  // ========== 公开方法 ==========

  /// 获取当前模式
  AIMode get currentMode => _currentMode;

  /// 设置模式
  void setMode(AIMode mode) {
    if (_currentMode == mode) return;
    _currentMode = mode;
    modeNotifier.value = mode;
    _persistMode(mode);
  }

  /// 切换模式
  AIMode switchMode() {
    final newMode = _currentMode == AIMode.assistant
        ? AIMode.companion
        : AIMode.assistant;
    setMode(newMode);
    return newMode;
  }

  /// 当前是否为助理模式
  bool get isAssistant => _currentMode == AIMode.assistant;

  /// 当前是否为陪伴模式
  bool get isCompanion => _currentMode == AIMode.companion;

  /// 获取模式的中文标签
  String get modeLabel => _currentMode == AIMode.assistant ? '助手模式' : '陪伴模式';

  /// 获取模式的 emoji 图标
  String get modeIcon => _currentMode == AIMode.assistant ? '🧠' : '💕';

  /// 获取模式描述
  String get modeDescription => _currentMode == AIMode.assistant
      ? '纯工具问答 · 无情绪无角色'
      : '情感陪伴 · 有情绪有朋友圈';

  /// 获取对方在当前模式下的称呼
  String get partnerLabel => _currentMode == AIMode.assistant ? 'AI 助手' : '角色';

  // ========== 持久化（本地存储） ==========
  static const String _prefsKey = 'ai_mode';

  void _persistMode(AIMode mode) {
    // 后续可接入 SharedPreferences 持久化
    // 暂用内存存储
  }
}
