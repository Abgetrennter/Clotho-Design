# 状态树查看器 (State Tree Viewer)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `00_active_specs/presentation/13-inspector.md`

---

## 1. 概述 (Overview)

状态树查看器是 Inspector 的核心组件，负责以树形结构展示 `Mnemosyne` 状态树。本规范定义树形视图的渲染和交互行为。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **层级清晰** | 通过缩进和图标展示层级关系 |
| **可折叠** | 支持展开/折叠子节点 |
| **类型标注** | 显示每个节点的数据类型 |
| **快速搜索** | 支持按路径或值搜索 |

---

## 2. 树节点模型 (Tree Node Model)

### 2.1 节点定义

```dart
class TreeNode {
  final String name;
  final String path;
  final dynamic value;
  final int level;
  final bool isExpanded;
  final bool hasChildren;

  TreeNode({
    required this.name,
    required this.path,
    required this.value,
    required this.level,
    this.isExpanded = false,
  }) : hasChildren = value is Map;
}
```

---

## 3. 树形渲染器 (Tree Renderer)

### 3.1 基础实现

```dart
class StateTreeViewer extends StatefulWidget {
  final Map<String, dynamic> stateTree;
  final String? selectedPath;
  final ValueChanged<String>? onPathSelected;

  @override
  _StateTreeViewerState createState() => _StateTreeViewerState();
}

class _StateTreeViewerState extends State<StateTreeViewer> {
  final Set<String> _expandedPaths = {};
  final TextEditingController _searchController = TextEditingController();
  List<TreeNode> _filteredNodes = [];

  @override
  void initState() {
    super.initState();
    _buildTree();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _buildTree() {
    _filteredNodes = _buildNodes(
      widget.stateTree,
      '',
      0,
    );
  }

  List<TreeNode> _buildNodes(
    Map<String, dynamic> map,
    String parentPath,
    int level,
  ) {
    final nodes = <TreeNode>[];

    for (final entry in map.entries) {
      final path = parentPath.isEmpty ? entry.key : '$parentPath.${entry.key}';
      final isExpanded = _expandedPaths.contains(path);

      nodes.add(TreeNode(
        name: entry.key,
        path: path,
        value: entry.value,
        level: level,
        isExpanded: isExpanded,
      ));

      if (entry.value is Map && isExpanded) {
        nodes.addAll(_buildNodes(
          entry.value as Map<String, dynamic>,
          path,
          level + 1,
        ));
      }
    }

    return nodes;
  }

  void _toggleExpansion(String path) {
    setState(() {
      if (_expandedPaths.contains(path)) {
        _expandedPaths.remove(path);
      } else {
        _expandedPaths.add(path);
      }
      _buildTree();
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      _buildTree();
      return;
    }

    // 搜索逻辑
    _filteredNodes = _searchNodes(
      widget.stateTree,
      '',
      0,
      query,
    );
  }

  List<TreeNode> _searchNodes(
    Map<String, dynamic> map,
    String parentPath,
    int level,
    String query,
  ) {
    final nodes = <TreeNode>[];

    for (final entry in map.entries) {
      final path = parentPath.isEmpty ? entry.key : '$parentPath.${entry.key}';
      final nameLower = entry.key.toLowerCase();
      final valueStr = entry.value.toString().toLowerCase();

      if (nameLower.contains(query) || valueStr.contains(query)) {
        nodes.add(TreeNode(
          name: entry.key,
          path: path,
          value: entry.value,
          level: level,
          isExpanded: true, // 搜索结果默认展开
        ));
      }

      if (entry.value is Map) {
        nodes.addAll(_searchNodes(
          entry.value as Map<String, dynamic>,
          path,
          level + 1,
          query,
        ));
      }
    }

    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索框
        Padding(
          padding: EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '搜索状态...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          ),
        ),
        Divider(color: Theme.of(context).colorScheme.divider),
        // 树形列表
        Expanded(
          child: ListView.builder(
            itemCount: _filteredNodes.length,
            itemBuilder: (context, index) {
              return _buildTreeNode(context, _filteredNodes[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTreeNode(BuildContext context, TreeNode node) {
    final isSelected = widget.selectedPath == node.path;
    final indent = node.level * 16.0;

    return Container(
      padding: EdgeInsets.only(left: indent),
      child: InkWell(
        onTap: () {
          if (node.hasChildren) {
            _toggleExpansion(node.path);
          }
          widget.onPathSelected?.call(node.path);
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // 展开/折叠图标
              Icon(
                node.hasChildren
                    ? (node.isExpanded ? Icons.expand_more : Icons.chevron_right)
                    : Icons.circle,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 8),
              // 节点名称
              Expanded(
                child: Text(
                  node.name,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              // 类型标签
              _buildTypeBadge(context, node.value),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(BuildContext context, dynamic value) {
    final type = _getValueType(value);
    final color = _getTypeColor(type);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getValueType(dynamic value) {
    if (value is String) return 'Str';
    if (value is int) return 'Int';
    if (value is double) return 'Dbl';
    if (value is bool) return 'Bool';
    if (value is List) return 'Arr';
    if (value is Map) return 'Obj';
    return 'Null';
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Str':
        return Colors.blue;
      case 'Int':
      case 'Dbl':
        return Colors.green;
      case 'Bool':
        return Colors.orange;
      case 'Arr':
        return Colors.purple;
      case 'Obj':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
```

---

## 4. 虚拟滚动 (Virtual Scrolling)

### 4.1 虚拟列表实现

```dart
class VirtualTreeViewer extends StatefulWidget {
  final Map<String, dynamic> stateTree;

  @override
  _VirtualTreeViewerState createState() => _VirtualTreeViewerState();
}

class _VirtualTreeViewerState extends State<VirtualTreeViewer> {
  final ScrollController _scrollController = ScrollController();
  final List<TreeNode> _nodes = [];
  static const double _itemHeight = 40.0;

  @override
  void initState() {
    super.initState();
    _buildTree();
  }

  void _buildTree() {
    // 构建所有节点
    _nodes.clear();
    _buildNodes(widget.stateTree, '', 0);
  }

  void _buildNodes(Map<String, dynamic> map, String parentPath, int level) {
    for (final entry in map.entries) {
      final path = parentPath.isEmpty ? entry.key : '$parentPath.${entry.key}';
      _nodes.add(TreeNode(
        name: entry.key,
        path: path,
        value: entry.value,
        level: level,
      ));

      if (entry.value is Map) {
        _buildNodes(entry.value as Map<String, dynamic>, path, level + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _nodes.length,
      itemBuilder: (context, index) {
        return SizedBox(
          height: _itemHeight,
          child: _buildTreeNode(context, _nodes[index]),
        );
      },
    );
  }

  Widget _buildTreeNode(BuildContext context, TreeNode node) {
    // ... 同基础实现
    return Container();
  }
}
```

---

## 5. 迁移对照表 (Migration Reference)

| 旧 UI 概念 | 新 UI 组件 | 变化 |
| :--- | :--- | :--- |
| JSON Tree | `StateTreeViewer` | 无 → 树形查看器 |
| 搜索功能 | `TextField` + 搜索逻辑 | 无 → 集成搜索 |
| 类型标注 | `_buildTypeBadge` | 无 → 类型标签 |

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`13-inspector.md`](./13-inspector.md) - Inspector 组件
