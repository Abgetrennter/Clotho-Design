# 排版系统 (Typography System)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `99_archive/legacy_ui/03-排版系统.md`

---

## 1. 概述 (Overview)

Clotho 表现层采用 Flutter Material 3 排版系统，通过 `TextTheme` 定义统一的字体、字号、行高和字重体系。本规范将旧 UI 的 CSS 排版系统迁移为 Flutter 排版令牌。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **可读性优先** | 确保文本在深色主题下清晰可读 |
| **动态缩放** | 支持系统字体大小缩放 |
| **层级清晰** | 通过字号、字重、颜色建立视觉层次 |
| **多语言支持** | 使用支持 CJK 的字体族 |

---

## 2. 字体族 (Font Family)

### 2.1 字体定义

```dart
class ClothoFonts {
  // 主字体（无衬线）
  static const String primary = 'Noto Sans';

  // 等宽字体
  static const String mono = 'Noto Sans Mono';

  // 后备字体链
  static const TextStyle baseTextStyle = TextStyle(
    fontFamily: 'Noto Sans',
    package: null, // 使用系统字体
  );
}
```

### 2.2 字体配置

```dart
TextTheme createTextTheme() {
  return TextTheme(
    // 使用 Google Fonts Noto Sans
    displayLarge: GoogleFonts.notoSans(
      fontSize: 57,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
    ),
    displayMedium: GoogleFonts.notoSans(
      fontSize: 45,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: GoogleFonts.notoSans(
      fontSize: 36,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: GoogleFonts.notoSans(
      fontSize: 32,
      fontWeight: FontWeight.w400,
    ),
    headlineMedium: GoogleFonts.notoSans(
      fontSize: 28,
      fontWeight: FontWeight.w400,
    ),
    headlineSmall: GoogleFonts.notoSans(
      fontSize: 24,
      fontWeight: FontWeight.w400,
    ),
    titleLarge: GoogleFonts.notoSans(
      fontSize: 22,
      fontWeight: FontWeight.w500,
    ),
    titleMedium: GoogleFonts.notoSans(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleSmall: GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    bodyLarge: GoogleFonts.notoSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.5,
    ),
    bodySmall: GoogleFonts.notoSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.4,
    ),
    labelLarge: GoogleFonts.notoSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.notoSans(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.notoSans(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
  );
}
```

---

## 3. 字号系统 (Font Size System)

### 3.1 字号层级

| Material 3 样式 | 字号 | 字重 | 行高 | 用途 |
| :--- | :--- | :--- | :--- | :--- |
| `displayLarge` | 57sp | 400 | 64 | 大标题（如欢迎页） |
| `displayMedium` | 45sp | 400 | 52 | 中等大标题 |
| `displaySmall` | 36sp | 400 | 44 | 小大标题 |
| `headlineLarge` | 32sp | 400 | 40 | 页面主标题 |
| `headlineMedium` | 28sp | 400 | 36 | 二级标题 |
| `headlineSmall` | 24sp | 400 | 32 | 三级标题 |
| `titleLarge` | 22sp | 500 | 28 | 卡片标题 |
| `titleMedium` | 16sp | 500 | 24 | 列表项标题 |
| `titleSmall` | 14sp | 500 | 20 | 小标题 |
| `bodyLarge` | 16sp | 400 | 24 | 正文（消息内容） |
| `bodyMedium` | 14sp | 400 | 20 | 次要正文 |
| `bodySmall` | 12sp | 400 | 16 | 说明文字 |
| `labelLarge` | 14sp | 500 | 20 | 按钮文本 |
| `labelMedium` | 12sp | 500 | 16 | 标签文本 |
| `labelSmall` | 11sp | 500 | 16 | 小标签 |

### 3.2 迁移对照表

| 旧 UI 变量 | Material 3 样式 | 字号 |
| :--- | :--- | :--- |
| `--fontSize-2xl` | `headlineLarge` | 30sp → 32sp |
| `--fontSize-xl` | `headlineSmall` | 22.5sp → 24sp |
| `--fontSize-lg` | `titleLarge` | 18sp → 22sp |
| `--fontSize-base` | `bodyLarge` | 15sp → 16sp |
| `--fontSize-sm` | `bodyMedium` | 13.5sp → 14sp |
| `--fontSize-xs` | `bodySmall` | 12sp |

---

## 4. 行高系统 (Line Height System)

### 4.1 行高定义

