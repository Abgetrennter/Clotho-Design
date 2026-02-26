# 性能优化策略 (Performance Optimization Strategy)

**版本**: 1.0.0
**日期**: 2026-02-25
**状态**: Draft
**类型**: Architecture Spec
**作者**: Clotho 架构团队

---

## 1. 概述 (Overview)

Clotho 表现层追求 60fps+ 的流畅渲染体验。本规范定义性能优化的策略、监控方法和问题排查指南，确保应用在各种设备上都能提供高性能体验。

### 1.1 性能目标

| 指标 | 目标值 | 说明 |
| :--- | :--- | :--- |
| **帧率 (FPS)** | ≥ 60fps | 流畅动画体验 |
| **响应时间** | < 100ms | 用户操作响应延迟 |
| **首屏渲染** | < 1s | 应用启动到首屏显示 |
| **内存占用** | < 500MB | 移动端内存限制 |
| **列表滚动** | ≥ 60fps | 长列表滚动流畅度 |
| **WebView 加载** | < 500ms | WebView 内容加载时间 |

### 1.2 性能优化原则

| 原则 | 说明 |
| :--- | :--- |
| **原生优先** | 优先使用 RFW 原生渲染，避免 WebView |
| **惰性加载** | 按需加载组件和数据 |
| **缓存复用** | 缓存图片、模板、渲染结果 |
| **减少重建** | 最小化 Widget 重建范围 |
| **异步处理** | 耗时操作异步执行 |

---

## 2. 性能指标 (Performance Metrics)

### 2.1 帧率监控

```dart
// utils/performance_monitor.dart

class PerformanceMonitor {
  final Map<String, List<int>> _frameTimes = {};
  final Map<String, int> _frameCounts = {};
  
  /// 记录帧时间
  void recordFrameTime(String tag, int milliseconds) {
    _frameTimes.putIfAbsent(tag, () => []);
    _frameTimes[tag]!.add(milliseconds);
    _frameCounts[tag] = (_frameCounts[tag] ?? 0) + 1;
    
    // 限制记录数量
    if (_frameTimes[tag]!.length > 1000) {
      _frameTimes[tag]!.removeAt(0);
    }
  }
  
  /// 计算平均帧率
  double getAverageFPS(String tag) {
    final times = _frameTimes[tag];
    if (times == null || times.isEmpty) return 0;
    
    final avgTime = times.reduce((a, b) => a + b) / times.length;
    return 1000 / avgTime;
  }
  
  /// 计算第 95 百分位帧时间
  int getP95FrameTime(String tag) {
    final times = _frameTimes[tag];
    if (times == null || times.isEmpty) return 0;
    
    final sorted = List<int>.from(times)..sort();
    final index = (sorted.length * 0.95).floor();
    return sorted[index];
  }
  
  /// 获取性能报告
  PerformanceReport getReport(String tag) {
    return PerformanceReport(
      tag: tag,
      averageFPS: getAverageFPS(tag),
      p95FrameTime: getP95FrameTime(tag),
      frameCount: _frameCounts[tag] ?? 0,
    );
  }
}

@immutable
class PerformanceReport {
  final String tag;
  final double averageFPS;
  final int p95FrameTime;
  final int frameCount;
  
  const PerformanceReport({
    required this.tag,
    required this.averageFPS,
    required this.p95FrameTime,
    required this.frameCount,
  });
  
  @override
  String toString() {
    return 'PerformanceReport($tag): '
        'FPS: ${averageFPS.toStringAsFixed(1)}, '
        'P95: ${p95FrameTime}ms, '
        'Frames: $frameCount';
  }
}

// 在 Widget 中使用
class PerformanceWidget extends StatefulWidget {
  final Widget child;
  final String tag;
  
  const PerformanceWidget({
    required this.child,
    required this.tag,
  });
  
  @override
  State<PerformanceWidget> createState() => _PerformanceWidgetState();
}

class _PerformanceWidgetState extends State<PerformanceWidget> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  int? _lastFrameTime;
  
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch;
    
    if (_lastFrameTime != null) {
      final frameTime = now - _lastFrameTime!;
      _monitor.recordFrameTime(widget.tag, frameTime);
    }
    
    _lastFrameTime = now;
    
    return widget.child;
  }
}
```

