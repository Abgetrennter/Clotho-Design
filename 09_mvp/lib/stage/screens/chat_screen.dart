import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';
import '../widgets/message_list.dart';
import '../widgets/input_area.dart';

/// ChatScreen - 聊天主界面
///
/// 包含消息列表和输入区域
class ChatScreen extends ConsumerStatefulWidget {
  final String personaId;

  const ChatScreen({
    super.key,
    required this.personaId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (!_isInitialized) {
      await ref.read(chatProvider.notifier).initializeSession(widget.personaId);
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);

    // 监听状态变化，自动滚动
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatState.turns.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clotho MVP Demo'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: MessageList(
              turns: chatState.turns,
              scrollController: _scrollController,
              isLoading: chatState.isLoading,
            ),
          ),

          // 错误提示
          if (chatState.error != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.withOpacity(0.1),
              child: Text(
                chatState.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          // 输入区域
          InputArea(
            onSend: (text) {
              ref.read(chatProvider.notifier).sendMessage(text);
            },
            onStop: () {
              ref.read(chatProvider.notifier).stopGeneration();
            },
            isLoading: chatState.isLoading,
            hintText: chatState.isLoading ? '生成中...' : '输入消息...',
          ),
        ],
      ),
    );
  }
}
