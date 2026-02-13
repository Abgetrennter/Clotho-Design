# WebView 兜底机制 (WebView Fallback)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `00_active_specs/presentation/10-hybrid-sdui.md`

---

## 1. 概述 (Overview)

WebView 兜底机制是 Hybrid SDUI 的备用渲染轨道，当 RFW 包不可用时，使用 WebView 渲染 HTML/JS 内容。本规范定义 WebView 的安全策略和降级机制。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **安全优先** | 严格的内容安全策略（CSP） |
| **性能可控** | WebView 池化和懒加载 |
| **异常处理** | 渲染失败时显示降级内容 |
| **资源隔离** | 独立的 WebView 实例，避免污染 |

---

## 2. WebView 渲染器 (WebView Renderer)

### 2.1 基础实现

```dart
class WebViewSlotRenderer extends StatefulWidget {
  final SDUIContent content;
  final Widget Function()? onError;

  @override
  _WebViewSlotRendererState createState() => _WebViewSlotRendererState();
}

class _WebViewSlotRendererState extends State<WebViewSlotRenderer> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
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
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = error.description;
            });
          },
        ),
      )
      ..loadHtmlString(_generateHTML());
  }

  String _generateHTML() {
    final generator = HTMLGenerator();
    return generator.generate(widget.content);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.onError?.call() ??
          FallbackSlotRenderer(content: widget.content);
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: widget.content.maxHeight?.toDouble() ?? 300,
        maxWidth: widget.content.maxWidth?.toDouble() ?? double.infinity,
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

  @override
  void dispose() {
    _controller.clearCache();
    super.dispose();
  }
}
```

---

## 3. HTML 生成器 (HTML Generator)

### 3.1 基础实现

```dart
class HTMLGenerator {
  String generate(SDUIContent content) {
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="zh-CN">');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('<meta http-equiv="Content-Security-Policy" content="${_getCSP()}">');
    buffer.writeln('<style>');
    buffer.writeln(_getStyles());
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln(_getBody(content));
    buffer.writeln('<script>');
    buffer.writeln(_getScripts());
    buffer.writeln('</script>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  String _getCSP() {
    return "default-src 'self'; "
        "script-src 'none'; "
        "style-src 'self' 'unsafe-inline'; "
        "img-src 'self' data: https:; "
        "font-src 'self' data:;";
  }

  String _getStyles() {
    return '''
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }

      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        font-size: 14px;
        line-height: 1.5;
        color: #DCDCD2;
        background-color: transparent;
        padding: 16px;
      }

      h1, h2, h3, h4, h5, h6 {
        margin-bottom: 12px;
        font-weight: 600;
      }

      p {
        margin-bottom: 8px;
      }

      a {
        color: #64B5F6;
        text-decoration: none;
      }

      a:hover {
        text-decoration: underline;
      }

      code {
        background-color: rgba(255, 255, 255, 0.1);
        padding: 2px 6px;
        border-radius: 4px;
        font-family: 'Courier New', monospace;
        font-size: 13px;
      }

      pre {
        background-color: rgba(255, 255, 255, 0.05);
        padding: 12px;
        border-radius: 8px;
        overflow-x: auto;
      }

      blockquote {
        border-left: 3px solid #E18A24;
        padding-left: 12px;
        margin: 12px 0;
        color: #919191;
      }

      ul, ol {
        padding-left: 24px;
        margin-bottom: 8px;
      }

      li {
        margin-bottom: 4px;
      }
    ''';
  }

  String _getScripts() {
    return '''
      // 禁用右键菜单
      document.addEventListener('contextmenu', function(e) {
        e.preventDefault();
      });

      // 禁用选择
      document.addEventListener('selectstart', function(e) {
        e.preventDefault();
      });

      // 通知 Flutter
      function postMessage(type, data) {
        window.flutter_inappwebview.postMessage({
          type: type,
          data: data
        });
      }
    ''';
  }

  String _getBody(SDUIContent content) {
    switch (content.type) {
      case SDUIContentType.characterStatus:
        return _generateCharacterStatus(content.data);
      case SDUIContentType.lorebookCard:
        return _generateLorebookCard(content.data);
      case SDUIContentType.custom:
        return _generateCustom(content.data);
      default:
        return '<div>未知内容类型</div>';
    }
  }

  String _generateCharacterStatus(Map<String, dynamic> data) {
    final name = data['name'] ?? '未知';
    final status = data['status'] ?? '离线';
    final avatar = data['avatar'];

    final avatarHtml = avatar != null
        ? '<img src="$avatar" alt="$name" class="avatar">'
        : '<div class="avatar-placeholder">$name.substring(0, 1)</div>';

    return '''
      <div class="character-status">
        $avatarHtml
        <div class="character-info">
          <h3>$name</h3>
          <p class="status">状态: <span class="status-value">$status</span></p>
        </div>
      </div>
    ''';
  }

  String _generateLorebookCard(Map<String, dynamic> data) {
    final title = data['title'] ?? '无标题';
    final content = data['content'] ?? '';
    final tags = data['tags'] as List<dynamic>? ?? [];

    final tagsHtml = tags
        .map((tag) => '<span class="tag">$tag</span>')
        .join('');

    return '''
      <div class="lorebook-card">
        <h4>$title</h4>
        <p>$content</p>
        $tagsHtml
      </div>
    ''';
  }

  String _generateCustom(Map<String, dynamic> data) {
    final html = data['html'] ?? '';
    return html;
  }
}
```