### 2.2 响应时间监控

```dart
// utils/response_time_monitor.dart

class ResponseTimeMonitor {
  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<int>> _responseTimes = {};
  
  /// 开始计时
  void start(String operation) {
    _startTimes[operation] = DateTime.now();
  }
  
  /// 结束计时
  void end(String operation) {
    final startTime = _startTimes[operation];
    if (startTime == null) return;
    
    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _responseTimes.putIfAbsent(operation, () => []);
    _responseTimes[operation]!.add(duration);
    
    _startTimes.remove(operation);
    
    // 限制记录数量
    if (_responseTimes[operation]!.length > 1000) {
      _responseTimes[operation]!.removeAt(0);
    }
  }
  
  /// 获取平均响应时间
  int getAverageResponseTime(String operation) {
    final times = _responseTimes[operation];
    if (times == null || times.isEmpty) return 0;
    
    return times.reduce((a, b) => a + b) ~/ times.length;
  }
  
  /// 获取响应时间报告
  Map<String, int> getReport() {
    final report = <String, int>{};
    for (final operation in _responseTimes.keys) {
      report[operation] = getAverageResponseTime(operation);
    }
    return report;
  }
}

// 使用示例
class MessageSender {
  final ResponseTimeMonitor _monitor = ResponseTimeMonitor();
  
  Future<void> sendMessage(String content) async {
    _monitor.start('send_message');
    
    try {
      await _doSendMessage(content);
    } finally {
      _monitor.end('send_message');
    }
  }
  
  Future<void> _doSendMessage(String content) async {
    // 实际发送逻辑
  }
}
```

### 2.3 内存监控

```dart
// utils/memory_monitor.dart

class MemoryMonitor {
  static final MemoryMonitor _instance = MemoryMonitor._internal();
  factory MemoryMonitor() => _instance;
  MemoryMonitor._internal();
  
  final List<MemorySnapshot> _snapshots = [];
  
  /// 获取当前内存使用情况
  Future<MemoryInfo> getCurrentMemoryUsage() async {
    final info = await MemoryMonitor.getMemoryInfo();
    return MemoryInfo(
      totalMemory: info.totalMemory,
      usedMemory: info.usedMemory,
      freeMemory: info.freeMemory,
    );
  }
  
  /// 记录内存快照
  Future<void> recordSnapshot(String tag) async {
    final info = await getCurrentMemoryUsage();
    _snapshots.add(MemorySnapshot(
      tag: tag,
      timestamp: DateTime.now(),
      memoryInfo: info,
    ));
    
    // 限制快照数量
    if (_snapshots.length > 100) {
      _snapshots.removeAt(0);
    }
  }
  
  /// 获取内存使用趋势
  List<MemorySnapshot> getSnapshots({String? tag}) {
    if (tag == null) return List.from(_snapshots);
    return _snapshots.where((s) => s.tag == tag).toList();
  }
}

@immutable
class MemoryInfo {
  final int totalMemory;
  final int usedMemory;
  final int freeMemory;
  
  const MemoryInfo({
    required this.totalMemory,
    required this.usedMemory,
    required this.freeMemory,
  });
  
  double get usagePercentage => (usedMemory / totalMemory) * 100;
}

@immutable
class MemorySnapshot {
  final String tag;
  final DateTime timestamp;
  final MemoryInfo memoryInfo;
  
  const MemorySnapshot({
    required this.tag,
    required this.timestamp,
    required this.memoryInfo,
  });
}
```

---

## 3. 优化策略 (Optimization Strategies)

### 3.1 惰性构建

