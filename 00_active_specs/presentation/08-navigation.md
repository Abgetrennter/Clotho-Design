# 导航系统 (Navigation System)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `99_archive/legacy_ui/07-导航系统.md`

---

## 1. 概述 (Overview)

Clotho 导航系统基于响应式三栏架构，根据屏幕尺寸自动切换导航方式。本规范定义顶部导航栏、NavigationRail、NavigationDrawer 等导航组件的设计。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **自适应** | 根据屏幕尺寸自动切换导航方式 |
| **一致性** | 跨平台保持统一的导航体验 |
| **可访问性** | 支持键盘导航和屏幕阅读器 |
| **状态反馈** | 当前页面有清晰的视觉反馈 |

---

## 2. 响应式导航策略 (Responsive Navigation Strategy)

### 2.1 导航模式

| 屏幕尺寸 | 导航方式 | 组件 |
| :--- | :--- | :--- |
| **Mobile** (≤ 600dp) | 抽屉导航 | `NavigationDrawer` |
| **Tablet** (600-839dp) | 侧边栏导航 | `NavigationRail` |
| **Desktop** (≥ 840dp) | 面板导航 | `NavigationPane` |

### 2.2 自适应导航组件

```dart
class AdaptiveNavigation extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return MobileNavigationDrawer();
        } else if (constraints.maxWidth < 840) {
          return NavigationRail();
        } else {
          return NavigationPane();
        }
      },
    );
  }
}
```

---

## 3. 顶部导航栏 (Top Navigation Bar)

### 3.1 基础结构

```dart
class TopNavigationBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 0,
      toolbarHeight: 56,
      leading: Builder(
        builder: (context) {
          final isMobile = MediaQuery.of(context).size.width < 600;
          return IconButton(
            icon: Icon(isMobile ? Icons.menu : Icons.arrow_back),
            onPressed: () {
              if (isMobile) {
                Scaffold.of(context).openDrawer();
              } else {
                Navigator.of(context).pop();
              }
            },
          );
        },
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: actions,
    );
  }
}
```

### 3.2 响应式适配

```dart
class ResponsiveTopBar extends StatelessWidget {
  final String title;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      elevation: 0,
      toolbarHeight: isMobile ? 56 : 50,
      leading: isMobile
          ? Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            )
          : null,
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: isMobile ? 16 : 18,
        ),
      ),
    );
  }
}
```

---

## 4. NavigationRail (侧边栏导航)

### 4.1 基础实现

```dart
class ClothoNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      destinations: [
        NavigationRailDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: Text('对话'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.book_outline),
          selectedIcon: Icon(Icons.book),
          label: Text('Lore (纹理)'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Pattern (织谱)'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('设置'),
        ),
      ],
    );
  }
}
```

### 4.2 带扩展的 NavigationRail

```dart
class ExtendedNavigationRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      extended: true,
      destinations: [
        NavigationRailDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: Text('对话'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.book_outline),
          selectedIcon: Icon(Icons.book),
          label: Text('Lore (纹理)'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Pattern (织谱)'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('设置'),
        ),
      ],
    );
  }
}
```

---

## 5. NavigationDrawer (抽屉导航)

### 5.1 基础实现

```dart
class ClothoNavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clotho',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'AI 角色扮演引擎',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: Text('对话'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.book_outline),
          selectedIcon: Icon(Icons.book),
          label: Text('Lore (纹理)'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Pattern (织谱)'),
        ),
        const Divider(),
        NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('设置'),
        ),
      ],
    );
  }
}
```

---

## 6. NavigationPane (面板导航)

### 6.1 基础实现

```dart
class NavigationPane extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          // 头部
          Container(
            padding: EdgeInsets.all(16),
            child: Text(
              'Clotho',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Divider(
            color: Theme.of(context).colorScheme.divider,
          ),
          // 导航项
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavigationItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  selectedIcon: Icons.chat_bubble,
                  label: '对话',
                  index: 0,
                  selectedIndex: selectedIndex,
                  onTap: onDestinationSelected,
                ),
                _buildNavigationItem(
                  context,
                  icon: Icons.book_outline,
                  selectedIcon: Icons.book,
                  label: 'Lore (纹理)',
                  index: 1,
                  selectedIndex: selectedIndex,
                  onTap: onDestinationSelected,
                ),
                _buildNavigationItem(
                  context,
                  icon: Icons.person_outline,
                  selectedIcon: Icons.person,
                  label: 'Pattern (织谱)',
                  index: 2,
                  selectedIndex: selectedIndex,
                  onTap: onDestinationSelected,
                ),
                Divider(
                  color: Theme.of(context).colorScheme.divider,
                ),
                _buildNavigationItem(
                  context,
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: '设置',
                  index: 3,
                  selectedIndex: selectedIndex,
                  onTap: onDestinationSelected,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required int selectedIndex,
    required ValueChanged<int> onTap,
  }) {
    final isSelected = index == selectedIndex;

    return ListTile(
      leading: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onTap: () => onTap(index),
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.12),
    );
  }
}
```

---

## 7. 迁移对照表 (Migration Reference)

| 旧 UI 元素 | 新 UI 组件 | 变化 |
| :--- | :--- | :--- |
| `#top-bar` | `TopNavigationBar` | div → AppBar |
| `#left-nav-panel` | `NavigationDrawer` | div → NavigationDrawer |
| 侧边栏 | `NavigationRail` | 自定义 → Material 3 |
| 导航链接 | `NavigationDestination` | a → NavigationDestination |

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`09-drawers-sheets.md`](./09-drawers-sheets.md) - 抽屉与面板
