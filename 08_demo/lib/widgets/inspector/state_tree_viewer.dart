/// Mnemosyne 状态树查看器组件
/// 对应文档: 00_active_specs/presentation/14-state-tree-viewer.md
library;

import 'package:flutter/material.dart';
import '../../models/state_node.dart';
import '../../theme/design_tokens.dart';

/// 状态树查看器组件
class StateTreeViewer extends StatefulWidget {
  const StateTreeViewer({
    super.key,
    required this.rootNode,
  });

  final StateNode rootNode;

  @override
  State<StateTreeViewer> createState() => _StateTreeViewerState();
}

class _StateTreeViewerState extends State<StateTreeViewer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const Divider(),
          Expanded(
            child: _buildTree(context, widget.rootNode),
          ),
        ],
      ),
    );
  }

  /// 构建头部
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(SpacingTokens.md),
      child: Row(
        children: [
          Icon(
            Icons.account_tree,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: SpacingTokens.sm),
          Text(
            'Mnemosyne State Tree',
            style: theme.textTheme.titleMedium,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
            tooltip: '刷新',
          ),
        ],
      ),
    );
  }

  /// 构建树
  Widget _buildTree(BuildContext context, StateNode node) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(SpacingTokens.sm),
      child: _buildNode(context, node, 0),
    );
  }

  /// 构建节点
  Widget _buildNode(BuildContext context, StateNode node, int depth) {
    final theme = Theme.of(context);
    final indent = depth * 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: indent),
          child: _buildNodeItem(context, node),
        ),
        if (node.isExpanded && node.hasChildren)
          ...node.children.map(
            (child) => _buildNode(context, child, depth + 1),
          ),
      ],
    );
  }

  /// 构建节点项
  Widget _buildNodeItem(BuildContext context, StateNode node) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          node.toggleExpanded();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: SpacingTokens.xs,
          horizontal: SpacingTokens.sm,
        ),
        child: Row(
          children: [
            _buildExpandIcon(context, node),
            const SizedBox(width: SpacingTokens.xs),
            _buildTypeIcon(context, node),
            const SizedBox(width: SpacingTokens.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (node.type == NodeType.value && node.value != null)
                    Text(
                      _formatValue(node.value),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建展开图标
  Widget _buildExpandIcon(BuildContext context, StateNode node) {
    final theme = Theme.of(context);

    if (!node.hasChildren) {
      return SizedBox(
        width: SizeTokens.iconSmall,
        height: SizeTokens.iconSmall,
      );
    }

    return Icon(
      node.isExpanded ? Icons.expand_more : Icons.chevron_right,
      size: SizeTokens.iconSmall,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  /// 构建类型图标
  Widget _buildTypeIcon(BuildContext context, StateNode node) {
    final theme = Theme.of(context);

    IconData icon;
    Color color;

    switch (node.type) {
      case NodeType.root:
        icon = Icons.folder_open;
        color = theme.colorScheme.primary;
        break;
      case NodeType.object:
        icon = Icons.data_object;
        color = theme.colorScheme.tertiary;
        break;
      case NodeType.array:
        icon = Icons.list;
        color = theme.colorScheme.secondary;
        break;
      case NodeType.value:
        icon = Icons.data_object;
        color = theme.colorScheme.onSurfaceVariant;
        break;
    }

    return Icon(
      icon,
      size: SizeTokens.iconSmall,
      color: color,
    );
  }

  /// 格式化值
  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    return value.toString();
  }
}
