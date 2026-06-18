import 'package:flutter/material.dart';

class ChatPagePlaceholder extends StatelessWidget {
  const ChatPagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('聊天页面 - 路由跳转')),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String characterName;
  final String characterEmoji;

  const ChatPage({
    super.key,
    required this.characterName,
    this.characterEmoji = '😊',
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool isLoading = false;

  void _sendMessage(String content) {
    if (content.trim().isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'content': content});
    });
    _controller.clear();

    // 模拟AI回复
    setState(() => isLoading = true);
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _messages.add({
          'role': 'ai',
          'content': _getMockReply(content),
        });
        isLoading = false;
      });
      _scrollToBottom();
    });
  }

  String _getMockReply(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('喜欢') || lower.contains('爱')) return '你...说的是真的吗？';
    if (lower.contains('忙') || lower.contains('没空')) return '嗯，你忙吧。';
    if (lower.contains('想') || lower.contains('念')) return '我也想你呀 ☺️';
    if (lower.contains('嗨') || lower.contains('你好') || lower.contains('hi')) return '嗨~ 你终于来找我了';
    return '嗯，我在听你说。';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(widget.characterEmoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(widget.characterName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (isLoading && index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      msg['content'] ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: '和${widget.characterName}聊天...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
