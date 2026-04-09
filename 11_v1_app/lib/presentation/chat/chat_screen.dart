import 'package:flutter/material.dart';

import '../../bootstrap/service_registry.dart';
import '../../jacquard/application/send_message_use_case.dart';
import '../../jacquard/domain/prompt_bundle.dart';
import '../../mnemosyne/domain/message.dart';
import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/placeholder_kicker.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  List<Message> _messages = const <Message>[];
  Map<String, Object?> _activeState = const <String, Object?>{};

  ServiceRegistry get _registry => ServiceRegistry.instance;

  @override
  void initState() {
    super.initState();
    _loadSessionView();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSessionView() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final view = await _registry.loadSessionViewUseCase.execute(
        _registry.activeSessionId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = view.messages;
        _activeState = view.activeState;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
      _error = null;
    });

    try {
      await _registry.sendMessageUseCase.execute(
        SendMessageRequest(
          sessionId: _registry.activeSessionId,
          userMessage: text,
          promptBundle: const PromptBundle(
            systemPrompt:
                'Return canonical filament_output with thought and content.',
            userPrompt:
                'Respond concisely. Use state_update only for legitimate JSON Pointer updates.',
          ),
        ),
      );
      _controller.clear();
      await _loadSessionView();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isSending = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlaceholderKicker(
          title: 'Stage',
          body:
              'This screen is now wired to the local Jacquard and Mnemosyne demo runtime. Messages are sent through the application use case, not directly to persistence.',
        ),
        const SizedBox(height: SpacingTokens.lg),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactLayout = constraints.maxWidth < 1100;

              if (compactLayout) {
                return ListView(
                  children: [
                    _StageCard(
                      compact: true,
                      controller: _controller,
                      messages: _messages,
                      isLoading: _isLoading,
                      isSending: _isSending,
                      error: _error,
                      onSend: _sendMessage,
                    ),
                    const SizedBox(height: SpacingTokens.md),
                    _RunwayCard(
                      activeState: _activeState,
                      isSending: _isSending,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _StageCard(
                      controller: _controller,
                      messages: _messages,
                      isLoading: _isLoading,
                      isSending: _isSending,
                      error: _error,
                      onSend: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.md),
                  Expanded(
                    flex: 2,
                    child: _RunwayCard(
                      activeState: _activeState,
                      isSending: _isSending,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.controller,
    required this.messages,
    required this.isLoading,
    required this.isSending,
    required this.onSend,
    this.error,
    this.compact = false,
  });

  final TextEditingController controller;
  final List<Message> messages;
  final bool isLoading;
  final bool isSending;
  final Future<void> Function() onSend;
  final String? error;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChatHeader(),
          const SizedBox(height: SpacingTokens.md),
          if (error != null) ...[
            _ErrorBanner(message: error!),
            const SizedBox(height: SpacingTokens.md),
          ],
          if (compact)
            SizedBox(
              height: 320,
              child: _MessageList(messages: messages, isLoading: isLoading),
            )
          else
            Expanded(
              child: _MessageList(messages: messages, isLoading: isLoading),
            ),
          const SizedBox(height: SpacingTokens.md),
          _ChatInput(
            controller: controller,
            isSending: isSending,
            onSend: onSend,
          ),
        ],
      ),
    );
  }
}

class _RunwayCard extends StatelessWidget {
  const _RunwayCard({
    required this.activeState,
    required this.isSending,
  });

  final Map<String, Object?> activeState;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    final character = activeState['character'];
    final session = activeState['session'];

    final mood = switch (character) {
      {'mood': final Object value} => value.toString(),
      _ => 'unset',
    };
    final turnCount = switch (session) {
      {'turnCount': final Object value} => value.toString(),
      _ => '0',
    };

    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Runway',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: SpacingTokens.md),
          _RunwayTile(
            title: 'Runtime',
            body: isSending ? 'Sending through Jacquard...' : 'Idle',
          ),
          const SizedBox(height: SpacingTokens.sm),
          _RunwayTile(title: 'Character Mood', body: mood),
          const SizedBox(height: SpacingTokens.sm),
          _RunwayTile(title: 'Turn Count', body: turnCount),
          const SizedBox(height: SpacingTokens.sm),
          const _RunwayTile(
            title: 'Boundary',
            body:
                'UI -> SendMessageUseCase -> MuseRawGateway -> FilamentParser -> TurnRepository',
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.hub_outlined,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: SpacingTokens.md),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Session',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: SpacingTokens.xs),
              Text(
                'Stage is backed by the minimal local pipeline and transaction commit path.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.isLoading,
  });

  final List<Message> messages;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return const Center(child: Text('No messages yet.'));
    }

    return ListView.separated(
      itemCount: messages.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: SpacingTokens.sm),
      itemBuilder: (context, index) {
        final message = messages[index];
        return _MessageBubble(
          role: _roleLabel(message),
          content: message.content,
          isUser: message.role == MessageRole.user,
          isThought: message.type == MessageType.thought,
        );
      },
    );
  }

  String _roleLabel(Message message) {
    if (message.type == MessageType.thought) {
      return 'Thought';
    }
    switch (message.role) {
      case MessageRole.user:
        return 'User';
      case MessageRole.assistant:
        return 'Assistant';
      case MessageRole.system:
        return 'System';
    }
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.role,
    required this.content,
    this.isUser = false,
    this.isThought = false,
  });

  final String role;
  final String content;
  final bool isUser;
  final bool isThought;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch ((isUser, isThought)) {
      (true, _) => theme.colorScheme.primaryContainer,
      (false, true) => theme.colorScheme.tertiaryContainer,
      _ => theme.colorScheme.surfaceContainerHighest,
    };
    final foreground = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
          ),
          child: Padding(
            padding: const EdgeInsets.all(SpacingTokens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: SpacingTokens.xs),
                Text(content, style: TextStyle(color: foreground)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            enabled: !isSending,
            onSubmitted: (_) => onSend(),
            decoration: const InputDecoration(
              hintText: 'Send a message through the demo Jacquard pipeline...',
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        FilledButton.icon(
          onPressed: isSending ? null : onSend,
          icon: isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(isSending ? 'Sending' : 'Send'),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}

class _RunwayTile extends StatelessWidget {
  const _RunwayTile({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SpacingTokens.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: SpacingTokens.xs),
            Text(body),
          ],
        ),
      ),
    );
  }
}