| 内容类型 | 行高值 | 说明 |
| :--- | :--- | :--- |
| 标题 | 1.2 - 1.3 | 紧凑，节省空间 |
| 正文 | 1.5 | 标准可读性 |
| 长文本 | 1.6 | 提高可读性 |
| 按钮文本 | 1.0 | 垂直居中 |
| 代码 | 1.4 | 适合代码阅读 |

### 4.2 Material 3 行高

```dart
// Material 3 已在 TextTheme 中定义行高
// bodyLarge: height: 1.5 (24/16)
// bodyMedium: height: 1.43 (20/14)
// bodySmall: height: 1.33 (16/12)
```

---

## 5. 字重系统 (Font Weight System)

### 5.1 字重定义

```dart
class ClothoFontWeight {
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;  // 默认
  static const FontWeight medium = FontWeight.w500;    // 强调
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;      // 标题
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}
```

### 5.2 应用场景

| 字重 | 用途 | 示例 |
| :--- | :--- | :--- |
| `w400` | 正文、次要文本 | 消息内容 |
| `w500` | 强调、按钮文本 | 按钮标签 |
| `w700` | 标题 | 页面标题 |

---

## 6. 文本样式应用 (Text Style Usage)

### 6.1 消息内容

```dart
Text(
  message.content,
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    color: Theme.of(context).colorScheme.onSurface,
    height: 1.5,
  ),
)
```

### 6.2 消息元数据（时间、状态）

```dart
Text(
  message.timestamp,
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  ),
)
```

### 6.3 AI 名称/状态文本

```dart
Text(
  'AI 正在生成...',
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  ),
)
```

### 6.4 代码块

```dart
Container(
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
    codeContent,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontFamily: 'Noto Sans Mono',
      height: 1.4,
    ),
  ),
)
```

### 6.5 引用文本

```dart
Container(
  padding: EdgeInsets.only(left: 12),
  decoration: BoxDecoration(
    border: Border(
      left: BorderSide(
        color: Theme.of(context).colorScheme.warning,
        width: 2,
      ),
    ),
  ),
  child: Text(
    quoteContent,
    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: Theme.of(context).colorScheme.warning,
      fontStyle: FontStyle.italic,
    ),
  ),
)
```

---

## 7. 动态字体缩放 (Dynamic Font Scaling)

### 7.1 系统字体缩放

Flutter 自动支持系统字体缩放设置。使用 `MediaQuery.textScaler` 获取当前缩放因子：

```dart
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return Text(
      text,
      style: style?.apply(
        fontSizeFactor: textScaler.scale(1.0),
      ),
    );
  }
}
```

### 7.2 限制最大缩放

```dart
Text(
  text,
  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
    fontSize: 16 * MediaQuery.textScalerOf(context).clamp(
      minScaleFactor: 0.8,
      maxScaleFactor: 1.3,
    ).scale(1.0),
  ),
)
```

---

## 8. 特殊文本样式 (Special Text Styles)

### 8.1 行内代码

```dart
class InlineCode extends StatelessWidget {
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        code,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'Noto Sans Mono',
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
```

### 8.2 Token 计数（等宽数字）

```dart
Text(
  '${tokenCount} tokens',
  style: Theme.of(context).textTheme.bodySmall?.copyWith(
    fontFamily: 'Noto Sans Mono',
    fontFeatures: [FontFeature.tabularFigures()],
  ),
)
```

---

## 9. 主题集成 (Theme Integration)

### 9.1 完整主题配置

```dart
ThemeData createClothoTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: createTextTheme(),
    // 确保所有组件使用 TextTheme
    appBarTheme: AppBarTheme(
      titleTextStyle: GoogleFonts.notoSans(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: ClothoColors.onSurface,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      extendedTextStyle: GoogleFonts.notoSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
```

---

## 10. 迁移检查清单 (Migration Checklist)

- [ ] 字体族从 CSS `font-family` 转换为 Flutter `TextStyle.fontFamily`
- [ ] 字号从 `px` 转换为 `sp`（支持系统缩放）
- [ ] 行高从 CSS `line-height` 转换为 Flutter `TextStyle.height`
- [ ] 字重从 CSS 数值转换为 `FontWeight` 枚举
- [ ] 颜色从 CSS 变量转换为 `TextStyle.color`
- [ ] 代码块使用等宽字体
- [ ] 支持系统字体缩放

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`README.md`](./README.md) - 表现层概览
