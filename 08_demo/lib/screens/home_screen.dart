/// 主屏幕组件
library;

import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/state_node.dart';
import '../widgets/layout/responsive_layout.dart';
import '../widgets/navigation/clotho_navigation_rail.dart';
import '../widgets/stage/message_bubble.dart';
import '../widgets/stage/input_area.dart';
import '../widgets/inspector/state_tree_viewer.dart';

/// 主屏幕
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TextEditingController _textController = TextEditingController();
  bool _isGenerating = false;
  final List<Message> _messages = [];
  late StateNode _rootNode;

  @override
  void initState() {
    super.initState();
    _initializeMessages();
    _initializeStateTree();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// 初始化示例消息
  void _initializeMessages() {
    _messages.addAll([
      Message.character(
        id: '1',
        content: '你好！我是你的角色扮演助手。有什么我可以帮助你的吗？',
      ),
      Message.user(
        id: '2',
        content: '我想开始一个新的角色扮演故事。',
      ),
      Message.character(
        id: '3',
        content: '好的！让我们开始吧。首先，请告诉我你想要什么样的故事背景？是奇幻世界、科幻未来，还是现代都市？',
      ),
    ]);
  }

  /// 初始化状态树
  void _initializeStateTree() {
    _rootNode = StateNode.root(
      id: 'root',
      name: 'Tapestry',
      children: [
        StateNode.object(
          id: 'pattern',
          name: 'Pattern',
          children: [
            StateNode.value(id: 'name', name: 'name', value: '示例角色'),
            StateNode.value(id: 'author', name: 'author', value: '作者'),
            StateNode.array(
              id: 'traits',
              name: 'traits',
              children: [
                StateNode.value(id: 't1', name: '0', value: '温柔'),
                StateNode.value(id: 't2', name: '1', value: '聪明'),
              ],
            ),
          ],
        ),
        StateNode.object(
          id: 'threads',
          name: 'Threads',
          children: [
            StateNode.object(
              id: 'thread1',
              name: 'Thread #1',
              children: [
                StateNode.value(
                  id: 'timestamp',
                  name: 'timestamp',
                  value: '2024-01-01T10:00:00Z',
                ),
                StateNode.value(
                  id: 'content',
                  name: 'content',
                  value: '你好！我是你的角色扮演助手。',
                ),
              ],
            ),
          ],
        ),
        StateNode.object(
          id: 'session',
          name: 'Session',
          children: [
            StateNode.value(id: 'id', name: 'id', value: 'session-001'),
            StateNode.value(
              id: 'startedAt',
              name: 'startedAt',
              value: '2024-01-01T10:00:00Z',
            ),
          ],
        ),
      ],
    );
  }

  /// 发送消息
  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(Message.user(id: DateTime.now().toString(), content: text));
      _textController.clear();
      _isGenerating = true;
    });

    // 模拟角色回复
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(
            Message.character(
              id: DateTime.now().toString(),
              content: '这是一个模拟回复。在实际应用中，这里会连接到 Jacquard 引擎和 Muse 智能服务。',
            ),
          );
          _isGenerating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      navigation: ClothoNavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      stage: _buildStage(context),
      inspector: StateTreeViewer(rootNode: _rootNode),
    );
  }

  /// 构建 Stage
  Widget _buildStage(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          InputArea(
            controller: _textController,
            onSend: _sendMessage,
            isGenerating: _isGenerating,
          ),
        ],
      ),
    );
  }
}
