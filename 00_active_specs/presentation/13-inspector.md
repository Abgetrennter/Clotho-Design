# Inspector 组件 (Inspector Component)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `00_active_specs/presentation/README.md`

---

## 1. 概述 (Overview)

Inspector 是 Clotho Control 区域的核心组件，提供对 `Mnemosyne` 状态树的只读可视化界面。本规范定义 Inspector 的结构、Schema 驱动渲染和数据检视功能。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **只读访问** | Inspector 只能查看状态，不能直接修改 |
| **Schema 驱动** | 支持自定义 Schema 定义数据展示方式 |
| **实时同步** | 监听 Mnemosyne 状态流，实时更新 |
| **可扩展** | 支持第三方自定义渲染器 |

---

## 2. 组件结构 (Component Structure)

### 2.1 基础结构

```dart
class Inspector extends StatefulWidget {
  @override
  _InspectorState createState() => _InspectorState();
}

class _InspectorState extends State<Inspector> {
  final StreamSubscription _subscription;
  Map<String, dynamic> _stateTree = {};
  String _selectedPath = '';

  @override
  void initState() {
    super.initState();
    // 订阅 Mnemosyne 状态流
    _subscription = Mnemosyne.stateStream.listen((snapshot) {
      setState(() {
        _stateTree = snapshot;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          // 头部
          InspectorHeader(
            title: '数据检视器',
            onRefresh: () {
              // 刷新状态
            },
          ),
          Divider(color: Theme.of(context).colorScheme.divider),
          // 状态树
          Expanded(
            child: StateTreeViewer(
              stateTree: _stateTree,
              selectedPath: _selectedPath,
              onPathSelected: (path) {
                setState(() {
                  _selectedPath = path;
                });
              },
            ),
          ),
          // 详情面板
          if (_selectedPath.isNotEmpty)
            InspectorDetailPanel(
              path: _selectedPath,
              value: _getValueAtPath(_selectedPath),
            ),
        ],
      ),
    );
  }

  dynamic _getValueAtPath(String path) {
    final parts = path.split('.');
    dynamic current = _stateTree;

    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current;
  }
}
```

---

## 3. StateTreeViewer (状态树查看器)

### 3.1 基础实现

```dart
class StateTreeViewer extends StatelessWidget {
  final Map<String, dynamic> stateTree;
  final String selectedPath;
  final ValueChanged<String> onPathSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(8),
      children: [
        _buildTreeItem(
          context,
          name: 'root',
          value: stateTree,
          path: '',
          level: 0,
        ),
      ],
    );
  }

  Widget _buildTreeItem(
    BuildContext context, {
    required String name,
    required dynamic value,
    required String path,
    required int level,
  }) {
    final fullPath = path.isEmpty ? name : '$path.$name';
    final isSelected = fullPath == selectedPath;
    final hasChildren = value is Map;

    return Container(
      padding: EdgeInsets.only(left: level * 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 树节点
          InkWell(
            onTap: () => onPathSelected(fullPath),
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
                  Icon(
                    hasChildren
                        ? (isExpanded(fullPath) ? Icons.expand_more : Icons.chevron_right)
                        : Icons.circle,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (!hasChildren)
                    Text(
                      '(${_getValueType(value)})',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 子节点
          if (hasChildren && isExpanded(fullPath))
            ..._buildChildren(value, fullPath, level + 1),
        ],
      ),
    );
  }

  List<Widget> _buildChildren(
    Map<String, dynamic> map,
    String path,
    int level,
  ) {
    return map.entries
        .map((entry) => _buildTreeItem(
              context,
              name: entry.key,
              value: entry.value,
              path: path,
              level: level,
            ))
        .toList();
  }

  String _getValueType(dynamic value) {
    if (value is String) return 'String';
    if (value is int) return 'Int';
    if (value is double) return 'Double';
    if (value is bool) return 'Boolean';
    if (value is List) return 'Array';
    if (value is Map) return 'Object';
    return 'Unknown';
  }

  bool isExpanded(String path) {
    // 简化实现，实际应该维护展开状态
    return false;
  }
}
```

---

## 4. Schema 驱动渲染 (Schema-Driven Rendering)

