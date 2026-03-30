# 颜色与主题系统 (Color & Theme System)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `99_archive/legacy_ui/02-颜色系统.md`

---

## 1. 概述 (Overview)

Clotho 表现层采用 Flutter Material 3 设计系统，使用 `ColorScheme.fromSeed` 构建语义化颜色体系。本规范定义深色主题的颜色映射规则，确保跨平台一致性。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **语义化优先** | 使用 Material 3 语义色（primary, surface 等）而非硬编码颜色值 |
| **色调层次** | 通过色调差异创建视觉层次，减少阴影依赖 |
| **对比度合规** | 确保文本与背景对比度符合 WCAG AA 标准 |
| **动态适配** | 支持系统深色/浅色主题切换 |

---

## 2. 主题配置 (Theme Configuration)

### 2.1 核心主题定义

```dart
import 'package:flutter/material.dart';

class ClothoTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ClothoColors.seedColor,
        brightness: Brightness.dark,
        // 自定义语义色映射
        primary: ClothoColors.primary,
        onPrimary: ClothoColors.onPrimary,
        primaryContainer: ClothoColors.primaryContainer,
        onPrimaryContainer: ClothoColors.onPrimaryContainer,
        surface: ClothoColors.surface,
        onSurface: ClothoColors.onSurface,
        surfaceContainer: ClothoColors.surfaceContainer,
        surfaceContainerLow: ClothoColors.surfaceContainerLow,
        surfaceContainerHigh: ClothoColors.surfaceContainerHigh,
        error: ClothoColors.error,
        onError: ClothoColors.onError,
      ),
      scaffoldBackgroundColor: ClothoColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: ClothoColors.surfaceContainer,
        elevation: 0,
      ),
    );
  }
}
```

### 2.2 颜色定义

```dart
class ClothoColors {
  // 种子颜色（偏冷色调：蓝灰）
  static const Color seedColor = Color(0xFF607D8B); // Blue Grey 500

  // 主色调
  static const Color primary = Color(0xFF607D8B);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF455A64);
  static const Color onPrimaryContainer = Color(0xFFECEFF1);

  // 表面色系
  static const Color background = Color(0xFF121212); // 深色背景
  static const Color surface = Color(0xFF1E1E1E);
  static const Color onSurface = Color(0xFFDCDCD2); // 主文本
  static const Color onSurfaceVariant = Color(0xFF919191); // 次要文本

  // 容器色系（用于创建层次）
  static const Color surfaceContainer = Color(0xFF1E1E1E);
  static const Color surfaceContainerLow = Color(0xFF2C2C2C);
  static const Color surfaceContainerHigh = Color(0xFF363636);

  // 语义化颜色
  static const Color error = Color(0xFFCF6679);
  static const Color onError = Color(0xFF000000);
  static const Color success = Color(0xFF58B600);
  static const Color warning = Color(0xFFE18A24);
  static const Color info = Color(0xFF64B5F6);

  // 消息背景色
  static const Color userMessageBackground = Color(0x4D000000); // rgba(0,0,0,0.3)
  static const Color aiMessageBackground = Color(0x4D3C3C3C);  // rgba(60,60,60,0.3)

  // 分割线
  static const Color divider = Color(0x1AFFFFFF); // onSurfaceVariant 10% 透明度
}
```

---

## 3. 语义色映射 (Semantic Color Mapping)

### 3.1 文本颜色

| 旧 UI 变量 | Material 3 语义色 | 用途 |
| :--- | :--- | :--- |
| `--SmartThemeBodyColor` | `onSurface` | 主要内容文本 |
| `--SmartThemeEmColor` | `onSurfaceVariant` | 次要说明文本 |
| `--SmartThemeQuoteColor` | `warning` | 引用、强调内容 |
| `--grey50` | `onSurfaceVariant.withOpacity(0.5)` | 禁用状态文本 |

### 3.2 背景颜色

| 旧 UI 变量 | Material 3 语义色 | 用途 |
| :--- | :--- | :--- |
| `#242425` | `background` | 页面默认背景 |
| `#171717` | `surfaceContainer` | 模糊效果底色、导航栏 |
| `--SmartThemeUserMesBlurTintColor` | `userMessageBackground` | 用户消息背景 |
| `--SmartThemeBotMesBlurTintColor` | `aiMessageBackground` | AI 消息背景 |

