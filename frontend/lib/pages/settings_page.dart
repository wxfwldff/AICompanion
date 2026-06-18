import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController(text: 'https://api.deepseek.com');
  final _modelController = TextEditingController(text: 'deepseek-chat');
  String _selectedProvider = 'DeepSeek';

  final List<String> _providers = ['DeepSeek', '通义千问', 'OpenAI', '自定义'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('AI 提供商', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedProvider,
            decoration: const InputDecoration(border: OutlineInputBorder()),
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
          const SizedBox(height: 16),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(labelText: 'Base URL', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(labelText: 'Model', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(labelText: 'API Key', border: OutlineInputBorder()),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置已保存（本地mock）')),
              );
            },
            child: const Text('保存设置'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }
}
