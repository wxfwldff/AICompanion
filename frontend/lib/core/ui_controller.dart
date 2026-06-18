import 'package:flutter/material.dart';

// ============ 动态 UI 组件描述 ============
class DynamicUIButton {
  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  DynamicUIButton({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

// ============ 功能模块开关 ============
class FeatureToggles {
  bool ttsEnabled;
  bool emotionEnabled;
  bool momentsEnabled;
  bool proactiveEnabled;
  bool glassEffectEnabled;

  FeatureToggles({
    this.ttsEnabled = true,
    this.emotionEnabled = true,
    this.momentsEnabled = true,
    this.proactiveEnabled = true,
    this.glassEffectEnabled = true,
  });
}

// ============ 全局 UI 控制器 ============
/// 所有字段均为 ValueNotifier，UI 层可监听并实时刷新
class UIController {
  // ---------- 颜色 ----------
  final ValueNotifier<Color> themeColor =
      ValueNotifier<Color>(const Color(0xFF0F0F0F));
  final ValueNotifier<Color> fontColor =
      ValueNotifier<Color>(Colors.white);
  final ValueNotifier<double> fontSize = ValueNotifier<double>(15.0);
  final ValueNotifier<Color> bubbleBgColor =
      ValueNotifier<Color>(Colors.white.withOpacity(0.08));
  final ValueNotifier<Color> userBubbleColor =
      ValueNotifier<Color>(Colors.blueAccent.withOpacity(0.25));

  // ---------- 效果开关 ----------
  final ValueNotifier<bool> glassEffect;
  final ValueNotifier<bool> ttsEnabledState;
  final ValueNotifier<bool> emotionEnabledState;
  final ValueNotifier<bool> momentsEnabledState;
  final ValueNotifier<bool> proactiveEnabledState;

  // ---------- 动态组件 ----------
  final ValueNotifier<List<DynamicUIButton>> dynamicButtons =
      ValueNotifier<List<DynamicUIButton>>([]);

  FeatureToggles get toggles => FeatureToggles(
        ttsEnabled: ttsEnabledState.value,
        emotionEnabled: emotionEnabledState.value,
        momentsEnabled: momentsEnabledState.value,
        proactiveEnabled: proactiveEnabledState.value,
        glassEffectEnabled: glassEffect.value,
      );

  UIController()
      : glassEffect = ValueNotifier<bool>(true),
        ttsEnabledState = ValueNotifier<bool>(true),
        emotionEnabledState = ValueNotifier<bool>(true),
        momentsEnabledState = ValueNotifier<bool>(true),
        proactiveEnabledState = ValueNotifier<bool>(true);

  // ---------- 便捷 setter ----------
  void setThemeColor(Color c) => themeColor.value = c;
  void setFontColor(Color c) => fontColor.value = c;
  void setFontSize(double s) => fontSize.value = s.clamp(12.0, 24.0);
  void setBubbleBg(Color c) => bubbleBgColor.value = c;
  void setUserBubble(Color c) => userBubbleColor.value = c;

  void toggleGlass() => glassEffect.value = !glassEffect.value;
  void setGlass(bool v) => glassEffect.value = v;
  void toggleTTS() => ttsEnabledState.value = !ttsEnabledState.value;
  void toggleEmotion() => emotionEnabledState.value = !emotionEnabledState.value;
  void toggleMoments() => momentsEnabledState.value = !momentsEnabledState.value;
  void toggleProactive() =>
      proactiveEnabledState.value = !proactiveEnabledState.value;

  void enableTTS() => ttsEnabledState.value = true;
  void disableTTS() => ttsEnabledState.value = false;
  void enableEmotion() => emotionEnabledState.value = true;
  void disableEmotion() => emotionEnabledState.value = false;
  void enableMoments() => momentsEnabledState.value = true;
  void disableMoments() => momentsEnabledState.value = false;
  void enableProactive() => proactiveEnabledState.value = true;
  void disableProactive() => proactiveEnabledState.value = false;


  // ---------- 动态组件管理 ----------
  void addButton(DynamicUIButton btn) {
    final list = List<DynamicUIButton>.from(dynamicButtons.value);
    // 避免重复添加相同 id
    list.removeWhere((b) => b.id == btn.id);
    list.add(btn);
    dynamicButtons.value = list;
  }

  void removeButton(String id) {
    final list = List<DynamicUIButton>.from(dynamicButtons.value);
    list.removeWhere((b) => b.id == id);
    dynamicButtons.value = list;
  }

  void clearButtons() => dynamicButtons.value = [];
}

/// 全局单例
final uiController = UIController();
