# 可访问性规范 (Accessibility)

**版本**: 1.0.0
**日期**: 2026-02-26
**状态**: Draft
**类型**: Implementation Guide
**作者**: Clotho 架构团队

---

## 1. 概述 (Overview)

本规范定义了 Clotho 表现层的可访问性（Accessibility，简称 a11y）标准，确保应用对所有用户（包括有视觉、听觉、运动或认知障碍的用户）都易于使用。可访问性不仅是法律要求，也是提升用户体验的重要方面。

### 1.1 核心可访问性原则

| 原则 | 说明 | 示例 |
| :--- | :--- | :--- |
| **可感知性** | 信息必须以用户能够感知的方式呈现 | 为图像提供替代文本，为视频提供字幕 |
| **可操作性** | UI 组件必须可操作 | 所有功能可通过键盘访问，提供足够的时间响应 |
| **可理解性** | 信息和 UI 操作必须可理解 | 使用清晰的语言，一致的导航模式 |
| **鲁棒性** | 内容必须足够鲁棒，可被各种用户代理（包括辅助技术）可靠地解释 | 使用标准 HTML 元素，确保兼容性 |

### 1.2 可访问性目标

| 目标 | 标准 | 说明 |
| :--- | :--- | :--- |
| **WCAG 2.1 AA** | 符合 WCAG 2.1 AA 级标准 | 国际通用的可访问性标准 |
| **键盘导航** | 所有功能可通过键盘访问 | 支持 Tab、方向键等键盘操作 |
| **屏幕阅读器** | 兼容主流屏幕阅读器 | Windows Narrator、Android TalkBack、Web NVDA |
| **颜色对比度** | 符合 WCAG 对比度要求 | 文本对比度至少 4.5:1，大文本 3:1 |
| **字体缩放** | 支持系统字体缩放 | 200% 缩放仍可正常使用 |

---

## 2. 屏幕阅读器支持 (Screen Reader Support)

### 2.1 语义化标签

```dart
// lib/widgets/accessibility/semantic_widget.dart

import 'package:flutter/material.dart';

/// 语义化消息气泡
class AccessibleMessageBubble extends StatelessWidget {
  final String content;
  final String sender;
  final DateTime timestamp;
  final MessageRole role;

  const AccessibleMessageBubble({
    super.key,
    required this.content,
    required this.sender,
    required this.timestamp,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // 定义语义标签
      label: '$sender 于 ${_formatTime(timestamp)} 说：$content',
      // 定义语义角色
      button: false,
      // 定义语义值
      value: content,
      // 定义语义属性
      properties: const SemanticsProperties(
        // 是否为文本字段
        isTextField: false,
        // 是否为只读
        readOnly: true,
        // 是否为选中状态
        selected: false,
      ),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: role == MessageRole.user
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 4.0),
            Text(content),
            Text(
              _formatTime(timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
```

### 2.2 自定义语义行为

```dart
// lib/widgets/accessibility/custom_semantics.dart

import 'package:flutter/material.dart';

/// 可访问性按钮
class AccessibleButton extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback onPressed;
  final Widget? icon;

  const AccessibleButton({
    super.key,
    required this.label,
    this.hint,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // 按钮语义
      button: true,
      // 标签
      label: label,
      // 提示
      hint: hint,
      // 启用状态
      enabled: onPressed != null,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8.0),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// 可访问性输入框
class AccessibleTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  const AccessibleTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // 文本字段语义
      textField: true,
      // 标签
      label: label,
      // 提示
      hint: hint,
      // 是否为密码字段
      obscureText: obscureText,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }
}
```

### 2.3 实时更新通知

```dart
// lib/widgets/accessibility/live_region.dart

import 'package:flutter/material.dart';

/// 实时区域（Live Region）
/// 用于向屏幕阅读器通知动态内容变化
class LiveRegion extends StatefulWidget {
  final Widget child;

  const LiveRegion({super.key, required this.child});

  @override
  State<LiveRegion> createState() => _LiveRegionState();
}

class _LiveRegionState extends State<LiveRegion> {
  String _liveMessage = '';

  /// 发布实时消息
  void announce(String message) {
    setState(() {
      _liveMessage = message;
    });

    // 延迟清除消息，避免重复朗读
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _liveMessage = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 实时消息（对屏幕阅读器可见，对普通用户隐藏）
        Semantics(
          liveRegion: true,
          label: _liveMessage,
          child: const SizedBox.shrink(),
        ),
        widget.child,
      ],
    );
  }
}

/// 使用示例
class MessageList extends StatefulWidget {
  const MessageList({super.key});

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  final GlobalKey<LiveRegionState> _liveRegionKey = GlobalKey<LiveRegionState>();

  void _addMessage(String message) {
    // 添加消息逻辑
    // ...

    // 通知屏幕阅读器
    _liveRegionKey.currentState?.announce('收到新消息：$message');
  }

  @override
  Widget build(BuildContext context) {
    return LiveRegion(
      key: _liveRegionKey,
      child: ListView.builder(
        itemBuilder: (context, index) {
          return const ListTile(title: Text('消息'));
        },
      ),
    );
  }
}
```

