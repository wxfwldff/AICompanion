import 'package:flutter/material.dart';
import 'chat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Mock角色数据
  final List<Map<String, dynamic>> _characters = [
    {'name': '小晴', 'emoji': '🌸', 'desc': '阳光开朗的女生', 'status': '在线', 'chats': 0, 'emotion': '😊'},
    {'name': '阿杰', 'emoji': '🌊', 'desc': '沉稳理性的男生', 'status': '在线', 'chats': 0, 'emotion': '😐'},
    {'name': '小雪', 'emoji': '❄️', 'desc': '温柔安静的女孩', 'status': '在线', 'chats': 0, 'emotion': '😔'},
    {'name': '阿龙', 'emoji': '🔥', 'desc': '热情率真的男生', 'status': '在线', 'chats': 0, 'emotion': '😊'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('AI 社交世界'),
            SizedBox(width: 8),
            Text('🌍', style: TextStyle(fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.article_outlined),
            tooltip: '朋友圈',
            onPressed: () => _navigateTo(context, '/moments'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _navigateTo(context, '/settings'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _characters.length,
        itemBuilder: (context, index) {
          final char = _characters[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(char['emoji'], style: const TextStyle(fontSize: 28)),
              ),
              title: Row(
                children: [
                  Text(char['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(char['emotion'], style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(char['desc']),
                  const SizedBox(height: 4),
                  Text('聊天 ${char['chats']}次', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
              trailing: const Icon(Icons.chat_bubble_outline),
              onTap: () => _openChat(char),
            ),
          );
        },
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  void _openChat(Map<String, dynamic> char) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(characterName: char['name'], characterEmoji: char['emoji']),
      ),
    ).then((_) {
      // 返回后刷新
      setState(() {});
    });
  }
}