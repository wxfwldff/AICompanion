import 'package:flutter/material.dart';
import 'chat_page.dart';
import '../core/memory_db.dart';
import '../core/emotion_engine.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> _characters = [
    {'name': '小晴', 'emoji': '🌸', 'desc': '阳光开朗的女生'},
    {'name': '阿杰', 'emoji': '🌊', 'desc': '沉稳理性的男生'},
    {'name': '小雪', 'emoji': '❄️', 'desc': '温柔安静的女孩'},
    {'name': '阿龙', 'emoji': '🔥', 'desc': '热情率真的男生'},
  ];

  Map<String, int> _chatCounts = {};
  Map<String, String> _charEmotions = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final db = await MemoryDB.instance;
    for (final c in _characters) {
      final name = c['name']!;
      final count = await db.getMessageCount(name);
      final emo = await EmotionDB.load(name);
      _chatCounts[name] = count;
      if (emo != null) {
        _charEmotions[name] = emo.moodLabel;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('AI 社交世界', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.article_outlined),
            tooltip: '朋友圈',
            onPressed: () => Navigator.pushNamed(context, '/moments', arguments: {
              'name': '小晴',
              'emoji': '🌸',
            }),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _characters.length + 1, // +1 for global stats
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildGlobalStats();
          }
          final char = _characters[index - 1];
          final name = char['name']!;
          final count = _chatCounts[name] ?? 0;
          final emotion = _charEmotions[name] ?? '😊';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
            ),
            color: isDark ? const Color(0xFF1A1A24) : Colors.white,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openChat(char),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                      child: Text(char['emoji']!, style: const TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(emotion, style: const TextStyle(fontSize: 14)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            char['desc']!,
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '聊天 $count 次',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlobalStats() {
    final totalChats = _chatCounts.values.fold(0, (a, b) => a + b);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.purple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white24,
            child: Text('🤖', style: TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 社交世界',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '与你对话 $totalChats 次',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_characters.length} 个角色',
              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  void _openChat(Map<String, String> char) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          characterName: char['name']!,
          characterEmoji: char['emoji']!,
        ),
      ),
    ).then((_) {
      _loadStats();
    });
  }
}
