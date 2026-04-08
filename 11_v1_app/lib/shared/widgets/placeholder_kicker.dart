import 'package:flutter/material.dart';

class PlaceholderKicker extends StatelessWidget {
  const PlaceholderKicker({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(body, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
