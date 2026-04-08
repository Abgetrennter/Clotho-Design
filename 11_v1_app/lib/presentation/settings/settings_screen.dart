import 'package:flutter/material.dart';

import '../../shared/theme/design_tokens.dart';
import '../../shared/widgets/app_section_card.dart';
import '../../shared/widgets/placeholder_kicker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PlaceholderKicker(
          title: 'Settings',
          body:
              'Provider selection, diagnostics toggles, and Persona asset paths will move here once the first runnable chain is in place.',
        ),
        const SizedBox(height: SpacingTokens.lg),
        Expanded(
          child: ListView(
            children: const [
              _SettingTile(
                title: 'Muse Gateway',
                subtitle: 'Choose provider, endpoint, and model defaults.',
              ),
              SizedBox(height: SpacingTokens.md),
              _SettingTile(
                title: 'Diagnostics',
                subtitle: 'Control logging visibility and debug surfaces.',
              ),
              SizedBox(height: SpacingTokens.md),
              _SettingTile(
                title: 'Persona Library',
                subtitle:
                    'Configure where Persona manifests and assets are discovered.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
