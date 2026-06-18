import 'dart:math';
import 'dart:ui' show VoidCallback;
// ============ TTS Provider 枚举 ============
enum TTSProvider { edge, azure, volcengine, openai }

// ============ TTS 语音风格映射 ============
enum VoiceStyle { normal, gentle, cold, soft, whisper }

class TTSConfig {
  TTSProvider provider;
  String language;
  double speed;
  double pitch;

  TTSConfig({
    this.provider = TTSProvider.edge,
    this.language = 'zh-CN',
    this.speed = 1.0,
    this.pitch = 1.0,
  });
}

// ============ TTS 引擎主类 ============
class TTSEngine {
  TTSConfig config;
  bool _isPlaying = false;

  // 回调：实际播放由平台层实现
  void Function(String text, VoiceStyle style)? onPlay;
  VoidCallback? onStop;
  VoidCallback? onComplete;

  TTSEngine({TTSConfig? config}) : config = config ?? TTSConfig();

  // ---------- 情绪 → 语音风格映射 ----------
  static VoiceStyle emotionToVoiceStyle(Map<String, double> emotions) {
    final love = emotions['love'] ?? 0;
    final jealousy = emotions['jealousy'] ?? 0;
    final coldness = emotions['coldness'] ?? 0;
    final missing = emotions['missing'] ?? 0;

    if (love > 70) return VoiceStyle.gentle;
    if (jealousy > 70) return VoiceStyle.cold;
    if (coldness > 60) return VoiceStyle.whisper;
    if (missing > 60) return VoiceStyle.soft;
    if (love > 50) return VoiceStyle.gentle;
    return VoiceStyle.normal;
  }

  /// 播放语音（封装层，由外部注册的 onPlay 处理实际播放）
  void playTTS(String text, Map<String, double> emotions) {
    if (_isPlaying) stopTTS();
    _isPlaying = true;

    final style = TTSEngine.emotionToVoiceStyle(emotions);
    onPlay?.call(text, style);
  }

  /// 便捷 speak 方法（用于 chat_page 直接朗读文本）
  void speak(String text) {
    if (_isPlaying) stopTTS();
    _isPlaying = true;
    onPlay?.call(text, VoiceStyle.normal);
  }

  /// 停止播放
  void stopTTS() {
    if (!_isPlaying) return;
    _isPlaying = false;
    onStop?.call();
  }

  /// 切换 TTS 提供商
  void setTTSProvider(TTSProvider provider) {
    config.provider = provider;
  }

  /// 语音风格 → 显示名称
  static String voiceStyleLabel(VoiceStyle style) {
    switch (style) {
      case VoiceStyle.gentle:
        return '温柔';
      case VoiceStyle.cold:
        return '冷淡';
      case VoiceStyle.soft:
        return '轻柔';
      case VoiceStyle.whisper:
        return '低语';
      case VoiceStyle.normal:
        return '普通';
    }
  }

  bool get isPlaying => _isPlaying;
}
