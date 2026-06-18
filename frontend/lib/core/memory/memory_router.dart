import '../mode_manager.dart';
import 'assistant_memory_db.dart';
import 'companion_memory_db.dart';

/// 记忆路由器
///
/// 根据当前 ModeManager 的模式，将读写操作路由到正确的数据库：
/// - assistant 模式 → AssistantMemoryDB（独立 .db 文件，仅存 QA）
/// - companion 模式 → CompanionMemoryDB（独立 .db 文件，存完整角色记忆）
///
/// 确保两个模式的记忆**完全物理隔离**（不同 .db 文件）
class MemoryRouter {
  /// 当前模式
  static AIMode get _mode => ModeManager.instance.currentMode;

  // ========== 写操作 ==========

  /// 写入一条消息（根据模式自动路由）
  static Future<void> writeMessage({
    required String characterId, // companion 用
    String? sessionId,           // assistant 用
    required String role,
    required String content,
    String? toolCall,
  }) async {
    if (_mode == AIMode.assistant) {
      await AssistantMemoryDB.saveQA(
        sessionId: sessionId ?? characterId,
        role: role,
        content: content,
        toolCall: toolCall,
      );
    } else {
      await CompanionMemoryDB.saveChat(
        characterId: characterId,
        role: role,
        content: content,
      );
    }
  }

  /// 写入情绪状态（仅在 companion 模式有效）
  static Future<void> writeEmotion({
    required String characterId,
    required Map<String, int> emotionMap,
  }) async {
    if (_mode != AIMode.companion) return; // assistant 模式不存情绪
    await CompanionMemoryDB.saveEmotionState(
      characterId: characterId,
      emotionMap: emotionMap,
    );
  }

  /// 写入朋友圈动态（仅在 companion 模式有效）
  static Future<void> writeMoment({
    required String characterId,
    required String text,
    String? imageUrl,
    String? emotionState,
  }) async {
    if (_mode != AIMode.companion) return; // assistant 模式不存朋友圈
    await CompanionMemoryDB.saveMoment(
      characterId: characterId,
      text: text,
      imageUrl: imageUrl,
      emotionState: emotionState,
    );
  }

  /// 写入主动消息日志（仅在 companion 模式有效）
  static Future<void> writeProactiveLog({
    required String characterId,
    required String message,
    String? context,
  }) async {
    if (_mode != AIMode.companion) return;
    await CompanionMemoryDB.saveProactiveLog(
      characterId: characterId,
      message: message,
      context: context,
    );
  }

  /// 写入角色人格数据（仅在 companion 模式有效）
  static Future<void> writePersona({
    required String characterId,
    required String name,
    String emoji = '🤖',
    String? personality,
    String? background,
    String? traits,
    String? greeting,
  }) async {
    if (_mode != AIMode.companion) return;
    await CompanionMemoryDB.savePersona(
      characterId: characterId,
      name: name,
      emoji: emoji,
      personality: personality,
      background: background,
      traits: traits,
      greeting: greeting,
    );
  }

  // ========== 读操作 ==========

  /// 读取聊天历史（按模式返回对应数据）
  static Future<List<Map<String, dynamic>>> readHistory({
    required String characterId,
    String? sessionId,
    int limit = 100,
  }) async {
    if (_mode == AIMode.assistant) {
      return await AssistantMemoryDB.getHistory(
        sessionId: sessionId ?? characterId,
        limit: limit,
      );
    } else {
      return await CompanionMemoryDB.getChatByCharacter(
        characterId: characterId,
        limit: limit,
      );
    }
  }

  /// 读取情绪状态（仅在 companion 模式有效）
  static Future<Map<String, dynamic>?> readEmotion(String characterId) async {
    if (_mode != AIMode.companion) return null; // assistant 模式无情绪
    return await CompanionMemoryDB.loadEmotionState(characterId);
  }

  /// 读取角色完整人格记忆（仅在 companion 模式有效）
  static Future<Map<String, dynamic>?> readFullPersonaMemory(
    String characterId, {
    int chatLimit = 100,
    int momentLimit = 20,
  }) async {
    if (_mode != AIMode.companion) return null; // assistant 模式无人格
    return await CompanionMemoryDB.getFullPersonaMemory(
      characterId,
      chatLimit: chatLimit,
      momentLimit: momentLimit,
    );
  }

  /// 读取朋友圈（仅在 companion 模式有效）
  static Future<List<Map<String, dynamic>>> readMoments(
    String characterId, {
    int limit = 50,
  }) async {
    if (_mode != AIMode.companion) return []; // assistant 模式无朋友圈
    return await CompanionMemoryDB.getMomentsByCharacter(
      characterId,
      limit: limit,
    );
  }

  // ========== 清理 ==========

  /// 清理当前模式下的数据
  static Future<void> clear({
    required String characterId,
    String? sessionId,
  }) async {
    if (_mode == AIMode.assistant) {
      await AssistantMemoryDB.clearSession(sessionId ?? characterId);
    } else {
      await CompanionMemoryDB.clearCharacterData(characterId);
    }
  }

  /// 清空当前模式所有数据
  static Future<void> clearAll() async {
    if (_mode == AIMode.assistant) {
      await AssistantMemoryDB.clearAll();
    } else {
      await CompanionMemoryDB.clearAll();
    }
  }

  // ========== 模式切换回调 ==========

  /// 切换模式时调用，可在此处做清理或预加载
  static Future<void> onModeSwitch(AIMode newMode) async {
    // assistant → companion：
    //   ❌ 不加载 emotion（由对应页面的 _loadHistory 按需加载）
    //   ✔ 只初始化角色记忆（惰性初始化，无需额外操作）
    //
    // companion → assistant：
    //   ❌ 不加载角色数据（MemoryRouter 会自动拒绝写入人格数据）
    //   ✔ 清空人格上下文（调用 clearAll 会清除旧模式数据，但不清除对方数据）
    // 不需要清理物理数据库，因为两个模式的 .db 文件不同
  }
}
