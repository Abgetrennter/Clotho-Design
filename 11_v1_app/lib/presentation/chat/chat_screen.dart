import 'package:flutter/material.dart';

import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/placeholder_kicker.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlaceholderKicker(
          title: 'Stage',
          body:
              'This is the V1 conversation shell. Streaming assistant output, intent submission, and recovery will be wired through Jacquard adapters once the runtime slices land.',
        ),
        const SizedBox(height: SpacingTokens.lg),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactLayout = constraints.maxWidth < 1100;

              if (compactLayout) {
                return ListView(
                  children: const [
                    _StageCard(compact: true),
                    SizedBox(height: SpacingTokens.md),
                    _RunwayCard(),
                  ],
                );
              }

              return const Row(
                children: [
                  Expanded(flex: 3, child: _StageCard()),
                  SizedBox(width: SpacingTokens.md),
                  Expanded(flex: 2, child: _RunwayCard()),
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
  const _StageCard({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ChatHeader(),
          const SizedBox(height: SpacingTokens.md),
          if (compact)
            const SizedBox(height: 220, child: _MessagePreviewList())
          else
            const Expanded(child: _MessagePreviewList()),
          const SizedBox(height: SpacingTokens.md),
          const _ChatInputPlaceholder(),
        ],
      ),
    );
  }
}

class _RunwayCard extends StatelessWidget {
  const _RunwayCard();

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Runway',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: SpacingTokens.md),
          _RunwayTile(
            title: 'Persona',
            body: 'Bind the active Persona manifest for the current Session.',
          ),
          SizedBox(height: SpacingTokens.sm),
          _RunwayTile(
            title: 'Jacquard',
            body:
                'Build PromptBundle, stream Muse output, and coordinate persistence.',
          ),
          SizedBox(height: SpacingTokens.sm),
          _RunwayTile(
            title: 'Mnemosyne',
            body: 'Persist turns, messages, active states, and state oplogs.',
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
                'The Stage stays UI-only here; real data will arrive through adapters.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessagePreviewList extends StatelessWidget {
  const _MessagePreviewList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _MessageBubblePreview(
          role: 'User',
          content: 'Create the V1 mainline without inheriting prototype debt.',
          isUser: true,
        ),
        SizedBox(height: SpacingTokens.sm),
        _MessageBubblePreview(
          role: 'Assistant',
          content:
              'The shell is ready. Next steps are Mnemosyne persistence, Jacquard orchestration, and Muse streaming.',
        ),
      ],
    );
  }
}

class _MessageBubblePreview extends StatelessWidget {
  const _MessageBubblePreview({
    required this.role,
    required this.content,
    this.isUser = false,
  });

  final String role;
  final String content;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final foreground = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
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

class _ChatInputPlaceholder extends StatelessWidget {
  const _ChatInputPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Message input will submit Intent through Jacquard...',
            ),
          ),
        ),
        const SizedBox(width: SpacingTokens.sm),
        FilledButton.icon(
          onPressed: null,
          icon: Icon(Icons.send),
          label: Text('Send'),
        ),
      ],
    );
  }
}

class _RunwayTile extends StatelessWidget {
  const _RunwayTile({required this.title, required this.body});

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
