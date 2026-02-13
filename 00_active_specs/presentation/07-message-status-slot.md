# 消息状态槽组件 (Message Status Slot Component)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `00_active_specs/presentation/README.md`

---

## 1. 概述 (Overview)

MessageStatusSlot 是嵌入在消息气泡底部的动态容器，作为"防火墙"隔离外部内容，管理渲染器的尺寸约束与异常处理。本规范定义其结构、职责和实现方式。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **隔离性** | 作为防火墙隔离外部内容，防止污染主界面 |
| **可扩展性** | 支持 Hybrid SDUI 双轨渲染（RFW + WebView） |
| **异常处理** | 捕获并处理渲染异常，不影响主界面 |
| **尺寸约束** | 严格控制外部内容的尺寸和位置 |

---

## 2. 组件职责 (Component Responsibilities)

### 2.1 核心职责

| 职责 | 说明 |
| :--- | :--- |
| **渲染隔离** | 将外部内容（HTML/JS）隔离在独立容器中 |
| **路由调度** | 根据内容类型选择 RFW 或 WebView 渲染 |
| **尺寸管理** | 控制外部内容的最大高度和宽度 |
| **异常捕获** | 捕获渲染异常并提供降级方案 |
| **生命周期管理** | 随消息创建而初始化，随消息销毁而清理 |

---

## 3. 组件结构 (Component Structure)

### 3.1 数据模型

```dart
enum SlotContentType {
  text,       // 纯文本
  html,       // HTML 内容
  rfw,        // Remote Flutter Widget
  custom,     // 自定义组件
}

class SlotContent {
  final String id;
  final SlotContentType type;
  final dynamic data;
  final Map<String, dynamic>? metadata;
  final int? maxHeight;
  final int? maxWidth;
}
```

### 3.2 Widget 结构

```dart
class MessageStatusSlot extends StatelessWidget {
  final SlotContent content;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8),
      constraints: BoxConstraints(
        maxHeight: content.maxHeight ?? 300,
        maxWidth: content.maxWidth ?? double.infinity,
      ),
      child: SlotRenderer(content: content),
    );
  }
}
```

---

## 4. 渲染路由器 (Slot Renderer)

### 4.1 路由逻辑

```dart
class SlotRenderer extends StatelessWidget {
  final SlotContent content;

  @override
  Widget build(BuildContext context) {
    switch (content.type) {
      case SlotContentType.rfw:
        return RFWSlotRenderer(content: content);

      case SlotContentType.html:
        return WebViewSlotRenderer(content: content);

      case SlotContentType.text:
        return TextSlotRenderer(content: content);

      case SlotContentType.custom:
        return CustomSlotRenderer(content: content);

      default:
        return FallbackSlotRenderer(content: content);
    }
  }
}
```

### 4.2 RFW 渲染器

```dart
class RFWSlotRenderer extends StatelessWidget {
  final SlotContent content;

  @override
  Widget build(BuildContext context) {
    return RemoteFlutterWidget(
      data: content.data,
      onError: (error) {
        // RFW 渲染失败，降级到 WebView
        return WebViewSlotRenderer(content: content);
      },
    );
  }
}
```

### 4.3 WebView 渲染器

```dart
class WebViewSlotRenderer extends StatefulWidget {
  final SlotContent content;

  @override
  _WebViewSlotRendererState createState() => _WebViewSlotRendererState();
}

class _WebViewSlotRendererState extends State<WebViewSlotRenderer> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            // WebView 加载失败，显示错误信息
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: widget.content.maxHeight ?? 300,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : WebViewWidget(controller: _controller),
    );
  }
}
```

---

## 5. 异常处理 (Error Handling)

### 5.1 异常捕获

```dart
class SafeSlotRenderer extends StatelessWidget {
  final SlotContent content;

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (error, stack) {
        // 捕获渲染异常，显示降级内容
        return FallbackSlotRenderer(
          content: SlotContent(
            id: content.id,
            type: SlotContentType.text,
            data: '内容加载失败',
          ),
        );
      },
      child: SlotRenderer(content: content),
    );
  }
}
```

