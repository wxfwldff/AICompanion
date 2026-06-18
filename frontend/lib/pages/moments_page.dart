import 'package:flutter/material.dart';

class MomentsPagePlaceholder extends StatelessWidget {
  const MomentsPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('朋友圈')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📝', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text('还没有朋友圈动态', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('聊天或等待一段时间后会自动生成', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  // Mock朋友圈数据
  final List<Map<String, dynamic>> _moments = [
    {'name': '小晴', 'emoji': '🌸', 'content': '今天心情很好 ☀️', 'time': '5分钟前', 'emotion': '😊', 'likes': 3, 'comments': '小雪: 真好~'},
    {'name': '阿杰', 'emoji': '🌊', 'content': '有些人好像更重要呢', 'time': '30分钟前', 'emotion': '😒', 'likes': 1, 'comments': ''},
    {'name': '小雪', 'emoji': '❄️', 'content': '今天有点安静...', 'time': '1小时前', 'emotion': '😔', 'likes': 5, 'comments': '小晴: 我在呢\n阿龙: +1'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('朋友圈')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _moments.length,
        itemBuilder: (context, index) {
          final m = _moments[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(m['emoji'], style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            Text(m['time'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Text(m['emotion'], style: const TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(m['content'], style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.favorite_border, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${m['likes']}', style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.comment_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${m['comments'].toString().split('\n').length}', style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  if (m['comments'].toString().isNotEmpty) ...[
                    const Divider(),
                    ...(m['comments'] as String).split('\n').map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(c, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    )),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