### 4.1 Schema 定义

```dart
class UISchema {
  final String type; // 'table', 'card', 'list', 'tree'
  final Map<String, dynamic>? config;

  UISchema({
    required this.type,
    this.config,
  });

  factory UISchema.fromJson(Map<String, dynamic> json) {
    return UISchema(
      type: json['type'] ?? 'tree',
      config: json['config'],
    );
  }
}
```

### 4.2 Schema 渲染器

```dart
class SchemaDrivenRenderer extends StatelessWidget {
  final String path;
  final dynamic value;
  final UISchema? schema;

  @override
  Widget build(BuildContext context) {
    final renderer = schema ?? UISchema(type: 'tree');

    switch (renderer.type) {
      case 'table':
        return TableRenderer(
          value: value,
          config: renderer.config,
        );
      case 'card':
        return CardRenderer(
          value: value,
          config: renderer.config,
        );
      case 'list':
        return ListRenderer(
          value: value,
          config: renderer.config,
        );
      case 'tree':
      default:
        return TreeRenderer(
          value: value,
        );
    }
  }
}
```

### 4.3 表格渲染器

```dart
class TableRenderer extends StatelessWidget {
  final dynamic value;
  final Map<String, dynamic>? config;

  @override
  Widget build(BuildContext context) {
    if (value is! List) {
      return Text('数据不是数组');
    }

    final data = value as List;
    final columns = config?['columns'] as List<String>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns
              .map((col) => DataColumn(
                    label: Text(col),
                  ))
              .toList(),
          rows: data
              .map((row) => DataRow(
                    cells: columns
                        .map((col) => DataCell(
                              Text(row[col]?.toString() ?? ''),
                            ))
                        .toList(),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
```

---

## 5. InspectorDetailPanel (详情面板)

### 5.1 基础实现

```dart
class InspectorDetailPanel extends StatelessWidget {
  final String path;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.divider,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 路径
          Text(
            '路径',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4),
          Text(
            path,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'Courier New',
            ),
          ),
          SizedBox(height: 16),
          // 类型
          Text(
            '类型',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4),
          Chip(
            label: Text(_getValueType(value)),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(height: 16),
          // 值
          Text(
            '值',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 4),
          _buildValueWidget(context, value),
        ],
      ),
    );
  }

  Widget _buildValueWidget(BuildContext context, dynamic value) {
    if (value is String) {
      return Text(value);
    } else if (value is int || value is double) {
      return Text(value.toString());
    } else if (value is bool) {
      return Text(value ? 'true' : 'false');
    } else if (value is List) {
      return Text('[${value.length} items]');
    } else if (value is Map) {
      return Text('{${value.length} keys}');
    } else {
      return Text('null');
    }
  }

  String _getValueType(dynamic value) {
    if (value is String) return 'String';
    if (value is int) return 'Int';
    if (value is double) return 'Double';
    if (value is bool) return 'Boolean';
    if (value is List) return 'Array';
    if (value is Map) return 'Object';
    return 'Unknown';
  }
}
```

---

## 6. 响应式适配 (Responsive Adaptation)

### 6.1 移动端适配

```dart
class ResponsiveInspector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // 移动端：通过 BottomSheet 呼出
      return Container(); // 由触发器打开
    } else if (MediaQuery.of(context).size.width < 840) {
      // 平板：默认隐藏，通过按钮呼出
      return Container(); // 由触发器打开
    } else {
      // 桌面：右侧固定面板
      return Inspector();
    }
  }
}
```

---

## 7. 迁移对照表 (Migration Reference)

| 旧 UI 概念 | 新 UI 组件 | 变化 |
| :--- | :--- | :--- |
| ACU Visualizer | `Inspector` | 独立组件 → 集成组件 |
| JSON Tree | `StateTreeViewer` | 无 → 树形查看器 |
| Schema 渲染 | `SchemaDrivenRenderer` | 无 → 统一渲染器 |

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`14-state-tree-viewer.md`](./14-state-tree-viewer.md) - 状态树查看器
- [`../mnemosyne/README.md`](../mnemosyne/README.md) - Mnemosyne 数据引擎
