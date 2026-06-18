import 'package:flutter/material.dart';
import 'ui_controller.dart';

// ============ 命令数据结构 ============
enum CommandAction {
  setThemeColor,
  setFontColor,
  setFontSize,
  toggleGlass,
  addButton,
  removeButton,
  enableTTS,
  disableTTS,
  enableEmotion,
  disableEmotion,
  enableMoments,
  disableMoments,
  enableProactive,
  disableProactive,
  unknown,
}

class AICommand {
  final CommandAction action;
  final String rawInput;
  final dynamic value;
  final String? message;

  AICommand({
    required this.action,
    required this.rawInput,
    this.value,
    this.message,
  });

  bool get isValid => action != CommandAction.unknown;
}

// ============ 命令引擎 ============
class CommandEngine {
  final UIController _ui;

  CommandEngine(this._ui);

  // ---------- 解析 ----------
  AICommand parseCommand(String raw) {
    final trimmed = raw.trim();

    // 尝试匹配结构化 JSON 命令
    if (trimmed.startsWith('{') && trimmed.contains('"action"')) {
      try {
        final json = _parseJson(trimmed);
        if (json != null) {
          final actionStr = json['action'] as String?;
          final value = json['value'];
          final action = _stringToAction(actionStr ?? '');
          if (action != CommandAction.unknown) {
            return AICommand(action: action, rawInput: raw, value: value);
          }
        }
      } catch (_) {}
    }

    // 自然语言匹配（中文）
    return _parseNaturalLanguage(trimmed);
  }

  AICommand _parseNaturalLanguage(String text) {
    final lower = text.toLowerCase();

    // 主题/背景颜色
    if (text.contains('主题') || text.contains('背景')) {
      final color = _extractColor(text);
      if (color != null) {
        return AICommand(
          action: CommandAction.setThemeColor,
          rawInput: text,
          value: color,
          message: '已设置主题色',
        );
      }
    }

    // 字体颜色
    if (text.contains('字体') && (text.contains('颜色') || text.contains('色'))) {
      final color = _extractColor(text);
      if (color != null) {
        return AICommand(
          action: CommandAction.setFontColor,
          rawInput: text,
          value: color,
          message: '已设置字体颜色',
        );
      }
    }

    // 字体大小
    if (text.contains('字体') && (text.contains('大') || text.contains('小'))) {
      double size = 15.0;
      if (text.contains('大一点') || text.contains('放大') || text.contains('大')) size = 18.0;
      if (text.contains('小')) size = 13.0;
      if (text.contains('超大')) size = 22.0;
      return AICommand(
        action: CommandAction.setFontSize,
        rawInput: text,
        value: size,
        message: '已调整字体大小',
      );
    }

    // 玻璃效果
    if (text.contains('玻璃') && (text.contains('开') || text.contains('启'))) {
      return AICommand(action: CommandAction.toggleGlass, rawInput: text, value: true);
    }
    if (text.contains('玻璃') && text.contains('关')) {
      return AICommand(action: CommandAction.toggleGlass, rawInput: text, value: false);
    }
    if (text.contains('玻璃效果')) {
      return AICommand(action: CommandAction.toggleGlass, rawInput: text);
    }

    // 功能开关
    if (text.contains('开启') && text.contains('tts')) {
      return AICommand(
        action: CommandAction.enableTTS, rawInput: text, message: 'TTS已开启');
    }
    if (text.contains('关闭') && text.contains('tts')) {
      return AICommand(
        action: CommandAction.disableTTS, rawInput: text, message: 'TTS已关闭');
    }
    if (text.contains('开启') && text.contains('情绪')) {
      return AICommand(
        action: CommandAction.enableEmotion, rawInput: text, message: '情绪系统已开启');
    }
    if (text.contains('关闭') && text.contains('情绪')) {
      return AICommand(
        action: CommandAction.disableEmotion, rawInput: text, message: '情绪系统已关闭');
    }
    if (text.contains('开启') && (text.contains('朋友圈') || text.contains('动态'))) {
      return AICommand(
        action: CommandAction.enableMoments, rawInput: text, message: '朋友圈已开启');
    }
    if (text.contains('关闭') && (text.contains('朋友圈') || text.contains('动态'))) {
      return AICommand(
        action: CommandAction.disableMoments, rawInput: text, message: '朋友圈已关闭');
    }
    if (text.contains('开启') && (text.contains('主动') || text.contains('自动'))) {
      return AICommand(
        action: CommandAction.enableProactive, rawInput: text, message: '主动消息已开启');
    }
    if (text.contains('关闭') && (text.contains('主动') || text.contains('自动'))) {
      return AICommand(
        action: CommandAction.disableProactive, rawInput: text, message: '主动消息已关闭');
    }

    // 添加按钮
    if (text.contains('添加') && text.contains('按钮')) {
      final label = _extractLabel(text);
      return AICommand(
        action: CommandAction.addButton,
        rawInput: text,
        value: label,
        message: '已添加按钮: $label',
      );
    }

    return AICommand(action: CommandAction.unknown, rawInput: text);
  }

