import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/memory_db.dart';
import '../core/emotion_engine.dart';
import '../core/moments_engine.dart';
import '../core/proactive_chat_engine.dart';
import '../core/tts_engine.dart';
import '../core/command_engine.dart';
import '../core/ui_controller.dart';
import '../core/mode_manager.dart';
import '../core/memory/memory_router.dart';
import '../core/ai_router.dart';

class ChatPage extends StatefulWidget {
  final String characterName;
  final String characterEmoji;
  const ChatPage({
    super.key,
    this.characterName = 'AI',
    this.characterEmoji = '🤖',
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];
  bool _isThinking = false;
  bool _isExiting = false;
  bool _initialized = false;
  EmotionModel _emotion = EmotionModel();
  MomentsEngine? _momentsEngine;
  ProactiveChatEngine? _proactiveEngine;
  final TTSEngine _tts = TTSEngine();
  final CommandEngine _cmd = CommandEngine(uiController);
  bool _ttsLoading = false;
  // iOS 侧滑返回
  double _dragStartX = 0;
  double _dragOffset = 0;
  bool _isDragging = false;

  final AIRouter _aiRouter = AIRouter();

  String get _characterId => widget.characterName;
  final ModeManager _modeMgr = ModeManager.instance;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _modeMgr.modeNotifier.addListener(_onModeChanged);
    _initModeEngines();
  }

  void _onModeChanged() {
    if (!mounted) return;
    _initModeEngines();
    setState(() {});
  }

  /// 根据当前模式初始化/销毁引擎
  void _initModeEngines() {
    if (_modeMgr.isCompanion) {
      // 陪伴模式：初始化情感/朋友圈/主动消息引擎
      if (_momentsEngine == null) {
        _momentsEngine = MomentsEngine(characterId: _characterId, emotion: _emotion);
        _momentsEngine!.startMomentsLoop();
        // 注册朋友圈发布回调 → 联动聊天
        MomentsEngine.onMomentPublished = (moment) {
          if (!mounted) return;
          final followup = _proactiveEngine!.buildMomentFollowupMessage(moment);
          if (followup.message.isNotEmpty) {
            _receiveAiMessage(followup.message);
          }
        };
      }
      if (_proactiveEngine == null) {
        _proactiveEngine = ProactiveChatEngine(
          characterId: _characterId,
          emotion: _emotion,
          onAiMessage: ({required String message, required Map<String, dynamic>? context}) {
            if (!mounted) return;
            _receiveAiMessage(message);
          },
          momentsEngine: _momentsEngine!,
        );
        _proactiveEngine!.startProactiveLoop();
      }
    } else {
      // 助理模式：彻底销毁情感/朋友圈/主动消息引擎
      _proactiveEngine?.stopProactiveLoop();
      _proactiveEngine = null;
      _momentsEngine?.stopMomentsLoop();
      _momentsEngine = null;
    }
  }

