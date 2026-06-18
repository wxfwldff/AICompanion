import 'package:flutter/material.dart';
import '../core/ui_controller.dart';
import '../core/mode_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _modeMgr = ModeManager.instance;

  // AI 配置
  final _providers = ['DeepSeek', '通义千问', 'OpenAI', '自定义'];
  String _selectedProvider = 'DeepSeek';
  final _baseUrlController = TextEditingController(text: 'https://api.deepseek.com');
  final _modelController = TextEditingController(text: 'deepseek-chat');
  final _apiKeyController = TextEditingController();

  @override
  void dispose() {
    _baseUrlController.dispose();
    _modelController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _pickColor(String label, ValueNotifier<Color> notifier) {
    final colors = [
      '0xFF0F0F0F', '0xFF1A1A2E', '0xFF16213E', '0xFF0F3460',
      '0xFF533483', '0xFF2D4059', '0xFF222831', '0xFF30475E',
    ];
    final labels = ['黑灰', '深紫', '深蓝', '靛蓝', '暗紫', '灰蓝', '深灰', '蓝灰'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('选择 $label'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(colors.length, (i) {
            final hex = colors[i];
            return _colorOption(context, labels[i], hex, notifier);
          }),
        ),
      ),
    );
  }

  Widget _colorOption(BuildContext ctx, String label, String hex, ValueNotifier<Color> notifier) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: _parseColor(hex)),
      title: Text(label),
      onTap: () {
        notifier.value = _parseColor(hex);
        Navigator.pop(ctx);
      },
    );
  }

  void _sizeOption(BuildContext ctx, double size, String label) {
    Navigator.pop(ctx);
    uiController.setFontSize(size);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF5F5F5);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ========== AI 模式切换 ==========
          _sectionHeader('AI 模式'),
          const SizedBox(height: 8),
          ValueListenableBuilder<AIMode>(
            valueListenable: _modeMgr.modeNotifier,
            builder: (context, mode, _) {
              final isAssistant = mode == AIMode.assistant;
              return Card(
                color: isDark ? const Color(0xFF1A1A1F) : Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _modeMgr.modeIcon,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _modeMgr.modeLabel,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: isAssistant
                                        ? Colors.blue[200]
                                        : Colors.pink[200],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _modeMgr.modeDescription,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isAssistant,
                            activeColor: Colors.blue,
                            inactiveThumbColor: Colors.pink,
                            onChanged: (_) {
                              _modeMgr.switchMode();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 模式说明
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isAssistant
                              ? Colors.blue
                              : Colors.pink).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAssistant
                                  ? Icons.psychology_outlined
                                  : Icons.favorite_outline,
                              color: isAssistant ? Colors.blue[200] : Colors.pink[200],
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAssistant
                                    ? '纯工具问答模式，不含情绪、角色扮演和朋友圈。适合快速获取信息和解决问题。'
                                    : '情感陪伴模式，具备情绪系统、朋友圈动态和主动消息功能。适合深度聊天和角色互动。',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // ========== AI 提供商 ==========
          _sectionHeader('AI 提供商'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedProvider,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: _providers.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) {
              setState(() => _selectedProvider = v!);
              switch (v) {
                case 'DeepSeek':
                  _baseUrlController.text = 'https://api.deepseek.com';
                  _modelController.text = 'deepseek-chat';
                  break;
                case '通义千问':
                  _baseUrlController.text = 'https://dashscope.aliyuncs.com/compatible-mode/v1';
                  _modelController.text = 'qwen-plus';
                  break;
                case 'OpenAI':
                  _baseUrlController.text = 'https://api.openai.com/v1';
                  _modelController.text = 'gpt-3.5-turbo';
                  break;
                case '自定义':
                  break;
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'Base URL',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: 'Model',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              labelText: 'API Key',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          // ========== UI 主题控制 ==========
          _sectionHeader('UI 主题'),
          const SizedBox(height: 8),

          // 主题色
          _settingTile(
            icon: Icons.palette_outlined,
            title: '主题色',
            subtitle: '当前: ${uiController.themeColor.value.toString()}',
            onTap: () => _pickColor('主题色', uiController.themeColor),
          ),
          // 字体颜色
          _settingTile(
            icon: Icons.text_fields,
            title: '字体颜色',
            subtitle: '当前: ${uiController.fontColor.value.toString()}',
            onTap: () => _pickColor('字体颜色', uiController.fontColor),
          ),
          // 字体大小
          _settingTile(
            icon: Icons.format_size,
            title: '字体大小',
            subtitle: '当前: ${uiController.fontSize.value.toInt()}px',
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('字体大小'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(title: const Text('小'), onTap: () => _sizeOption(ctx, 12.0, '小')),
                      ListTile(title: const Text('标准'), onTap: () => _sizeOption(ctx, 15.0, '标准')),
                      ListTile(title: const Text('大'), onTap: () => _sizeOption(ctx, 18.0, '大')),
                      ListTile(title: const Text('特大'), onTap: () => _sizeOption(ctx, 22.0, '特大')),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // ========== 功能开关 ==========
          _sectionHeader('功能开关'),
          const SizedBox(height: 8),
          // 玻璃效果
          ValueListenableBuilder<bool>(
            valueListenable: uiController.glassEffect,
            builder: (context, val, _) => SwitchListTile(
              title: const Text('玻璃效果'),
              subtitle: Text(val ? '已开启' : '已关闭'),
              value: val,
              onChanged: (v) => uiController.toggleGlass(),
            ),
          ),
          // TTS
          ValueListenableBuilder<bool>(
            valueListenable: uiController.ttsEnabledState,
            builder: (context, val, _) => SwitchListTile(
              title: const Text('语音朗读 (TTS)'),
              subtitle: Text(val ? '已开启' : '已关闭'),
              value: val,
              onChanged: (v) => v ? uiController.enableTTS() : uiController.disableTTS(),
            ),
          ),
          // 情绪系统
          ValueListenableBuilder<bool>(
            valueListenable: uiController.emotionEnabledState,
            builder: (context, val, _) => SwitchListTile(
              title: const Text('情绪系统'),
              subtitle: Text(val ? '已开启' : '已关闭'),
              value: val,
              onChanged: (v) {
                if (v) {
                  uiController.enableEmotion();
                } else {
                  uiController.disableEmotion();
                }
              },
            ),
          ),
          // 朋友圈系统
          ValueListenableBuilder<bool>(
            valueListenable: uiController.momentsEnabledState,
            builder: (context, val, _) => SwitchListTile(
              title: const Text('朋友圈系统'),
              subtitle: Text(val ? '已开启' : '已关闭'),
              value: val,
              onChanged: (v) => v ? uiController.enableMoments() : uiController.disableMoments(),
            ),
          ),
          // 主动消息
          ValueListenableBuilder<bool>(
            valueListenable: uiController.proactiveEnabledState,
            builder: (context, val, _) => SwitchListTile(
              title: const Text('主动消息'),
              subtitle: Text(val ? '已开启' : '已关闭'),
              value: val,
              onChanged: (v) => v ? uiController.enableProactive() : uiController.disableProactive(),
            ),
          ),
          const SizedBox(height: 24),
          // 保存按钮
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置已保存（本地mock）')),
              );
            },
            child: const Text('保存 AI 配置'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.grey[300],
      ),
    );
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('0x', '').replaceAll('#', '');
    return Color(int.parse(hex, radix: 16));
  }
}
