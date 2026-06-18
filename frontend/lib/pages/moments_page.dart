import 'package:flutter/material.dart';
import '../core/moments_engine.dart';
import '../models/moment_model.dart';

/// 朋友圈页面 —— 按时间倒序展示AI角色的动态
class MomentsPage extends StatefulWidget {
  final String characterName;
  final String characterEmoji;

  const MomentsPage({
    super.key,
    required this.characterName,
    this.characterEmoji = '🤖',
  });

  @override
  State<MomentsPage> createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  List<Moment> _moments = [];
  bool _loading = true;

  String get _characterId => widget.characterName;

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    final list = await MomentsEngine.getMoments(_characterId);
    if (!mounted) return;
    setState(() {
      _moments = list;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await _loadMoments();
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${dt.month}/${dt.day}';
  }

  IconData _emotionIcon(String state) {
    switch (state) {
      case '吃醋':
        return Icons.sentiment_dissatisfied;
      case '喜欢':
        return Icons.favorite;
      case '冷淡':
        return Icons.ac_unit;
      case '依赖':
        return Icons.link;
      case '想你':
        return Icons.nightlight_round;
      default:
        return Icons.sentiment_satisfied;
    }
  }

  Color _emotionColor(String state) {
    switch (state) {
      case '吃醋':
        return Colors.purpleAccent;
      case '喜欢':
        return Colors.pinkAccent;
      case '冷淡':
        return Colors.blueGrey;
      case '依赖':
        return Colors.orangeAccent;
      case '想你':
        return Colors.indigoAccent;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0F),
        title: Text(
          '${widget.characterEmoji} ${widget.characterName} 的动态',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white54))
          : _moments.isEmpty
              ? const Center(
                  child: Text(
                    '还没有动态\n等AI发一条吧',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 15),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: Colors.blueAccent,
                  backgroundColor: const Color(0xFF1A1A24),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _moments.length,
                    itemBuilder: (context, index) {
                      final moment = _moments[index];
                      return _momentCard(moment);
                    },
                  ),
                ),
    );
  }

  Widget _momentCard(Moment moment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：头像+角色名+时间
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: Text(
                      widget.characterEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.characterName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    _formatTime(moment.timestamp),
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 正文
              Text(
                moment.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              // 图片占位（预留）
              if (moment.imageUrl != null) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    moment.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 160,
                        color: Colors.white.withOpacity(0.04),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white24,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 160,
                        color: Colors.white.withOpacity(0.04),
                        child: Center(
                          child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 40),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
              // 情绪标签
              Row(
                children: [
                  Icon(
                    _emotionIcon(moment.emotionState),
                    size: 14,
                    color: _emotionColor(moment.emotionState),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    moment.emotionState,
                    style: TextStyle(
                      color: _emotionColor(moment.emotionState),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
