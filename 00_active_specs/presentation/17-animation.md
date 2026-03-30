# 动画与过渡 (Animation & Transition)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `99_archive/legacy_ui/10-动画与过渡.md`

---

## 1. 概述 (Overview)

Clotho 表现层使用 Material 3 标准动画系统，确保流畅的过渡效果和一致的用户体验。本规范定义动画时长、缓动曲线和动画模式。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **Material 3 标准** | 使用 Material 3 标准动画曲线 |
| **流畅自然** | 避免突兀的动画，保持自然流畅 |
| **性能优先** | 确保动画在 60fps 下运行 |
| **可配置** | 支持用户关闭动画 |

---

## 2. 动画时长 (Animation Duration)

### 2.1 标准时长

```dart
class ClothoDuration {
  // 快速动画（微交互）
  static const Duration fast = Duration(milliseconds: 150);

  // 中速动画（标准过渡）
  static const Duration medium = Duration(milliseconds: 250);

  // 慢速动画（复杂动画）
  static const Duration slow = Duration(milliseconds: 350);

  // 超慢动画（页面切换）
  static const Duration extraSlow = Duration(milliseconds: 500);
}
```

### 2.2 应用场景

| 时长 | 缓动曲线 | 应用场景 |
| :--- | :--- | :--- |
| `fast` (150ms) | `standard` | 悬停、点击反馈 |
| `medium` (250ms) | `emphasized` | 组件展开/折叠 |
| `slow` (350ms) | `emphasizedDecelerate` | 模态框进入 |
| `extraSlow` (500ms) | `standard` | 页面切换 |

---

## 3. 缓动曲线 (Easing Curves)

### 3.1 标准曲线

```dart
class ClothoCurve {
  // 标准曲线（对称）
  static const Curve standard = Curves.easeInOut;

  // 强调曲线（进入）
  static const Curve emphasized = Curves.easeOutCubic;

  // 强调减速曲线（进入）
  static const Curve emphasizedDecelerate = Curves.easeOutExpo;

  // 强调加速曲线（退出）
  static const Curve emphasizedAccelerate = Curves.easeInCubic;

  // 弹性曲线（特殊效果）
  static const Curve elastic = Curves.elasticOut;
}
```

### 3.2 应用场景

| 曲线 | 应用场景 |
| :--- | :--- |
| `standard` | 标准过渡、悬停效果 |
| `emphasized` | 组件展开、抽屉打开 |
| `emphasizedDecelerate` | 模态框进入、页面切换 |
| `emphasizedAccelerate` | 模态框退出、页面切换 |
| `elastic` | 特殊反馈效果 |

---

## 4. 页面过渡 (Page Transitions)

### 4.1 标准过渡

```dart
class ClothoPageTransitions {
  static Widget buildTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
```

### 4.2 滑动过渡

```dart
class SlidePageTransition extends StatelessWidget {
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PageTransitionsTheme(
      data: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      child: child,
    );
  }
}
```

### 4.3 淡入淡出过渡

```dart
class FadePageTransition extends PageRouteBuilder {
  final Widget child;

  FadePageTransition({required this.child})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: ClothoDuration.medium,
        );
}
```

---

## 5. 组件动画 (Component Animations)

### 5.1 消息气泡动画

```dart
class AnimatedMessageBubble extends StatefulWidget {
  final Message message;

  @override
  _AnimatedMessageBubbleState createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ClothoDuration.medium,
      vsync: this,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: ClothoCurve.emphasizedDecelerate,
    ));

    _slideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: ClothoCurve.emphasizedDecelerate,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 1),
          end: Offset.zero,
        ).animate(_controller),
        child: MessageBubble(message: widget.message),
      ),
    );
  }
}
```

### 5.2 输入框动画

```dart
class AnimatedInputField extends StatefulWidget {
  @override
  _AnimatedInputFieldState createState() => _AnimatedInputFieldState();
}

class _AnimatedInputFieldState extends State<AnimatedInputField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: ClothoDuration.fast,
      curve: ClothoCurve.standard,
      decoration: BoxDecoration(
        color: _isFocused
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isFocused
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Focus(
        onFocusChange: (hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        },
        child: TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: '输入消息...',
          ),
        ),
      ),
    );
  }
}
```

---

## 6. 微交互 (Micro-interactions)

### 6.1 按钮点击反馈

```dart
class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ClothoDuration.fast,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: ClothoCurve.standard,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
```

### 6.2 列表项动画

```dart
class AnimatedListItem extends StatelessWidget {
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: ClothoDuration.medium,
      curve: ClothoCurve.emphasizedDecelerate,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
```

---

## 7. 加载动画 (Loading Animations)

### 7.1 圆形进度条

```dart
class CircularLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
```

### 7.2 脉冲加载动画

```dart
class PulseLoadingIndicator extends StatefulWidget {
  @override
  _PulseLoadingIndicatorState createState() => _PulseLoadingIndicatorState();
}

class _PulseLoadingIndicatorState extends State<PulseLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ClothoDuration.slow,
      vsync: this,
    )..repeat();

    _opacityAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: ClothoCurve.standard,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
```

---

## 8. 动画禁用 (Animation Disable)

### 8.1 全局禁用

```dart
class AnimationSettings {
  static bool animationsEnabled = true;

  static void setAnimationsEnabled(bool enabled) {
    animationsEnabled = enabled;
  }

  static Duration getDuration(Duration defaultDuration) {
    return animationsEnabled ? defaultDuration : Duration.zero;
  }

  static Curve getCurve(Curve defaultCurve) {
    return animationsEnabled ? defaultCurve : Curves.linear;
  }
}
```

### 8.2 应用禁用设置

```dart
class AnimatedContainer extends StatelessWidget {
  final Duration duration;
  final Curve curve;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AnimationSettings.getDuration(duration),
      curve: AnimationSettings.getCurve(curve),
      child: child,
    );
  }
}
```

---

## 9. 迁移对照表 (Migration Reference)

| 旧 CSS 动画 | 新 Flutter 动画 | 变化 |
| :--- | :--- | :--- |
| `transition: all 0.2s ease` | `AnimatedContainer` | CSS → Widget |
| `@keyframes` | `AnimationController` | 关键帧 → Tween |
| `ease-in-out` | `Curves.easeInOut` | CSS 曲线 → Flutter 曲线 |
| `animation-delay` | `Future.delayed` | CSS 延迟 → Dart 异步 |

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`16-performance.md`](./16-performance.md) - 性能优化