### 3.3 状态颜色

| 旧 UI 变量 | Material 3 语义色 | 用途 |
| :--- | :--- | :--- |
| `--active` | `success` | 连接成功、激活状态 |
| `--warning` | `warning` | 警告提示 |
| `--fullred` | `error` | 错误信息、危险操作 |
| `--preferred` | `primary` | 重要、优先项 |

---

## 4. 组件颜色应用 (Component Color Usage)

### 4.1 消息气泡

```dart
// AI 消息气泡
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text(
    message.content,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  ),
)

// 用户消息气泡
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.primaryContainer,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Text(
    message.content,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.onPrimaryContainer,
    ),
  ),
)
```

### 4.2 导航栏

```dart
AppBar(
  backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
  elevation: 0,
  title: Text(
    'Clotho',
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  ),
  actions: [
    IconButton(
      icon: Icon(Icons.settings),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: () {},
    ),
  ],
)
```

### 4.3 输入区域

```dart
Container(
  color: Theme.of(context).colorScheme.surfaceContainerHigh,
  padding: EdgeInsets.all(12),
  child: TextField(
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
    ),
    decoration: InputDecoration(
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      hintText: '输入消息...',
      hintStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
    ),
  ),
)
```

---

## 5. 透明度系统 (Opacity System)

### 5.1 标准透明度

```dart
class ClothoOpacity {
  static const double highlyTransparent = 0.08;  // 极低对比度
  static const double transparent = 0.12;         // 低对比度
  static const double semiTransparent = 0.38;     // 中对比度
  static const double opaque = 0.87;              // 高对比度
}
```

### 5.2 应用场景

| 透明度 | 用途 | 示例 |
| :--- | :--- | :--- |
| `0.08` | 分割线、禁用状态 | `onSurface.withOpacity(0.08)` |
| `0.12` | 悬停状态 | `primary.withOpacity(0.12)` |
| `0.38` | 次要文本 | `onSurface.withOpacity(0.38)` |
| `0.87` | 主要文本 | `onSurface.withOpacity(0.87)` |

---

## 6. 迁移对照表 (Migration Reference)

| 旧 UI 颜色值 | 新 UI 语义色 | RGB/ARGB |
| :--- | :--- | :--- |
| `#DCDCD2` | `onSurface` | rgb(220, 220, 210) |
| `#919191` | `onSurfaceVariant` | rgb(145, 145, 145) |
| `#E18A24` | `warning` | rgb(225, 138, 36) |
| `#171717` | `surfaceContainer` | rgb(23, 23, 23) |
| `rgba(0,0,0,0.3)` | `userMessageBackground` | rgba(0, 0, 0, 0.3) |
| `rgba(60,60,60,0.3)` | `aiMessageBackground` | rgba(60, 60, 60, 0.3) |
| `#58B600` | `success` | rgb(88, 182, 0) |
| `rgba(255,0,0,0.9)` | `error` | rgba(255, 0, 0, 0.9) |

---

## 7. 主题切换 (Theme Switching)

### 7.1 支持系统主题

```dart
class ClothoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ClothoTheme.lightTheme,  // 浅色主题
      darkTheme: ClothoTheme.darkTheme, // 深色主题
      themeMode: ThemeMode.system,      // 跟随系统
    );
  }
}
```

### 7.2 动态主题切换

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }
}
```

---

## 8. 颜色对比度检查 (Contrast Checking)

### 8.1 WCAG AA 标准

- **正常文本**: 对比度 ≥ 4.5:1
- **大号文本 (≥18pt)**: 对比度 ≥ 3:1

### 8.2 验证工具

使用 `flutter pub add contrast` 添加对比度检查包：

```dart
import 'package:contrast/contrast.dart';

void checkContrast() {
  final contrast = Contrast.contrast(
    foreground: ClothoColors.onSurface,
    background: ClothoColors.surface,
  );
  assert(contrast >= 4.5, 'Contrast ratio $contrast is below WCAG AA');
}
```

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`README.md`](./README.md) - 表现层概览