### 5.2 降级渲染器

```dart
class FallbackSlotRenderer extends StatelessWidget {
  final SlotContent content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          SizedBox(width: 8),
          Text(
            content.data?.toString() ?? '内容无法显示',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 6. 尺寸约束 (Size Constraints)

### 6.1 约束管理

```dart
class SlotConstraints {
  static const int defaultMaxHeight = 300;
  static const int defaultMaxWidth = double.infinity;

  static BoxConstraints getConstraints(SlotContent content) {
    return BoxConstraints(
      maxHeight: content.maxHeight ?? defaultMaxHeight,
      maxWidth: content.maxWidth ?? defaultMaxWidth,
    );
  }
}
```

### 6.2 响应式约束

```dart
class ResponsiveSlotConstraints extends StatelessWidget {
  final SlotContent content;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final maxHeight = isMobile ? 200 : 300;
    final maxWidth = isMobile ? screenWidth * 0.9 : screenWidth * 0.8;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight.toDouble(),
        maxWidth: maxWidth,
      ),
      child: SlotRenderer(content: content),
    );
  }
}
```

---

## 7. 生命周期管理 (Lifecycle Management)

### 7.1 资源清理

```dart
class SlotLifecycle extends StatefulWidget {
  final SlotContent content;

  @override
  _SlotLifecycleState createState() => _SlotLifecycleState();
}

class _SlotLifecycleState extends State<SlotLifecycle> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    // 初始化资源
  }

  @override
  void dispose() {
    // 清理资源
    _controller?.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlotRenderer(content: widget.content);
  }
}
```

---

## 8. 应用场景 (Use Cases)

### 8.1 角色状态栏

```dart
class CharacterStatusSlot extends StatelessWidget {
  final String characterId;

  @override
  Widget build(BuildContext context) {
    return MessageStatusSlot(
      content: SlotContent(
        id: 'status-$characterId',
        type: SlotContentType.rfw,
        data: {
          'type': 'character_status',
          'characterId': characterId,
        },
        maxHeight: 150,
      ),
    );
  }
}
```

### 8.2 世界书卡片

```dart
class LorebookCardSlot extends StatelessWidget {
  final String loreId;

  @override
  Widget build(BuildContext context) {
    return MessageStatusSlot(
      content: SlotContent(
        id: 'lore-$loreId',
        type: SlotContentType.html,
        data: '<div>世界书内容...</div>',
        maxHeight: 200,
      ),
    );
  }
}
```

---

## 9. 安全考虑 (Security Considerations)

### 9.1 内容过滤

```dart
class ContentSanitizer {
  static String sanitizeHTML(String html) {
    // 移除危险标签和属性
    return html
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+="[^"]*"', caseSensitive: false), '');
  }
}
```

### 9.2 CSP 策略

```dart
class WebViewSecurity extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setContentSecurityPolicy(
          ContentSecurityPolicy(
            defaultSrc: [ContentSecurityPolicySource.self],
            scriptSrc: [ContentSecurityPolicySource.none],
            styleSrc: [ContentSecurityPolicySource.self],
            imgSrc: [ContentSecurityPolicySource.self, ContentSecurityPolicySource.data],
          ),
        ),
    );
  }
}
```

---

## 10. 迁移对照表 (Migration Reference)

| 旧 UI 概念 | 新 UI 组件 | 变化 |
| :--- | :--- | :--- |
| 内联 HTML | `MessageStatusSlot` | 直接嵌入 → 隔离容器 |
| 状态栏渲染 | `SlotRenderer` | 直接渲染 → 路由调度 |
| 异常处理 | `ErrorBoundary` | 无 → 统一异常捕获 |

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`05-message-bubble.md`](./05-message-bubble.md) - 消息气泡组件
- [`10-hybrid-sdui.md`](./10-hybrid-sdui.md) - Hybrid SDUI 引擎