---

## 3. 键盘导航 (Keyboard Navigation)

### 3.1 焦点管理

```dart
// lib/widgets/accessibility/focus_manager.dart

import 'package:flutter/material.dart';

/// 焦点管理器
class FocusManager {
  /// 焦点节点集合
  static final Map<String, FocusNode> _focusNodes = {};

  /// 获取焦点节点
  static FocusNode getFocusNode(String key) {
    _focusNodes.putIfAbsent(key, () => FocusNode());
    return _focusNodes[key]!;
  }

  /// 请求焦点
  static void requestFocus(String key) {
    _focusNodes[key]?.requestFocus();
  }

  /// 释放焦点
  static void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
  }
}

/// 可聚焦的卡片
class FocusableCard extends StatelessWidget {
  final String focusKey;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const FocusableCard({
    super.key,
    required this.focusKey,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final focusNode = FocusManager.getFocusNode(focusKey);

    return Focus(
      focusNode: focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            onTap?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;

          return GestureDetector(
            onTap: onTap,
            onLongPress: onLongPress,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isFocused
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
```

### 3.2 快捷键支持

```dart
// lib/widgets/accessibility/shortcuts.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 可访问性快捷键
class AccessibilityShortcuts {
  /// 定义快捷键
  static Map<LogicalKeySet, Intent> get shortcuts => {
    // 导航
    LogicalKeySet(LogicalKeyboardKey.tab): const NextFocusIntent(),
    LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.tab):
        const PreviousFocusIntent(),
    LogicalKeySet(LogicalKeyboardKey.arrowDown): const DirectionalFocusIntent(
          TraversalDirection.down,
        ),
    LogicalKeySet(LogicalKeyboardKey.arrowUp): const DirectionalFocusIntent(
          TraversalDirection.up,
        ),
    LogicalKeySet(LogicalKeyboardKey.arrowLeft): const DirectionalFocusIntent(
          TraversalDirection.left,
        ),
    LogicalKeySet(LogicalKeyboardKey.arrowRight): const DirectionalFocusIntent(
          TraversalDirection.right,
        ),
    
    // 操作
    LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
    LogicalKeySet(LogicalKeyboardKey.space): const ActivateIntent(),
    LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
    
    // 可访问性
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.a):
        const AnnounceFocusIntent(),
  };
}

/// 下一个焦点意图
class NextFocusIntent extends Intent {
  const NextFocusIntent();
}

/// 上一个焦点意图
class PreviousFocusIntent extends Intent {
  const PreviousFocusIntent();
}

/// 方向焦点意图
class DirectionalFocusIntent extends Intent {
  final TraversalDirection direction;

  const DirectionalFocusIntent(this.direction);
}

/// 激活意图
class ActivateIntent extends Intent {
  const ActivateIntent();
}

/// 关闭意图
class DismissIntent extends Intent {
  const DismissIntent();
}

/// 宣布焦点意图
class AnnounceFocusIntent extends Intent {
  const AnnounceFocusIntent();
}

/// 快捷键操作
class AccessibilityActions {
  static CallbackAction<NextFocusIntent> get nextFocus =>
      CallbackAction<NextFocusIntent>(
        onInvoke: (intent) => _handleNextFocus(),
      );

  static CallbackAction<PreviousFocusIntent> get previousFocus =>
      CallbackAction<PreviousFocusIntent>(
        onInvoke: (intent) => _handlePreviousFocus(),
      );

  static CallbackAction<DirectionalFocusIntent> get directionalFocus =>
      CallbackAction<DirectionalFocusIntent>(
        onInvoke: (intent) => _handleDirectionalFocus(intent.direction),
      );

  static CallbackAction<ActivateIntent> get activate =>
      CallbackAction<ActivateIntent>(
        onInvoke: (intent) => _handleActivate(),
      );

  static CallbackAction<DismissIntent> get dismiss =>
      CallbackAction<DismissIntent>(
        onInvoke: (intent) => _handleDismiss(),
      );

  static CallbackAction<AnnounceFocusIntent> get announceFocus =>
      CallbackAction<AnnounceFocusIntent>(
        onInvoke: (intent) => _handleAnnounceFocus(),
      );

  static void _handleNextFocus() {
    FocusScope.of(WidgetsBinding.instance.focusManager.primaryFocus!.context!)
        .nextFocus();
  }

  static void _handlePreviousFocus() {
    FocusScope.of(WidgetsBinding.instance.focusManager.primaryFocus!.context!)
        .previousFocus();
  }

  static void _handleDirectionalFocus(TraversalDirection direction) {
    FocusScope.of(WidgetsBinding.instance.focusManager.primaryFocus!.context!)
        .focusInDirection(direction);
  }

  static void _handleActivate() {
    // 激活当前焦点元素
  }

  static void _handleDismiss() {
    // 关闭当前对话框或抽屉
  }

  static void _handleAnnounceFocus() {
    // 宣布当前焦点元素
  }
}
```

