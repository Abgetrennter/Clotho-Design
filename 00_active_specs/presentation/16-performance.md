# 性能优化 (Performance Optimization)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `00_active_specs/presentation/README.md`

---

## 1. 概述 (Overview)

Clotho 表现层追求 60fps+ 的流畅渲染体验。本规范定义性能优化的策略和最佳实践。

### 1.1 性能目标

| 指标 | 目标值 | 说明 |
| :--- | :--- | :--- |
| **帧率** | ≥ 60fps | 流畅动画 |
| **响应时间** | < 100ms | 用户操作响应 |
| **首屏渲染** | < 1s | 应用启动时间 |
| **内存占用** | < 500MB | 移动端内存限制 |

---

## 2. 渲染优化 (Rendering Optimization)

### 2.1 const 构造函数

```dart
// ✅ 推荐：使用 const
const SizedBox(width: 16);
const EdgeInsets.all(16);
const Text('Hello');

// ❌ 避免：重复创建
SizedBox(width: 16);
EdgeInsets.all(16);
```

### 2.2 避免不必要的重建

```dart
// ❌ 错误：每次都重建
class BadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 1000,
      itemBuilder: (context, index) {
        return Container(
          child: Text('Item $index'),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}

// ✅ 正确：提取 const
class GoodWidget extends StatelessWidget {
  static const _itemDecoration = BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 1000,
      itemBuilder: (context, index) {
        return Container(
          child: Text('Item $index'),
          decoration: _itemDecoration,
        );
      },
    );
  }
}
```

### 2.3 使用 RepaintBoundary

```dart
class OptimizedMessageBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Text(message.content),
      ),
    );
  }
}
```

---

## 3. 列表优化 (List Optimization)

### 3.1 ListView.builder

```dart
// ✅ 推荐：使用 ListView.builder
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (context, index) {
    return MessageBubble(message: messages[index]);
  },
)

// ❌ 避免：使用 ListView（一次性构建所有子项）
ListView(
  children: messages.map((m) => MessageBubble(message: m)).toList(),
)
```

### 3.2 虚拟滚动

```dart
class VirtualListView extends StatelessWidget {
  final List<Message> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return _buildMessage(context, messages[index]);
      },
      // 添加缓存
      cacheExtent: 500,
    );
  }

  Widget _buildMessage(BuildContext context, Message message) {
    return RepaintBoundary(
      child: MessageBubble(message: message),
    );
  }
}
```

---

## 4. 图片优化 (Image Optimization)

### 4.1 图片缓存

```dart
class CachedAvatar extends StatelessWidget {
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      // 启用缓存
      cacheWidth: 80,
      cacheHeight: 80,
      // 错误处理
      errorBuilder: (context, error, stackTrace) {
        return CircleAvatar(
          child: Icon(Icons.person),
        );
      },
      // 加载占位
      loadingBuilder: (context, child, loadingProgress) {
        return CircularProgressIndicator();
      },
    );
  }
}
```

### 4.2 图片压缩

```dart
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      // 使用 WebP 格式
      frameBuilder: (context, child, frame) {
        return child;
      },
    );
  }
}
```

---

## 5. 状态管理优化 (State Management Optimization)

### 5.1 Provider 优化

```dart
// ✅ 推荐：使用 Selector
Selector<ChatState, List<Message>>(
  selector: (context, chat) => chat.messages,
  builder: (context, messages, child) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: messages[index]);
      },
    );
  },
)

// ❌ 避免：使用 Consumer（会重建整个组件）
Consumer<ChatState>(
  builder: (context, chat, child) {
    return ListView.builder(
      itemCount: chat.messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: chat.messages[index]);
      },
    );
  },
)
```

### 5.2 ChangeNotifier 优化

```dart
class OptimizedNotifier extends ChangeNotifier {
  List<Message> _messages = [];

  List<Message> get messages => _messages;

  void addMessage(Message message) {
    _messages.add(message);
    // 只通知必要的监听器
    notifyListeners();
  }

  void updateMessage(int index, Message message) {
    _messages[index] = message;
    notifyListeners();
  }
}
```

---

## 6. WebView 优化 (WebView Optimization)

### 6.1 WebView 池

```dart
class WebViewPool {
  final Queue<WebViewController> _pool = Queue();
  final int _maxSize = 3;

  WebViewController acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeFirst();
    }
    return _createWebView();
  }

  void release(WebViewController controller) {
    controller.clearCache();
    if (_pool.length < _maxSize) {
      _pool.add(controller);
    }
  }

  void clear() {
    while (_pool.isNotEmpty) {
      final controller = _pool.removeFirst();
      controller.clearCache();
    }
  }
}
```

### 6.2 懒加载

```dart
class LazyWebView extends StatefulWidget {
  final String html;

  @override
  _LazyWebViewState createState() => _LazyWebViewState();
}

class _LazyWebViewState extends State<LazyWebView> {
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
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WebViewWidget(
      controller: WebViewController()
        ..loadHtmlString(widget.html),
    );
  }
}
```

---

## 7. 内存优化 (Memory Optimization)

### 7.1 避免内存泄漏

```dart
class MemorySafeWidget extends StatefulWidget {
  @override
  _MemorySafeWidgetState createState() => _MemorySafeWidgetState();
}

class _MemorySafeWidgetState extends State<MemorySafeWidget> {
  StreamSubscription? _subscription;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _subscription = someStream.listen((data) {
      // 处理数据
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      // 定时任务
    });
  }

  @override
  void dispose() {
    // 释放资源
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

### 7.2 图片缓存清理

```dart
class ImageCacheManager {
  static void clearCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  static int get cacheSize {
    return PaintingBinding.instance.imageCache.currentSize;
  }

  static int get cacheCount {
    return PaintingBinding.instance.imageCache.currentSizeBytes;
  }
}
```

---

## 8. 性能监控 (Performance Monitoring)

### 8.1 帧率监控

```dart
class PerformanceMonitor {
  static void startMonitoring() {
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final frame in timings) {
        if (frame.totalSpan.inMilliseconds > 16) {
          // 帧率低于 60fps
          print('Frame dropped: ${frame.totalSpan.inMilliseconds}ms');
        }
      }
    });
  }

  static void stopMonitoring() {
    WidgetsBinding.instance.addTimingsCallback(null);
  }
}
```

### 8.2 性能指标

```dart
class PerformanceMetrics {
  static final Map<String, int> _metrics = {};

  static void recordMetric(String name, int value) {
    _metrics[name] = value;
  }

  static int? getMetric(String name) {
    return _metrics[name];
  }

  static Map<String, int> getAllMetrics() {
    return Map.from(_metrics);
  }

  static void clear() {
    _metrics.clear();
  }
}
```

---

## 9. 迁移对照表 (Migration Reference)

| 旧 UI 问题 | 新 UI 解决方案 | 变化 |
| :--- | :--- | :--- |
| DOM 操作频繁 | Flutter Widget 树 | 直接操作 → 声明式 |
| 无缓存机制 | Image.network 缓存 | 无 → 自动缓存 |
| 内存泄漏 | dispose 清理 | 无 → 资源释放 |
| 列表卡顿 | ListView.builder | 无 → 虚拟滚动 |

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`17-animation.md`](./17-animation.md) - 动画与过渡