```dart
// 惰性构建示例

// ❌ 错误：一次性构建所有子项
class BadListView extends StatelessWidget {
  final List<Message> messages;
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: messages.map((m) => MessageBubble(message: m)).toList(),
    );
  }
}

// ✅ 正确：使用 ListView.builder
class GoodListView extends StatelessWidget {
  final List<Message> messages;
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return MessageBubble(message: messages[index]);
      },
    );
  }
}

// ✅ 更好：添加缓存和 RepaintBoundary
class OptimizedListView extends StatelessWidget {
  final List<Message> messages;
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: messages.length,
      cacheExtent: 500, // 预加载范围
      itemBuilder: (context, index) {
        return RepaintBoundary(
          child: MessageBubble(message: messages[index]),
        );
      },
    );
  }
}
```

### 3.2 图片缓存

```dart
// utils/image_cache_manager.dart

class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();
  
  final Map<String, CachedImage> _cache = {};
  final int _maxCacheSize = 100 * 1024 * 1024; // 100MB
  int _currentCacheSize = 0;
  
  /// 获取缓存的图片
  CachedImage? getCachedImage(String url) {
    return _cache[url];
  }
  
  /// 缓存图片
  void cacheImage(String url, CachedImage image) {
    // 检查缓存大小
    if (_currentCacheSize + image.size > _maxCacheSize) {
      _evictLRU();
    }
    
    _cache[url] = image;
    _currentCacheSize += image.size;
  }
  
  /// 清理最少使用的图片
  void _evictLRU() {
    if (_cache.isEmpty) return;
    
    final sorted = _cache.entries.toList()
      ..sort((a, b) => a.value.lastAccess.compareTo(b.value.lastAccess));
    
    while (_currentCacheSize > _maxCacheSize * 0.8 && sorted.isNotEmpty) {
      final entry = sorted.removeAt(0);
      _currentCacheSize -= entry.value.size;
      _cache.remove(entry.key);
    }
  }
  
  /// 清除缓存
  void clearCache() {
    _cache.clear();
    _currentCacheSize = 0;
  }
}

@immutable
class CachedImage {
  final Uint8List bytes;
  final int size;
  final DateTime lastAccess;
  
  CachedImage({
    required this.bytes,
    required this.size,
  }) : lastAccess = DateTime.now();
}

// 使用示例
class CachedAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  
  const CachedAvatar({
    required this.imageUrl,
    this.size = 48,
  });
  
  @override
  Widget build(BuildContext context) {
    final cacheManager = ImageCacheManager();
    final cached = cacheManager.getCachedImage(imageUrl);
    
    if (cached != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: MemoryImage(cached.bytes),
      );
    }
    
    return Image.network(
      imageUrl,
      width: size,
      height: size,
      cacheWidth: size.toInt(),
      cacheHeight: size.toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return CircleAvatar(
          radius: size / 2,
          child: CircularProgressIndicator(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return CircleAvatar(
          radius: size / 2,
          child: Icon(Icons.person),
        );
      },
    );
  }
}
```

### 3.3 WebView 池化

```dart
// utils/webview_pool.dart

class WebViewPool {
  static final WebViewPool _instance = WebViewPool._internal();
  factory WebViewPool() => _instance;
  WebViewPool._internal();
  
  final List<WebViewController> _availableControllers = [];
  final Set<WebViewController> _inUseControllers = {};
  final int _maxPoolSize = 5;
  
  /// 获取可用的 WebView 控制器
  WebViewController acquire() {
    if (_availableControllers.isNotEmpty) {
      final controller = _availableControllers.removeLast();
      _inUseControllers.add(controller);
      return controller;
    }
    
    // 创建新的控制器
    final controller = _createController();
    _inUseControllers.add(controller);
    return controller;
  }
  
  /// 释放 WebView 控制器
  void release(WebViewController controller) {
    if (_inUseControllers.contains(controller)) {
      _inUseControllers.remove(controller);
      
      if (_availableControllers.length < _maxPoolSize) {
        _availableControllers.add(controller);
      } else {
        // 超过池大小，销毁控制器
        controller.clearCache();
      }
    }
  }
  
  /// 创建 WebView 控制器
  WebViewController _createController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // 页面加载完成
          },
        ),
      );
  }
  
  /// 清空池
  void clearPool() {
    for (final controller in _availableControllers) {
      controller.clearCache();
    }
    _availableControllers.clear();
  }
}

// 使用示例
class PooledWebView extends StatefulWidget {
  final String html;
  
  const PooledWebView({required this.html});
  
  @override
  State<PooledWebView> createState() => _PooledWebViewState();
}

class _PooledWebViewState extends State<PooledWebView> {
  late WebViewController _controller;
  final WebViewPool _pool = WebViewPool();
  
  @override
  void initState() {
    super.initState();
    _controller = _pool.acquire();
    _loadHtml();
  }
  
  void _loadHtml() {
    _controller.loadHtmlString(widget.html);
  }
  
  @override
  void didUpdateWidget(PooledWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html) {
      _loadHtml();
    }
  }
  
  @override
  void dispose() {
    _pool.release(_controller);
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
```