### 3.3 Tab 键导航顺序

```dart
// lib/widgets/accessibility/tab_navigation.dart

import 'package:flutter/material.dart';

/// Tab 导航顺序管理器
class TabNavigationManager {
  /// 定义 Tab 导航顺序
  static Widget buildWithTabOrder({
    required List<Widget> children,
    required List<int> tabOrder,
  }) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        children: List.generate(
          children.length,
          (index) {
            final tabIndex = tabOrder.indexOf(index);
            return FocusTraversalOrder(
              order: NumericFocusOrder(tabIndex.toDouble()),
              child: children[index],
            );
          },
        ),
      ),
    );
  }
}

/// 使用示例
class FormWithTabOrder extends StatelessWidget {
  const FormWithTabOrder({super.key});

  @override
  Widget build(BuildContext context) {
    return TabNavigationManager.buildWithTabOrder(
      children: [
        TextField(
          decoration: const InputDecoration(labelText: '用户名'),
        ),
        TextField(
          decoration: const InputDecoration(labelText: '密码'),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: () {},
          child: const Text('登录'),
        ),
      ],
      tabOrder: [0, 1, 2], // Tab 键导航顺序
    );
  }
}
```

---

## 4. 语义标签 (Semantic Labels)

### 4.1 图标语义

```dart
// lib/widgets/accessibility/icon_semantics.dart

import 'package:flutter/material.dart';

/// 可访问性图标按钮
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? tooltip;
  final VoidCallback? onPressed;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // 按钮语义
      button: true,
      // 标签
      label: label,
      // 提示
      tooltip: tooltip,
      child: Tooltip(
        message: tooltip ?? label,
        child: IconButton(
          icon: Icon(icon),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// 使用示例
class MessageActions extends StatelessWidget {
  const MessageActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AccessibleIconButton(
          icon: Icons.copy,
          label: '复制',
          tooltip: '复制消息',
          onPressed: () {
            // 复制逻辑
          },
        ),
        AccessibleIconButton(
          icon: Icons.reply,
          label: '回复',
          tooltip: '回复消息',
          onPressed: () {
            // 回复逻辑
          },
        ),
        AccessibleIconButton(
          icon: Icons.delete,
          label: '删除',
          tooltip: '删除消息',
          onPressed: () {
            // 删除逻辑
          },
        ),
      ],
    );
  }
}
```

### 4.2 自定义语义标签

```dart
// lib/widgets/accessibility/custom_semantics_label.dart

import 'package:flutter/material.dart';

/// 自定义语义标签
class CustomSemanticsLabel extends StatelessWidget {
  final Widget child;
  final String label;
  final String? hint;
  final bool button;
  final bool textField;

  const CustomSemanticsLabel({
    super.key,
    required this.child,
    required this.label,
    this.hint,
    this.button = false,
    this.textField = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint,
      button: button,
      textField: textField,
      child: ExcludeSemantics(
        child: child,
      ),
    );
  }
}

/// 使用示例
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: CustomSemanticsLabel(
          label: text,
          button: true,
          child: Text(
            text,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
```

---

