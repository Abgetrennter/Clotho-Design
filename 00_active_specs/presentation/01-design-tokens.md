# 设计令牌系统 (Design Tokens System)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `99_archive/legacy_ui/01-设计令牌.md`

---

## 1. 概述 (Overview)

设计令牌是 Clotho 表现层设计系统的原子单位，定义了所有可复用的设计属性值。本规范将旧 UI 的 CSS 变量系统迁移为 Flutter 设计令牌，确保跨平台一致性。

### 1.1 迁移原则

| 旧 UI 概念 | 新 UI 对应 | 迁移方式 |
| :--- | :--- | :--- |
| CSS 变量 | Flutter 设计令牌类 | 转换语义，保持数值 |
| calc() 计算 | Dart 常量计算 | 使用 final const |
| 字体缩放 | MediaQuery.textScaler | 动态适配系统设置 |

---

## 2. 间距令牌 (Spacing Tokens)

### 2.1 基础间距系统

基于 4px 基准网格，确保所有间距为 4 的倍数。

```dart
class ClothoSpacing {
  // 基准间距
  static const double xs = 4.0;   // 最小间距
  static const double sm = 8.0;   // 小间距
  static const double md = 12.0;  // 中等间距
  static const double lg = 16.0;  // 大间距
  static const double xl = 24.0;  // 超大间距
  static const double xxl = 32.0; // 特大间距

  // 组件专用间距
  static const double messagePadding = 12.0;
  static const double messageSpacing = 16.0;
  static const double inputPadding = 12.0;
  static const double navBarHeight = 56.0;
}
```

### 2.2 应用场景

| 令牌 | 用途 | 示例 |
| :--- | :--- | :--- |
| `xs` | 图标内边距、小分隔 | IconButton padding |
| `sm` | 小组件间距 | 标签与文本间距 |
| `md` | 卡片内边距 | Container padding |
| `lg` | 组件间距、页面边距 | 页面内容 padding |
| `xl` | 区块分隔 | Section 间距 |
| `xxl` | 大区块分隔 | 页面主要区域分隔 |

---

## 3. 圆角令牌 (Border Radius Tokens)

### 3.1 圆角系统

```dart
class ClothoBorderRadius {
  static const double none = 0.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double full = 999.0; // 圆形/胶囊形

  // 组件专用
  static const double messageBubble = 16.0;
  static const double inputField = 24.0;
  static const double button = 8.0;
}
```

### 3.2 应用场景

| 令牌 | 用途 |
| :--- | :--- |
| `messageBubble` | 消息气泡 |
| `inputField` | 输入框（胶囊形） |
| `button` | 标准按钮 |
| `full` | 圆形头像、标签 |

---

## 4. 阴影令牌 (Elevation Tokens)

### 4.1 阴影系统

Material 3 使用色调差异而非阴影来创建层次感，但保留少量阴影用于浮层元素。

```dart
class ClothoElevation {
  static const double level0 = 0.0;
  static const double level1 = 1.0;
  static const double level2 = 2.0;
  static const double level3 = 3.0;
  static const double level4 = 4.0;
}
```

### 4.2 应用场景

| 令牌 | 用途 |
| :--- | :--- |
| `level0` | 默认状态，无阴影 |
| `level1` | 悬停状态 |
| `level2` | 浮层元素（Sheet, Drawer） |
| `level3` | 对话框 |
| `level4` | 菜单、下拉框 |

---

## 5. 尺寸令牌 (Size Tokens)

### 5.1 图标尺寸

```dart
class ClothoIconSize {
  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
}
```

### 5.2 头像尺寸

```dart
class ClothoAvatarSize {
  static const double sm = 32.0;
  static const double md = 40.0;
  static const double lg = 56.0;
  static const double xl = 80.0;
}
```

---

## 6. 动画令牌 (Animation Tokens)

### 6.1 时长系统

```dart
class ClothoDuration {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration extraSlow = Duration(milliseconds: 500);
}
```

### 6.2 缓动曲线

```dart
class ClothoCurve {
  static const Curve standard = Curves.easeInOut;
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve emphasizedDecelerate = Curves.easeOutExpo;
  static const Curve emphasizedAccelerate = Curves.easeInCubic;
}
```

### 6.3 应用场景

| 时长 | 缓动曲线 | 用途 |
| :--- | :--- | :--- |
| `fast` | `standard` | 悬停、点击反馈 |
| `medium` | `emphasized` | 页面切换、组件展开 |
| `slow` | `emphasizedDecelerate` | 复杂动画进入 |
| `extraSlow` | `standard` | 复杂场景过渡 |

---

## 7. Z-Index 令牌 (Z-Index Tokens)

Flutter 使用 Stack 和 Positioned 控制层级，Z-Index 通过 widget 树顺序实现。

```dart
class ClothoZIndex {
  // 用于 Overlay/ModalRoute
  static const int modal = 100;
  static const int drawer = 200;
  static const int menu = 300;
  static const int tooltip = 400;
  static const int snackbar = 500;
}
```

---

## 8. 断点令牌 (Breakpoint Tokens)

详见 [`04-responsive-layout.md`](./04-responsive-layout.md)。

---

## 9. 迁移对照表 (Migration Reference)

| 旧 UI 变量 | 新 UI 令牌 | 值 |
| :--- | :--- | :--- |
| `--spacing-xs` | `ClothoSpacing.xs` | 4px |
| `--spacing-sm` | `ClothoSpacing.sm` | 8px |
| `--spacing-md` | `ClothoSpacing.md` | 12px |
| `--spacing-lg` | `ClothoSpacing.lg` | 16px |
| `--spacing-xl` | `ClothoSpacing.xl` | 24px |
| `--spacing-2xl` | `ClothoSpacing.xxl` | 32px |
| `--shadowWidth` | `ClothoElevation.level1` | 1 |
| `--blurStrength` | `BackdropFilter` | 10px |

---

## 10. 使用示例 (Usage Examples)

### 10.1 在 Widget 中使用

```dart
Padding(
  padding: EdgeInsets.all(ClothoSpacing.lg),
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(ClothoBorderRadius.messageBubble),
    ),
    child: Icon(Icons.send, size: ClothoIconSize.md),
  ),
)
```

### 10.2 主题集成

```dart
ThemeData(
  // 使用设计令牌定义间距
  cardTheme: CardTheme(
    margin: EdgeInsets.all(ClothoSpacing.md),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ClothoBorderRadius.md),
    ),
  ),
  // 使用设计令牌定义动画
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
    },
  ),
)
```

---

**关联文档**:
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`README.md`](./README.md) - 表现层概览