### 3.4 RFW 缓存

```dart
// utils/rfw_cache_manager.dart

class RFWCacheManager {
  static final RFWCacheManager _instance = RFWCacheManager._internal();
  factory RFWCacheManager() => _instance;
  RFWCacheManager._internal();
  
  final Map<String, CachedRFWPackage> _cache = {};
  final int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  int _currentCacheSize = 0;
  
  /// 获取缓存的 RFW 包
  CachedRFWPackage? getCachedPackage(String name) {
    final cached = _cache[name];
    if (cached != null) {
      // 更新访问时间
      _cache[name] = cached.copyWith(lastAccess: DateTime.now());
    }
    return cached;
  }
  
  /// 缓存 RFW 包
  void cachePackage(String name, CachedRFWPackage package) {
    // 检查缓存大小
    if (_currentCacheSize + package.size > _maxCacheSize) {
      _evictLRU();
    }
    
    _cache[name] = package;
    _currentCacheSize += package.size;
  }
  
  /// 清理最少使用的包
  void _evictLRU() {
    if (_cache.isEmpty) return;
    
    final sorted = _cache.entries.toList()
      ..sort((a, b) => a.value.lastAccess.compareTo(b.value.lastAccess));
    
    while (_currentCacheSize > _maxCacheSize * 0.8 && sorted.isNotEmpty) {
      final entry = sorted.removeAt(0);
      _currentCacheSize -= entry.value.size;
      _cache.remove(entry.key);
    }
  }
  
  /// 清除缓存
  void clearCache() {
    _cache.clear();
    _currentCacheSize = 0;
  }
}

@immutable
class CachedRFWPackage {
  final String name;
  final String version;
  final Map<String, dynamic> schema;
  final Widget Function(Map<String, dynamic> data) builder;
  final int size;
  final DateTime lastAccess;
  
  const CachedRFWPackage({
    required this.name,
    required this.version,
    required this.schema,
    required this.builder,
    required this.size,
    required this.lastAccess,
  });
  
  CachedRFWPackage copyWith({DateTime? lastAccess}) {
    return CachedRFWPackage(
      name: name,
      version: version,
      schema: schema,
      builder: builder,
      size: size,
      lastAccess: lastAccess ?? this.lastAccess,
    );
  }
}
```

---

## 4. 性能监控 (Performance Monitoring)

### 4.1 性能分析器

```dart
// widgets/performance_overlay.dart

class PerformanceOverlay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitor = ref.watch(performanceMonitorProvider);
    final report = monitor.getReport('main');
    
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '性能监控',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _buildMetric('FPS', '${report.averageFPS.toStringAsFixed(1)}'),
            _buildMetric('P95', '${report.p95FrameTime}ms'),
            _buildMetric('Frames', '${report.frameCount}'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetric(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Provider
final performanceMonitorProvider = Provider<PerformanceMonitor>((ref) {
  return PerformanceMonitor();
});
```

### 4.2 性能日志