## 5. 颜色对比度 (Color Contrast)

### 5.1 对比度检查

```dart
// lib/utils/color_contrast.dart

import 'package:flutter/material.dart';

/// 颜色对比度工具
class ColorContrast {
  /// 计算相对亮度
  static double _getRelativeLuminance(Color color) {
    final r = _linearizeColorComponent(color.red);
    final g = _linearizeColorComponent(color.green);
    final b = _linearizeColorComponent(color.blue);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// 线性化颜色分量
  static double _linearizeColorComponent(int component) {
    final normalized = component / 255.0;
    return normalized <= 0.03928
        ? normalized / 12.92
        : pow((normalized + 0.055) / 1.055, 2.4).toDouble();
  }

  /// 计算对比度
  static double getContrastRatio(Color foreground, Color background) {
    final l1 = _getRelativeLuminance(foreground);
    final l2 = _getRelativeLuminance(background);

    final lighter = max(l1, l2);
    final darker = min(l1, l2);

    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 检查是否符合 WCAG AA 标准
  static bool meetsWCAGAA(Color foreground, Color background, {bool largeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    final requiredRatio = largeText ? 3.0 : 4.5;
    return ratio >= requiredRatio;
  }

  /// 检查是否符合 WCAG AAA 标准
  static bool meetsWCAGAAA(Color foreground, Color background, {bool largeText = false}) {
    final ratio = getContrastRatio(foreground, background);
    final requiredRatio = largeText ? 4.5 : 7.0;
    return ratio >= requiredRatio;
  }

  /// 获取最佳文本颜色
  static Color getBestTextColor(Color backgroundColor) {
    final whiteContrast = getContrastRatio(Colors.white, backgroundColor);
    final blackContrast = getContrastRatio(Colors.black, backgroundColor);

    return whiteContrast > blackContrast ? Colors.white : Colors.black;
  }
}

import 'dart:math';
```

### 5.2 可访问性颜色主题

```dart
// lib/theme/accessibility_theme.dart

import 'package:flutter/material.dart';

/// 可访问性颜色主题
class AccessibilityColorTheme {
  /// 创建符合 WCAG AA 标准的颜色主题
  static ThemeData createAccessibleTheme({
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
  }) {
    // 确保颜色对比度符合标准
    final onPrimary = ColorContrast.getBestTextColor(primary);
    final onSecondary = ColorContrast.getBestTextColor(secondary);
    final onBackground = ColorContrast.getBestTextColor(background);
    final onSurface = ColorContrast.getBestTextColor(surface);

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onSurface: onSurface,
        onBackground: onBackground,
      ),
    );
  }

  /// 高对比度主题
  static ThemeData createHighContrastTheme() {
    return ThemeData(
      colorScheme: const ColorScheme.highContrast(
        brightness: Brightness.light,
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Colors.blue,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
        background: Colors.white,
        onBackground: Colors.black,
      ),
    );
  }

  /// 深色高对比度主题
  static ThemeData createDarkHighContrastTheme() {
    return ThemeData(
      colorScheme: const ColorScheme.highContrast(
        brightness: Brightness.dark,
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.yellow,
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        background: Colors.black,
        onBackground: Colors.white,
      ),
    );
  }
}
```

---

## 6. 字体缩放 (Font Scaling)

### 6.1 响应式字体

```dart
// lib/theme/responsive_text.dart

import 'package:flutter/material.dart';

/// 响应式文本样式
class ResponsiveText {
  /// 根据文本缩放因子调整字体大小
  static double scaledFontSize(double baseSize, BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return baseSize * textScaler.scale(1.0);
  }

  /// 创建响应式文本样式
  static TextStyle responsiveStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? wordSpacing,
    double? height,
  }) {
    return Builder(
      builder: (context) {
        final scaledSize = scaledFontSize(fontSize, context);
        return TextStyle(
          fontSize: scaledSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
          wordSpacing: wordSpacing,
          height: height,
        );
      },
    ).resolve(const {});
  }

  /// 响应式文本组件
  static Widget responsiveText(
    String text, {
    required double fontSize,
    TextStyle? style,
    TextAlign? textAlign,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return Builder(
      builder: (context) {
        final scaledSize = scaledFontSize(fontSize, context);
        return Text(
          text,
          style: (style ?? const TextStyle()).copyWith(fontSize: scaledSize),
          textAlign: textAlign,
          overflow: overflow,
          maxLines: maxLines,
        );
      },
    );
  }
}

/// 使用示例
class ResponsiveMessageBubble extends StatelessWidget {
  final String content;

  const ResponsiveMessageBubble({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: ResponsiveText.responsiveText(
        content,
        fontSize: 16.0,
        maxLines: null,
      ),
    );
  }
}
```

