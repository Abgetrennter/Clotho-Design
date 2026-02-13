# RFW 渲染器 (RFW Renderer)

**版本**: 1.0.0
**日期**: 2026-02-11
**状态**: Draft
**参考**: `00_active_specs/presentation/10-hybrid-sdui.md`

---

## 1. 概述 (Overview)

RFW (Remote Flutter Widgets) 渲染器是 Hybrid SDUI 的原生渲染轨道，负责渲染高性能的 Flutter 组件。本规范定义 RFW 包的结构、加载和渲染机制。

### 1.1 设计原则

| 原则 | 说明 |
| :--- | :--- |
| **类型安全** | 使用 Schema 定义数据结构 |
| **性能优先** | 原生渲染，无 WebView 开销 |
| **可扩展** | 支持第三方扩展包 |
| **异常处理** | 渲染失败时降级到 WebView |

---

## 2. RFW 包结构 (RFW Package Structure)

### 2.1 包定义

```dart
class RFWPackage {
  final String name;
  final String version;
  final String type;
  final Map<String, dynamic> schema;
  final Widget Function(Map<String, dynamic> data) builder;

  RFWPackage({
    required this.name,
    required this.version,
    required this.type,
    required this.schema,
    required this.builder,
  });

  /// 验证数据是否符合 Schema
  bool validate(Map<String, dynamic> data) {
    for (final entry in schema.entries) {
      final key = entry.key;
      final type = entry.value;

      if (!data.containsKey(key)) {
        return false;
      }

      final value = data[key];
      if (!_checkType(value, type)) {
        return false;
      }
    }
    return true;
  }

  bool _checkType(dynamic value, String type) {
    switch (type) {
      case 'string':
        return value is String;
      case 'number':
        return value is num;
      case 'boolean':
        return value is bool;
      case 'array':
        return value is List;
      case 'object':
        return value is Map;
      default:
        return true;
    }
  }
}
```

### 2.2 包元数据

```dart
class RFWPackageMetadata {
  final String name;
  final String version;
  final String author;
  final String description;
  final List<String> dependencies;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RFWPackageMetadata({
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    this.dependencies = const [],
    required this.createdAt,
    this.updatedAt,
  });
}
```

---

## 3. RFW 加载器 (RFW Loader)

### 3.1 加载器实现

```dart
class RFWLoader {
  final Map<String, RFWPackage> _loadedPackages = {};

  /// 从本地加载包
  Future<RFWPackage?> loadFromPath(String path) async {
    try {
      final file = File(path);
      final json = await file.readAsString();
      final data = jsonDecode(json);

      final metadata = RFWPackageMetadata(
        name: data['name'],
        version: data['version'],
        author: data['author'],
        description: data['description'],
        dependencies: List<String>.from(data['dependencies'] ?? []),
        createdAt: DateTime.parse(data['createdAt']),
        updatedAt: data['updatedAt'] != null
            ? DateTime.parse(data['updatedAt'])
            : null,
      );

      // 加载动态代码
      final package = await _loadPackageCode(path, metadata);

      _loadedPackages[metadata.name] = package;
      return package;
    } catch (e) {
      return null;
    }
  }

  /// 加载包代码
  Future<RFWPackage> _loadPackageCode(
    String path,
    RFWPackageMetadata metadata,
  ) async {
    // 这里应该使用动态加载机制
    // 实际实现可能需要使用 isolate 或类似技术
    return RFWPackage(
      name: metadata.name,
      version: metadata.version,
      type: metadata.name,
      schema: {},
      builder: (data) => Container(
        child: Text('RFW Package: ${metadata.name}'),
      ),
    );
  }

  /// 获取已加载的包
  RFWPackage? getPackage(String name) {
    return _loadedPackages[name];
  }
}
```

---

## 4. RFW 渲染器 (RFW Renderer)

### 4.1 渲染器实现