```dart
// utils/performance_logger.dart

class PerformanceLogger {
  static final PerformanceLogger _instance = PerformanceLogger._internal();
  factory PerformanceLogger() => _instance;
  PerformanceLogger._internal();
  
  final List<PerformanceLogEntry> _logs = [];
  final int _maxLogSize = 1000;
  
  /// 记录性能日志
  void log(PerformanceLogEntry entry) {
    _logs.add(entry);
    
    // 限制日志数量
    if (_logs.length > _maxLogSize) {
      _logs.removeAt(0);
    }
  }
  
  /// 记录操作耗时
  void logOperation(String operation, int duration) {
    log(PerformanceLogEntry(
      type: LogType.operation,
      message: operation,
      duration: duration,
      timestamp: DateTime.now(),
    ));
  }
  
  /// 记录错误
  void logError(String error, StackTrace stackTrace) {
    log(PerformanceLogEntry(
      type: LogType.error,
      message: error,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    ));
  }
  
  /// 获取日志
  List<PerformanceLogEntry> getLogs({LogType? type}) {
    if (type == null) return List.from(_logs);
    return _logs.where((l) => l.type == type).toList();
  }
  
  /// 导出日志
  String exportLogs() {
    final buffer = StringBuffer();
    for (final log in _logs) {
      buffer.writeln(log.toString());
    }
    return buffer.toString();
  }
  
  /// 清除日志
  void clearLogs() {
    _logs.clear();
  }
}

enum LogType {
  operation,
  error,
  warning,
  info,
}

@immutable
class PerformanceLogEntry {
  final LogType type;
  final String message;
  final int? duration;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  
  const PerformanceLogEntry({
    required this.type,
    required this.message,
    this.duration,
    this.stackTrace,
    required this.timestamp,
  });
  
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${type.name.toUpperCase()}] ');
    buffer.write(message);
    if (duration != null) {
      buffer.write(' (${duration}ms)');
    }
    if (stackTrace != null) {
      buffer.write('\n$stackTrace');
    }
    return buffer.toString();
  }
}
```

### 4.3 性能报告

```dart
// utils/performance_reporter.dart

class PerformanceReporter {
  final PerformanceMonitor _monitor;
  final ResponseTimeMonitor _responseMonitor;
  final MemoryMonitor _memoryMonitor;
  
  PerformanceReporter({
    required PerformanceMonitor monitor,
    required ResponseTimeMonitor responseMonitor,
    required MemoryMonitor memoryMonitor,
  })  : _monitor = monitor,
        _responseMonitor = responseMonitor,
        _memoryMonitor = memoryMonitor;
  
  /// 生成性能报告
  Future<PerformanceReportData> generateReport() async {
    return PerformanceReportData(
      timestamp: DateTime.now(),
      fpsReport: _monitor.getReport('main'),
      responseTimes: _responseMonitor.getReport(),
      memoryUsage: await _memoryMonitor.getCurrentMemoryUsage(),
    );
  }
  
  /// 导出为 JSON
  String exportToJson(PerformanceReportData report) {
    return jsonEncode(report.toJson());
  }
  
  /// 导出为 Markdown
  String exportToMarkdown(PerformanceReportData report) {
    final buffer = StringBuffer();
    
    buffer.writeln('# 性能报告');
    buffer.writeln();
    buffer.writeln('**时间**: ${report.timestamp.toIso8601String()}');
    buffer.writeln();
    
    buffer.writeln('## 帧率');
    buffer.writeln('- 平均 FPS: ${report.fpsReport.averageFPS.toStringAsFixed(1)}');
    buffer.writeln('- P95 帧时间: ${report.fpsReport.p95FrameTime}ms');
    buffer.writeln('- 总帧数: ${report.fpsReport.frameCount}');
    buffer.writeln();
    
    buffer.writeln('## 响应时间');
    for (final entry in report.responseTimes.entries) {
      buffer.writeln('- ${entry.key}: ${entry.value}ms');
    }
    buffer.writeln();
    
    buffer.writeln('## 内存使用');
    buffer.writeln('- 总内存: ${_formatBytes(report.memoryUsage.totalMemory)}');
    buffer.writeln('- 已使用: ${_formatBytes(report.memoryUsage.usedMemory)}');
    buffer.writeln('- 空闲: ${_formatBytes(report.memoryUsage.freeMemory)}');
    buffer.writeln('- 使用率: ${report.memoryUsage.usagePercentage.toStringAsFixed(1)}%');
    
    return buffer.toString();
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

@immutable
class PerformanceReportData {
  final DateTime timestamp;
  final PerformanceReport fpsReport;
  final Map<String, int> responseTimes;
  final MemoryInfo memoryUsage;
  
  const PerformanceReportData({
    required this.timestamp,
    required this.fpsReport,
    required this.responseTimes,
    required this.memoryUsage,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'fps': {
        'average': fpsReport.averageFPS,
        'p95': fpsReport.p95FrameTime,
        'count': fpsReport.frameCount,
      },
      'responseTimes': responseTimes,
      'memory': {
        'total': memoryUsage.totalMemory,
        'used': memoryUsage.usedMemory,
        'free': memoryUsage.freeMemory,
        'usage': memoryUsage.usagePercentage,
      },
    };
  }
}
```