---

## 4. WebView 池 (WebView Pool)

### 4.1 池实现

```dart
class WebViewPool {
  final Queue<WebViewController> _pool = Queue();
  final int _maxSize = 3;
  int _currentSize = 0;

  WebViewController acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeFirst();
    }

    _currentSize++;
    return _createWebView();
  }

  void release(WebViewController controller) {
    // 清理 WebView
    controller.clearCache();
    controller.loadHtmlString('<!DOCTYPE html><html><body></body></html>');

    if (_pool.length < _maxSize) {
      _pool.add(controller);
    } else {
      _currentSize--;
      // 销毁 WebView
    }
  }

  WebViewController _createWebView() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  void clear() {
    while (_pool.isNotEmpty) {
      final controller = _pool.removeFirst();
      controller.clearCache();
    }
    _currentSize = _pool.length;
  }
}
```

---

## 5. 安全策略 (Security Policy)

### 5.1 内容过滤

```dart
class ContentSanitizer {
  static String sanitize(String input) {
    // 移除危险标签
    var result = input;

    // 移除 script 标签
    result = result.replaceAll(
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true),
      '',
    );

    // 移除 iframe 标签
    result = result.replaceAll(
      RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false, dotAll: true),
      '',
    );

    // 移除事件处理器
    result = result.replaceAll(
      RegExp(r'on\w+="[^"]*"', caseSensitive: false),
      '',
    );

    // 移除 javascript: 协议
    result = result.replaceAll(
      RegExp(r'javascript:', caseSensitive: false),
      '',
    );

    return result;
  }

  static String sanitizeHTML(String html) {
    final document = parse(html);
    final sanitized = sanitize(document.body?.innerHtml ?? '');
    return sanitized;
  }
}
```

### 5.2 CSP 策略

```dart
class ContentSecurityPolicy {
  static const String defaultPolicy = '''
    default-src 'self';
    script-src 'none';
    style-src 'self' 'unsafe-inline';
    img-src 'self' data: https:;
    font-src 'self' data:;
    connect-src 'self';
    frame-src 'none';
    object-src 'none';
    base-uri 'self';
    form-action 'self';
  ''';

  static String get customPolicy => '''
    default-src 'self';
    script-src 'self' 'unsafe-inline';
    style-src 'self' 'unsafe-inline';
    img-src 'self' data: https:;
  ''';
}
```

---

## 6. 性能优化 (Performance Optimization)

### 6.1 懒加载

```dart
class LazyWebViewRenderer extends StatefulWidget {
  final SDUIContent content;

  @override
  _LazyWebViewRendererState createState() => _LazyWebViewRendererState();
}

class _LazyWebViewRendererState extends State<LazyWebViewRenderer> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // 延迟加载
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WebViewSlotRenderer(content: widget.content);
  }
}
```

---

## 7. 迁移对照表 (Migration Reference)

| 旧 UI 概念 | 新 UI 组件 | 变化 |
| :--- | :--- | :--- |
| 内联 HTML | `WebViewSlotRenderer` | 直接嵌入 → 隔离容器 |
| HTML 生成 | `HTMLGenerator` | 无 → 统一生成器 |
| 安全过滤 | `ContentSanitizer` | 无 → CSP + 过滤 |

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`10-hybrid-sdui.md`](./10-hybrid-sdui.md) - Hybrid SDUI 引擎
- [`11-rfw-renderer.md`](./11-rfw-renderer.md) - RFW 渲染器