  Future<void> _loadHistory() async {
    final rows = await MemoryRouter.readHistory(characterId: _characterId);
    final emotion = await EmotionDB.load(_characterId);
    if (!mounted) return;
    setState(() {
      _emotion = emotion;
      messages = rows.map((row) => {
            "role": row["role"] as String,
            "text": row["content"] as String,
          }).toList();
      _initialized = true;
    });
    _autoScroll();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add({"role": "user", "text": text});
      _isThinking = true;
    });
    MemoryRouter.writeMessage(characterId: _characterId, role: "user", content: text);

    // 陪伴模式下更新情绪
    if (_modeMgr.isCompanion) {
      _emotion.update("chat");
    }

    Future.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted) return;

      // 使用 AI 路由器处理输入
      final routeResult = await _aiRouter.routeInput(
        input: text,
        characterId: _characterId,
        emotion: _modeMgr.isCompanion ? _emotion : null,
        characterName: widget.characterName,
        characterEmoji: widget.characterEmoji,
      );

      String reply = routeResult.reply;

      // 助理模式：纯工具回答直接显示
      // 陪伴模式：情绪风格已经由 ai_router 处理
      String displayReply = reply;

      setState(() {
        _isThinking = false;
        messages.add({
          "role": "ai",
          "text": displayReply,
        });
      });

      MemoryRouter.writeMessage(characterId: _characterId, role: "ai", content: reply);

      // 陪伴模式下保存情绪状态并可能触发朋友圈
      if (_modeMgr.isCompanion) {
        EmotionDB.save(_characterId, _emotion);
        if (_emotion.love > 70 || _emotion.jealousy > 70 || _emotion.dependency > 70) {
          _momentsEngine?.triggerMomentByEmotion();
        }
      }

      _autoScroll();
    });
    _controller.clear();
  }

  /// 接收 AI 主动消息（插入列表 + 写 SQLite）
  void _receiveAiMessage(String message) {
    if (!mounted) return;
    setState(() {
      messages.add({
        "role": "ai",
        "text": message,
      });
    });
    MemoryRouter.writeMessage(characterId: _characterId, role: "ai", content: message);
  }

  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _modeMgr.modeNotifier.removeListener(_onModeChanged);
    _controller.dispose();
    _scrollController.dispose();
    _momentsEngine?.stopMomentsLoop();
    _proactiveEngine?.stopProactiveLoop();
    super.dispose();
  }

  // ============= 顶部模式切换按钮 =============

  Widget _buildModeToggle() {
    final isAssistant = _modeMgr.isAssistant;
    return GestureDetector(
      onTap: () {
        _modeMgr.switchMode();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isAssistant
              ? Colors.blue.withOpacity(0.2)
              : Colors.pink.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isAssistant
                ? Colors.blue.withOpacity(0.4)
                : Colors.pink.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _modeMgr.modeIcon,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              _modeMgr.modeLabel,
              style: TextStyle(
                color: isAssistant ? Colors.blue[200] : Colors.pink[200],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(String role, String text) {
    final isMe = role == "user";
    final crossAxisAlignment =
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final flex = isMe ? MainAxisAlignment.end : MainAxisAlignment.start;

    return GestureDetector(
      onLongPress: () {
        _tts.speak(text);
      },
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.blueAccent.withOpacity(0.25)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(18),
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: uiController.fontSize.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thinkingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      alignment: Alignment.centerLeft,
      child: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white54,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isExiting
        ? 0.92
        : (_isDragging
            ? 1.0 - (_dragOffset / (MediaQuery.of(context).size.width * 3))
            : 1.0);
    final opacity = _isExiting
        ? 0.0
        : (_isDragging
            ? 1.0 - (_dragOffset / MediaQuery.of(context).size.width)
            : 1.0);
    return PopScope(
      canPop: !_isExiting,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: GestureDetector(
        onHorizontalDragStart: (details) {
          _dragStartX = details.globalPosition.dx;
        },
        onHorizontalDragUpdate: (details) {
          if (_dragStartX > 40) return;
          setState(() {
            _isDragging = true;
            _dragOffset = details.globalPosition.dx - _dragStartX;
          });
        },
        onHorizontalDragEnd: (details) {
          if (_dragOffset > MediaQuery.of(context).size.width * 0.3) {
            Navigator.of(context).pop();
          } else {
            setState(() {
              _isDragging = false;
              _dragOffset = 0;
            });
          }
        },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 220),
          scale: scale,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: opacity,
            child: ValueListenableBuilder<Color>(
                valueListenable: uiController.themeColor,
                builder: (context, themeColor, _) => ValueListenableBuilder<double>(
                  valueListenable: uiController.fontSize,
                  builder: (context, fontSize, _) => Scaffold(
              backgroundColor: const Color(0xFF0B0B0F),
              body: SafeArea(
                child: Column(
                  children: [
                    // 顶部玻璃栏（含模式切换按钮）
                    ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 4),
                              Text(
                                "${widget.characterEmoji} ${widget.characterName}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              // 模式切换按钮
                              _buildModeToggle(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // 聊天列表
                    Expanded(
                      child: _initialized
                          ? ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(top: 10),
                              itemCount:
                                  messages.length + (_isThinking ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (_isThinking &&
                                    index == messages.length) {
                                  return _thinkingIndicator();
                                }
                                final msg = messages[index];
                                return _bubble(msg["role"]!, msg["text"]!);
                              })
                          : const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                    ),
                    // 输入栏 - 玻璃风格
                    ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          color: Colors.white.withOpacity(0.06),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: "输入消息...",
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 10),
                                  ),
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _sendMessage(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send_rounded,
                                    color: Colors.blueAccent),
                                onPressed: _sendMessage,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