```dart
class RFWSlotRenderer extends StatefulWidget {
  final RFWPackage package;
  final Map<String, dynamic> data;
  final Widget Function(Object error)? onError;

  @override
  _RFWSlotRendererState createState() => _RFWSlotRendererState();
}

class _RFWSlotRendererState extends State<RFWSlotRenderer> {
  Object? _error;
  bool _isValidating = true;

  @override
  void initState() {
    super.initState();
    _validateAndRender();
  }

  Future<void> _validateAndRender() async {
    setState(() {
      _isValidating = true;
      _error = null;
    });

    // 验证数据
    if (!widget.package.validate(widget.data)) {
      setState(() {
        _isValidating = false;
        _error = 'Data validation failed';
      });
      return;
    }

    // 渲染组件
    try {
      setState(() {
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidating) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return widget.onError?.call(_error!) ??
          FallbackSlotRenderer(
            content: SDUIContent(
              id: 'error',
              type: SDUIContentType.custom,
              data: {'error': _error.toString()},
            ),
          );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: 300,
        maxWidth: double.infinity,
      ),
      child: widget.package.builder(widget.data),
    );
  }
}
```

---

## 5. 内置 RFW 包 (Built-in RFW Packages)

### 5.1 角色状态包

```dart
class CharacterStatusPackage extends RFWPackage {
  CharacterStatusPackage()
      : super(
          name: 'CharacterStatus',
          version: '1.0.0',
          type: 'characterStatus',
          schema: {
            'name': 'string',
            'status': 'string',
            'avatar': 'string?',
          },
          builder: (data) {
            final name = data['name'] ?? '未知';
            final status = data['status'] ?? '离线';
            final avatar = data['avatar'];

            return Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (avatar != null)
                    CircleAvatar(
                      backgroundImage: NetworkImage(avatar!),
                      radius: 20,
                    )
                  else
                    CircleAvatar(
                      child: Text(name.substring(0, 1)),
                      radius: 20,
                    ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
}
```

### 5.2 世界书卡片包

```dart
class LorebookCardPackage extends RFWPackage {
  LorebookCardPackage()
      : super(
          name: 'LorebookCard',
          version: '1.0.0',
          type: 'lorebookCard',
          schema: {
            'title': 'string',
            'content': 'string',
            'tags': 'array?',
          },
          builder: (data) {
            final title = data['title'] ?? '无标题';
            final content = data['content'] ?? '';
            final tags = data['tags'] as List<String>? ?? [];

            return Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(content),
                  if (tags.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: tags
                          .map((tag) => Chip(
                                label: Text(tag),
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            );
          },
        );
}
```

---

## 6. 性能优化 (Performance Optimization)

### 6.1 组件缓存

```dart
class RFWComponentCache {
  final Map<String, Widget> _cache = {};

  Widget get(String key, Widget Function() builder) {
    return _cache.putIfAbsent(key, builder);
  }

  void clear() {
    _cache.clear();
  }

  void remove(String key) {
    _cache.remove(key);
  }
}
```

### 6.2 懒加载

```dart
class LazyRFWRenderer extends StatefulWidget {
  final RFWPackage package;
  final Map<String, dynamic> data;

  @override
  _LazyRFWRendererState createState() => _LazyRFWRendererState();
}

class _LazyRFWRendererState extends State<LazyRFWRenderer> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    // 延迟加载
    Future.delayed(Duration(milliseconds: 100), () {
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
      return SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return RFWSlotRenderer(
      package: widget.package,
      data: widget.data,
    );
  }
}
```

---

## 7. 迁移对照表 (Migration Reference)

| 旧 UI 概念 | 新 UI 组件 | 变化 |
| :--- | :--- | :--- |
| 内联组件 | `RFWPackage` | HTML → Dart Widget |
| 组件加载 | `RFWLoader` | 无 → 包加载器 |
| 组件渲染 | `RFWSlotRenderer` | innerHTML → Widget |

---

**关联文档**:
- [`01-design-tokens.md`](./01-design-tokens.md) - 设计令牌系统
- [`02-color-theme.md`](./02-color-theme.md) - 颜色与主题系统
- [`03-typography.md`](./03-typography.md) - 排版系统
- [`04-responsive-layout.md`](./04-responsive-layout.md) - 响应式布局
- [`10-hybrid-sdui.md`](./10-hybrid-sdui.md) - Hybrid SDUI 引擎
- [`12-webview-fallback.md`](./12-webview-fallback.md) - WebView 兜底
