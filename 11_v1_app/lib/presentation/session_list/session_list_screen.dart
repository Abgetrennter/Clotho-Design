import 'package:flutter/material.dart';

import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/placeholder_kicker.dart';

class SessionListScreen extends StatelessWidget {
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlaceholderKicker(
          title: 'Session List',
          body:
              'This page is reserved for the V1 session index. It will open, restore, and delete sessions through Jacquard use cases instead of touching persistence directly.',
        ),
        const SizedBox(height: SpacingTokens.lg),
        Expanded(
          child: ListView.separated(
            itemCount: 5,
            separatorBuilder: (context, index) =>
                const SizedBox(height: SpacingTokens.md),
            itemBuilder: (context, index) {
              return AppSectionCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Text('${index + 1}'),
                  ),
                  title: Text('Session ${index + 1}'),
                  subtitle: const Text(
                    'Persona binding, recent turn, and restore metadata will live here.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