---

## 5. 性能问题排查 (Performance Troubleshooting)

### 5.1 常见性能问题

| 问题 | 可能原因 | 解决方案 |
| :--- | :--- | :--- |
| **帧率低** | 过多的 Widget 重建 | 使用 `const`、`RepaintBoundary` |
| **内存占用高** | 图片未缓存、内存泄漏 | 实现图片缓存、及时清理 |
| **列表卡顿** | 未使用 `ListView.builder` | 改用惰性构建 |
| **WebView 加载慢** | 未使用池化 | 实现 WebView 池 |
| **状态更新慢** | 状态树过大 | 使用增量更新 |

### 5.2 排查工具

```dart
// utils/performance_profiler.dart

class PerformanceProfiler {
  static final PerformanceProfiler _instance = PerformanceProfiler._internal();
  factory PerformanceProfiler() => _instance;
  PerformanceProfiler._internal();
  
  bool _isProfiling = false;
  final List<ProfileEntry> _entries = [];
  
  /// 开始性能分析
  void startProfiling() {
    _isProfiling = true;
    _entries.clear();
  }
  
  /// 停止性能分析
  void stopProfiling() {
    _isProfiling = false;
  }
  
  /// 记录性能数据
  void record(String tag, int duration) {
    if (!_isProfiling) return;
    
    _entries.add(ProfileEntry(
      tag: tag,
      duration: duration,
      timestamp: DateTime.now(),
    ));
  }
  
  /// 生成分析报告
  ProfileReport generateReport() {
    final grouped = <String, List<int>>{};
    for (final entry in _entries) {
      grouped.putIfAbsent(entry.tag, () => []);
      grouped[entry.tag]!.add(entry.duration);
    }
    
    final summary = <String, ProfileSummary>{};
    for (final entry in grouped.entries) {
      final durations = entry.value;
      durations.sort();
      
      summary[entry.key] = ProfileSummary(
        count: durations.length,
        total: durations.reduce((a, b) => a + b),
        average: durations.reduce((a, b) => a + b) ~/ durations.length,
        min: durations.first,
        max: durations.last,
        p50: durations[(durations.length * 0.5).floor()],
        p95: durations[(durations.length * 0.95).floor()],
        p99: durations[(durations.length * 0.99).floor()],
      );
    }
    
    return ProfileReport(
      entries: _entries,
      summary: summary,
    );
  }
}

@immutable
class ProfileEntry {
  final String tag;
  final int duration;
  final DateTime timestamp;
  
  const ProfileEntry({
    required this.tag,
    required this.duration,
    required this.timestamp,
  });
}

@immutable
class ProfileSummary {
  final int count;
  final int total;
  final int average;
  final int min;
  final int max;
  final int p50;
  final int p95;
  final int p99;
  
  const ProfileSummary({
    required this.count,
    required this.total,
    required this.average,
    required this.min,
    required this.max,
    required this.p50,
    required this.p95,
    required this.p99,
  });
}

@immutable
class ProfileReport {
  final List<ProfileEntry> entries;
  final Map<String, ProfileSummary> summary;
  
  const ProfileReport({
    required this.entries,
    required this.summary,
  });
}

// 使用示例
class ProfiledWidget extends StatefulWidget {
  final Widget child;
  
  const ProfiledWidget({required this.child});
  
  @override
  State<ProfiledWidget> createState() => _ProfiledWidgetState();
}

class _ProfiledWidgetState extends State<ProfiledWidget> {
  final PerformanceProfiler _profiler = PerformanceProfiler();
  DateTime? _buildStart;
  
  @override
  void initState() {
    super.initState();
    _profiler.startProfiling();
  }
  
  @override
  Widget build(BuildContext context) {
    _buildStart = DateTime.now();
    return widget.child;
  }
  
  @override
  void didUpdateWidget(ProfiledWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_buildStart != null) {
      final duration = DateTime.now().difference(_buildStart!).inMilliseconds;
      _profiler.record('build', duration);
    }
  }
  
  @override
  void dispose() {
    _profiler.stopProfiling();
    final report = _profiler.generateReport();
    print(report);
    super.dispose();
  }
}
```

