import 'package:flutter/material.dart';

import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/placeholder_kicker.dart';

class StateInspectorScreen extends StatelessWidget {
  const StateInspectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlaceholderKicker(
          title: 'Inspector',
          body:
              'The Inspector stays read-only. In V1 it should request schema and projections through the Jacquard UI adapter instead of reading Mnemosyne directly.',
        ),
        const SizedBox(height: SpacingTokens.lg),
        Expanded(
          child: AppSectionCard(
            child: ListView(
              children: [
                Text('Projected State', style: theme.textTheme.titleMedium),
                const SizedBox(height: SpacingTokens.md),
                const _TreeLine(depth: 0, label: r'session', value: '{...}'),
                const _TreeLine(depth: 1, label: r'id', value: 'session_001'),
                const _TreeLine(
                  depth: 1,
                  label: r'persona',
                  value: 'starter_guide',
                ),
                const _TreeLine(
                  depth: 0,
                  label: r'active_state',
                  value: '{...}',
                ),
                const _TreeLine(
                  depth: 1,
                  label: r'location',
                  value: 'weaving_hall',
                ),
                const _TreeLine(depth: 1, label: r'mood', value: 'steady'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TreeLine extends StatelessWidget {
  const _TreeLine({
    required this.depth,
    required this.label,
    required this.value,
  });

  final int depth;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: depth * SpacingTokens.lg,
        bottom: SpacingTokens.sm,
      ),
      child: Row(
        children: [
          Icon(
            depth == 0
                ? Icons.folder_open_outlined
                : Icons.subdirectory_arrow_right,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(width: SpacingTokens.sm),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