### 6.2 字体大小限制

```dart
// lib/theme/font_size_limiter.dart

import 'package:flutter/material.dart';

/// 字体大小限制器
class FontSizeLimiter {
  /// 限制字体大小范围
  static double limitFontSize(double size, BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final scaledSize = size * textScaler.scale(1.0);

    // 限制最大字体大小
    const maxSize = 32.0;
    // 限制最小字体大小
    const minSize = 12.0;

    return scaledSize.clamp(minSize, maxSize);
  }

  /// 创建受限的文本样式
  static TextStyle limitedStyle({
    required double fontSize,
    TextStyle? style,
  }) {
    return Builder(
      builder: (context) {
        final limitedSize = limitFontSize(fontSize, context);
        return (style ?? const TextStyle()).copyWith(fontSize: limitedSize);
      },
    ).resolve(const {});
  }
}
```

---

## 7. 可访问性测试 (Accessibility Testing)

### 7.1 自动化测试

```dart
// test/accessibility/semantics_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clotho_ui_demo/widgets/accessibility/accessible_button.dart';

void main() {
  group('Accessibility Tests', () {
    testWidgets('button should have semantic label', (tester) async {
      // Arrange
      const buttonLabel = '发送消息';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: buttonLabel,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(
        find.bySemanticsLabel(buttonLabel),
        findsOneWidget,
      );
    });

    testWidgets('text field should have semantic label', (tester) async {
      // Arrange
      const fieldLabel = '输入消息';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleTextField(
              label: fieldLabel,
              controller: TextEditingController(),
            ),
          ),
        ),
      );

      // Assert
      expect(
        find.bySemanticsLabel(fieldLabel),
        findsOneWidget,
      );
    });

    testWidgets('should announce live region message', (tester) async {
      // Arrange
      const message = '新消息已到达';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveRegion(
              child: Container(),
            ),
          ),
        ),
      );

      // Assert
      final liveRegion = tester.widget<Semantics>(find.byType(Semantics));
      expect(liveRegion.properties.liveRegion, isTrue);
    });
  });
}
```

### 7.2 手动测试清单

```markdown
# 可访问性测试清单

## 键盘导航
- [ ] 所有交互元素可通过 Tab 键访问
- [ ] 焦点顺序符合逻辑
- [ ] Enter/Space 键可激活按钮
- [ ] Escape 键可关闭对话框
- [ ] 方向键可在列表中导航

## 屏幕阅读器
- [ ] 所有图像有替代文本
- [ ] 所有按钮有语义标签
- [ ] 所有输入框有标签和提示
- [ ] 动态内容变化有通知
- [ ] 错误消息可被读取

## 颜色对比度
- [ ] 普通文本对比度 >= 4.5:1
- [ ] 大文本对比度 >= 3:1
- [ ] 图标与背景对比度 >= 3:1
- [ ] 链接与背景对比度 >= 3:1
- [ ] 错误信息有颜色和文本双重指示

## 字体缩放
- [ ] 200% 字体缩放后仍可使用
- [ ] 文本不会溢出容器
- [ ] 布局不会破坏
- [ ] 所有文本可读

## 语义标签
- [ ] 所有按钮有语义标签
- [ ] 所有链接有语义标签
- [ ] 所有输入框有语义标签
- [ ] 所有图像有语义标签
- [ ] 自定义组件有适当语义
```

---

## 8. 可访问性设置 (Accessibility Settings)

### 8.1 设置界面

