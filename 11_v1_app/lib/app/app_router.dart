import 'package:flutter/material.dart';

import '../presentation/chat/chat_screen.dart';
import '../presentation/session_list/session_list_screen.dart';
import '../presentation/settings/settings_screen.dart';
import '../presentation/state_inspector/state_inspector_screen.dart';

enum AppDestination {
  sessions(
    label: 'Sessions',
    icon: Icons.forum_outlined,
    selectedIcon: Icons.forum,
  ),
  chat(
    label: 'Stage',
    icon: Icons.auto_awesome_mosaic_outlined,
    selectedIcon: Icons.auto_awesome_mosaic,
  ),
  inspector(
    label: 'Inspector',
    icon: Icons.account_tree_outlined,
    selectedIcon: Icons.account_tree,
  ),
  settings(
    label: 'Settings',
    icon: Icons.tune_outlined,
    selectedIcon: Icons.tune,
  );

  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

Widget buildDestinationScreen(AppDestination destination) {
  switch (destination) {
    case AppDestination.sessions:
      return const SessionListScreen();
    case AppDestination.chat:
      return const ChatScreen();
    case AppDestination.inspector:
      return const StateInspectorScreen();
    case AppDestination.settings:
      return const SettingsScreen();
  }
}