---

## 6. 代码示例 (Code Examples)

### 6.1 完整的性能优化示例

```dart
class OptimizedChatScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<OptimizedChatScreen> createState() => _OptimizedChatScreenState();
}

class _OptimizedChatScreenState extends ConsumerState<OptimizedChatScreen> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  final ResponseTimeMonitor _responseMonitor = ResponseTimeMonitor();
  
  @override
  Widget build(BuildContext context) {
    return PerformanceWidget(
      tag: 'chat_screen',
      child: Scaffold(
        appBar: AppBar(
          title: Text('聊天'),
          actions: [
            IconButton(
              icon: Icon(Icons.analytics),
              onPressed: () => _showPerformanceReport(),
            ),
          ],
        ),
        body: Column(
          children: [
            // 消息列表
            Expanded(
              child: OptimizedMessageList(),
            ),
            // 输入区域
            MessageInput(),
          ],
        ),
      ),
    );
  }
  
  void _showPerformanceReport() {
    final fpsReport = _monitor.getReport('chat_screen');
    final responseReport = _responseMonitor.getReport();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('性能报告'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('帧率'),
              Text('平均 FPS: ${fpsReport.averageFPS.toStringAsFixed(1)}'),
              Text('P95: ${fpsReport.p95FrameTime}ms'),
              Text('总帧数: ${fpsReport.frameCount}'),
              SizedBox(height: 16),
              Text('响应时间'),
              ...responseReport.entries.map((e) => Text('${e.key}: ${e.value}ms')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class OptimizedMessageList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messageListProvider);
    
    return ListView.builder(
      itemCount: messages.length,
      cacheExtent: 500,
      itemBuilder: (context, index) {
        return RepaintBoundary(
          key: ValueKey(messages[index].id),
          child: MessageBubble(message: messages[index]),
        );
      },
    );
  }
}
```

---

## 7. 关联文档 (Related Documents)

- [`16-performance.md`](./16-performance.md) - 性能优化基础
- [`10-hybrid-sdui.md`](./10-hybrid-sdui.md) - Hybrid SDUI 引擎
- [`11-rfw-renderer.md`](./11-rfw-renderer.md) - RFW 渲染器
- [`12-webview-fallback.md`](./12-webview-fallback.md) - WebView 兜底机制
- [`state-sync-events.md`](./state-sync-events.md) - 状态同步与事件流
- [`../infrastructure/logging-standards.md`](../infrastructure/logging-standards.md) - 日志规范

---

**最后更新**: 2026-02-25  
**文档状态**: 草案，待架构评审委员会审议