```dart
// lib/screens/accessibility_settings.dart

import 'package:flutter/material.dart';

/// 可访问性设置
class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  State<AccessibilitySettingsScreen> createState() =>
      _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _screenReader = false;
  double _textScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('可访问性设置'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('高对比度'),
            subtitle: const Text('使用高对比度颜色'),
            value: _highContrast,
            onChanged: (value) {
              setState(() {
                _highContrast = value;
              });
              // 应用高对比度主题
            },
          ),
          SwitchListTile(
            title: const Text('减少动画'),
            subtitle: const Text('减少或禁用动画效果'),
            value: _reduceMotion,
            onChanged: (value) {
              setState(() {
                _reduceMotion = value;
              });
              // 应用减少动画设置
            },
          ),
          SwitchListTile(
            title: const Text('屏幕阅读器支持'),
            subtitle: const Text('优化屏幕阅读器体验'),
            value: _screenReader,
            onChanged: (value) {
              setState(() {
                _screenReader = value;
              });
              // 应用屏幕阅读器优化
            },
          ),
          ListTile(
            title: const Text('文本缩放'),
            subtitle: Text('${_textScale.toStringAsFixed(1)}x'),
            trailing: Slider(
              value: _textScale,
              min: 0.8,
              max: 2.0,
              divisions: 12,
              label: '${_textScale.toStringAsFixed(1)}x',
              onChanged: (value) {
                setState(() {
                  _textScale = value;
                });
                // 应用文本缩放
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 8.2 系统可访问性设置检测

```dart
// lib/utils/accessibility_detection.dart

import 'package:flutter/material.dart';

/// 可访问性设置检测
class AccessibilityDetection {
  /// 检测是否启用了高对比度
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.highContrastOf(context);
  }

  /// 检测是否启用了减少动画
  static bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }

  /// 检测是否启用了粗体文本
  static bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.boldTextOf(context);
  }

  /// 获取文本缩放因子
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.textScalerOf(context).scale(1.0);
  }

  /// 检测是否为屏幕阅读器模式
  static bool isScreenReaderMode(BuildContext context) {
    // 检测屏幕阅读器是否运行
    // 注意：这需要平台特定实现
    return false;
  }
}
```

---

## 9. 可访问性最佳实践 (Accessibility Best Practices)

### 9.1 通用原则

| 原则 | 说明 | 示例 |
| :--- | :--- | :--- |
| **语义优先** | 使用语义化组件而非纯视觉组件 | 使用 `ElevatedButton` 而非 `Container` + `GestureDetector` |
| **标签清晰** | 为所有交互元素提供清晰的标签 | 按钮使用"发送"而非"→" |
| **提供反馈** | 为所有操作提供反馈 | 点击按钮后显示 Toast 或更新 UI |
| **错误处理** | 提供清晰的错误信息和恢复方式 | 表单验证失败时显示具体错误 |
| **一致性** | 保持一致的交互模式 | 所有对话框使用相同的关闭方式 |

### 9.2 代码示例

```dart
// ✅ 正确 - 使用语义化组件
ElevatedButton(
  onPressed: () {},
  child: const Text('发送消息'),
)

// ❌ 错误 - 使用非语义化组件
GestureDetector(
  onTap: () {},
  child: Container(
    color: Colors.blue,
    child: const Text('发送消息'),
  ),
)

// ✅ 正确 - 提供清晰标签
Semantics(
  label: '发送消息',
  button: true,
  child: IconButton(
    icon: const Icon(Icons.send),
    onPressed: () {},
  ),
)

// ❌ 错误 - 缺少标签
IconButton(
  icon: const Icon(Icons.send),
  onPressed: () {},
)

// ✅ 正确 - 提供错误反馈
TextField(
  decoration: InputDecoration(
    labelText: '邮箱',
    errorText: _emailError,
  ),
  onChanged: (value) {
    setState(() {
      _emailError = _validateEmail(value);
    });
  },
)

// ❌ 错误 - 没有错误反馈
TextField(
  decoration: const InputDecoration(
    labelText: '邮箱',
  ),
  onChanged: (value) {
    _validateEmail(value);
  },
)
```

---

## 10. 关联文档 (Related Documents)

- [`00_active_specs/presentation/README.md`](../00_active_specs/presentation/README.md) - 表现层总览
- [`00_active_specs/presentation/01-design-tokens.md`](../00_active_specs/presentation/01-design-tokens.md) - 设计令牌系统
- [`00_active_specs/presentation/02-color-theme.md`](../00_active_specs/presentation/02-color-theme.md) - 颜色主题
- [`00_active_specs/presentation/03-typography.md`](../00_active_specs/presentation/03-typography.md) - 排版系统
- [`00_active_specs/presentation/component-testing.md`](../00_active_specs/presentation/component-testing.md) - 组件测试策略
- [`00_active_specs/reference/documentation_standards.md`](../00_active_specs/reference/documentation_standards.md) - 文档编写规范

---

**最后更新**: 2026-02-26  
**文档状态**: 草案，待架构评审委员会审议