  // ---------- 执行 ----------
  String executeCommand(AICommand cmd) {
    if (!cmd.isValid) return '未知命令，请重试。';

    switch (cmd.action) {
      case CommandAction.setThemeColor:
        _ui.setThemeColor(cmd.value as Color);
        return '✅ 主题颜色已更新';

      case CommandAction.setFontColor:
        _ui.setFontColor(cmd.value as Color);
        return '✅ 字体颜色已更新';

      case CommandAction.setFontSize:
        _ui.setFontSize((cmd.value as num).toDouble());
        return '✅ 字体大小已调整为 ${cmd.value}';

      case CommandAction.toggleGlass:
        final bool? enable = cmd.value as bool?;
        if (enable != null) {
          _ui.setGlass(enable);
          return enable ? '✅ 玻璃效果已开启' : '✅ 玻璃效果已关闭';
        }
        _ui.toggleGlass();
        return _ui.glassEffect.value ? '✅ 玻璃效果已开启' : '✅ 玻璃效果已关闭';

      case CommandAction.enableTTS:
        _ui.ttsEnabledState.value = true;
        return '✅ TTS语音已开启';
      case CommandAction.disableTTS:
        _ui.ttsEnabledState.value = false;
        return '✅ TTS语音已关闭';

      case CommandAction.enableEmotion:
        _ui.emotionEnabledState.value = true;
        return '✅ 情绪系统已开启';
      case CommandAction.disableEmotion:
        _ui.emotionEnabledState.value = false;
        return '✅ 情绪系统已关闭';

      case CommandAction.enableMoments:
        _ui.momentsEnabledState.value = true;
        return '✅ 朋友圈已开启';
      case CommandAction.disableMoments:
        _ui.momentsEnabledState.value = false;
        return '✅ 朋友圈已关闭';

      case CommandAction.enableProactive:
        _ui.proactiveEnabledState.value = true;
        return '✅ 主动消息已开启';
      case CommandAction.disableProactive:
        _ui.proactiveEnabledState.value = false;
        return '✅ 主动消息已关闭';

      case CommandAction.addButton:
        final label = cmd.value as String? ?? '快捷按钮';
        final id = 'cmd_btn_${DateTime.now().millisecondsSinceEpoch}';
        _ui.addButton(DynamicUIButton(
          id: id,
          label: label,
          icon: Icons.touch_app,
          onTap: () {},
        ));
        return '✅ 已添加按钮「$label」';

      case CommandAction.removeButton:
        if (cmd.value is String) {
          _ui.removeButton(cmd.value);
          return '✅ 已移除按钮';
        }
        return '⚠️ 请指定要移除的按钮ID';

      default:
        return '⚠️ 未知命令类型';
    }
  }

  // ---------- 辅助方法 ----------

  CommandAction _stringToAction(String s) {
    switch (s) {
      case 'set_theme_color':
        return CommandAction.setThemeColor;
      case 'set_font_color':
        return CommandAction.setFontColor;
      case 'set_font_size':
        return CommandAction.setFontSize;
      case 'toggle_glass':
        return CommandAction.toggleGlass;
      case 'add_button':
        return CommandAction.addButton;
      case 'enable_tts':
        return CommandAction.enableTTS;
      case 'disable_tts':
        return CommandAction.disableTTS;
      case 'enable_emotion':
        return CommandAction.enableEmotion;
      case 'disable_emotion':
        return CommandAction.disableEmotion;
      case 'enable_moments':
        return CommandAction.enableMoments;
      case 'disable_moments':
        return CommandAction.disableMoments;
      case 'enable_proactive':
        return CommandAction.enableProactive;
      case 'disable_proactive':
        return CommandAction.disableProactive;
      default:
        return CommandAction.unknown;
    }
  }

  Color? _extractColor(String text) {
    final colorMap = <String, Color>{
      '蓝色': Colors.blue,
      '红色': Colors.red,
      '绿色': Colors.green,
      '黑色': Colors.black,
      '白色': Colors.white,
      '紫色': Colors.purple,
      '橙色': Colors.orange,
      '粉色': Colors.pink,
      '灰色': Colors.grey,
      '青色': Colors.teal,
      '深色': const Color(0xFF0F0F0F),
      '深蓝': const Color(0xFF1A237E),
      '暗红': const Color(0xFFB71C1C),
    };
    for (final entry in colorMap.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    // 尝试解析 #RRGGBB
    final hexRegex = RegExp(r'#?([0-9A-Fa-f]{6})');
    final match = hexRegex.firstMatch(text);
    if (match != null) {
      final hex = int.parse('FF${match.group(1)!}', radix: 16);
      return Color(hex);
    }
    return null;
  }

  String _extractLabel(String text) {
    final possible = text.replaceAll(RegExp(r'[添加按钮]'), '').trim();
    if (possible.length < 6 && possible.isNotEmpty) return possible;
    return '快捷按钮';
  }

  Map<String, dynamic>? _parseJson(String jsonStr) {
    try {
      final cleaned = jsonStr
          .replaceAll('"', '"')
          .replaceAll('"', '"')
          .replaceAll("'", '"')
          .replaceAll(RegExp(r'\s'), '')
          .trim();
      if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
        final parts = cleaned.substring(1, cleaned.length - 1).split(',');
        final map = <String, dynamic>{};
        for (final part in parts) {
          final kv = part.split(':');
          if (kv.length == 2) {
            final key = kv[0].replaceAll('"', '').trim();
            final val = kv[1].replaceAll('"', '').trim();
            map[key] = val;
          }
        }
        return map;
      }
    } catch (_) {}
    return null;
  }

}
}
