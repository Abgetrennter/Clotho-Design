# 抽屉与面板 (Drawers & Sheets)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `99_archive/legacy_ui/09-弹窗系统.md`

---

## 1. 概述 (Overview)

Clotho 使用抽屉（Drawer）和底部面板（BottomSheet）来展示辅助内容和临时交互。本规范定义模态对话框、确认框、底部面板等弹窗组件的设计。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **层级清晰** | 弹窗层级高于主界面，有明确的遮罩 |
| **易于关闭** | 提供多种关闭方式（点击遮罩、ESC 键、关闭按钮） |
| **响应式** | 根据屏幕尺寸调整弹窗尺寸和位置 |
| **动画流畅** | 使用标准 Material 3 动画曲线 |

---

## 2. 模态对话框 (Modal Dialog)

### 2.1 基础实现

```dart
class ClothoDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content,
      actions: actions,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
```

### 2.2 响应式对话框

```dart
class ResponsiveDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? 400 : 600,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头部
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.divider),
            // 内容
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: content,
              ),
            ),
            // 底部操作
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 3. 确认对话框 (Confirmation Dialog)

### 3.1 基础实现

```dart
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          child: Text(confirmText),
        ),
      ],
    );
  }

  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = '确认',
    String cancelText = '取消',
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
      ),
    ).then((value) => value ?? false);
  }
}
```

---

## 4. 底部面板 (Bottom Sheet)

### 4.1 基础实现

```dart
class ClothoBottomSheet extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(color: Theme.of(context).colorScheme.divider),
          ],
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: content,
            ),
          ),
          if (actions != null) ...[
            Divider(color: Theme.of(context).colorScheme.divider),
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      builder: (context) => ClothoBottomSheet(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }
}
```

### 4.2 响应式底部面板

```dart
class ResponsiveBottomSheet extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      // 移动端：底部面板
      return ClothoBottomSheet(
        title: title,
        content: content,
        actions: actions,
      );
    } else {
      // 桌面端：对话框
      return ResponsiveDialog(
        title: title,
        content: content,
        actions: actions,
      );
    }
  }

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return showModalBottomSheet<T>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => ClothoBottomSheet(
          title: title,
          content: content,
          actions: actions,
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        builder: (context) => ResponsiveDialog(
          title: title,
          content: content,
          actions: actions,
        ),
      );
    }
  }
}
```

---

## 5. 侧边抽屉 (Side Drawer)

### 5.1 基础实现

```dart
class SideDrawer extends StatelessWidget {
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      child: child,
    );
  }
}
```

### 5.2 响应式抽屉

```dart
class ResponsiveDrawer extends StatelessWidget {
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      width: width ?? (isMobile ? 280 : 320),
      child: child,
    );
  }
}
```

---

## 6. 菜单 (Menu)

### 6.1 基础实现

```dart
class ClothoMenu extends StatelessWidget {
  final List<MenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          icon: Icon(Icons.more_vert),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
      menuChildren: entries.map((entry) {
        if (entry.isDivider) {
          return Divider();
        } else if (entry.isSubmenu) {
          return SubmenuButton(
            leadingIcon: Icon(entry.icon),
            label: Text(entry.label),
            menuChildren: entry.submenuEntries!.map((subEntry) {
              return MenuItemButton(
                leadingIcon: Icon(subEntry.icon),
                onPressed: subEntry.onPressed,
                child: Text(subEntry.label),
              );
            }).toList(),
          );
        } else {
          return MenuItemButton(
            leadingIcon: Icon(entry.icon),
            onPressed: entry.onPressed,
            child: Text(entry.label),
          );
        }
      }).toList(),
    );
  }
}

class MenuEntry {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isDivider;
  final bool isSubmenu;
  final List<MenuEntry>? submenuEntries;

  MenuEntry({
    required this.label,
    this.icon,
    this.onPressed,
    this.isDivider = false,
    this.isSubmenu = false,
    this.submenuEntries,
  });

  factory MenuEntry.divider() {
    return MenuEntry(label: '', isDivider: true);
  }

  factory MenuEntry.submenu({
    required String label,
    required IconData icon,
    required List<MenuEntry> entries,
  }) {
    return MenuEntry(
      label: label,
      icon: icon,
      isSubmenu: true,
      submenuEntries: entries,
    );
  }
}
```

---

## 7. 提示框 (Snackbar)

### 7.1 基础实现

```dart
class ClothoSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
    );
  }

  static void showSuccess({
    required BuildContext context,
    required String message,
  }) {
    show(
      context: context,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.success,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
  }) {
    show(
      context: context,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.error,
    );
  }
}
```

---

## 8. 迁移对照表 (Migration Reference)

| 旧 UI 元素 | 新 UI 组件 | 变化 |
| :--- | :--- | :--- |
| `.modal-overlay` | `Dialog`/`AlertDialog` | div → Material Dialog |
| `.modal` | `ResponsiveDialog` | div → Dialog |
| `.drawer` | `Drawer` | div → Drawer |
| `.bottom-sheet` | `BottomSheet` | div → BottomSheet |
| 提示框 | `SnackBar` | 自定义 → SnackBar |

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`08-navigation.md`](./08-navigation.md) - 导航系统
