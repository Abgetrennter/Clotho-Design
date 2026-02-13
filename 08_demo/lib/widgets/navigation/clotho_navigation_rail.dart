/// Clotho 导航栏组件
/// 对应文档: 00_active_specs/presentation/08-navigation.md
library;

import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// 导航项
enum NavigationItem {
  /// Stage - 聊天舞台
  stage,
  /// Pattern - 角色卡
  pattern,
  /// Tapestry - 存档
  tapestry,
  /// Settings - 设置
  settings,
}

/// Clotho 导航栏组件
class ClothoNavigationRail extends StatelessWidget {
  const ClothoNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      leading: _buildLeading(context),
      destinations: _buildDestinations(context),
    );
  }

  /// 构建头部 Logo
  Widget _buildLeading(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Column(
        children: [
          Icon(
            Icons.auto_awesome,
            size: SizeTokens.iconLarge,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: SpacingTokens.xs),
          Text(
            'Clotho',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建导航目标
  List<NavigationRailDestination> _buildDestinations(BuildContext context) {
    return const [
      NavigationRailDestination(
        icon: Icon(Icons.chat_bubble_outline),
        selectedIcon: Icon(Icons.chat_bubble),
        label: Text('Stage'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.description_outlined),
        selectedIcon: Icon(Icons.description),
        label: Text('Pattern'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.folder_open),
        selectedIcon: Icon(Icons.folder),
        label: Text('Tapestry'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
    ];
  }
}
