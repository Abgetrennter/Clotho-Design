# 依赖注入与状态管理规范 (Dependency Injection & State Management)

**版本**: 1.0.0  
**日期**: 2026-02-12  
**状态**: Active  
**所属模块**: Infrastructure  

---

## 1. 概述 (Overview)

Clotho 项目采用 **GetIt** 和 **Riverpod** 的混合架构来管理依赖注入（DI）和状态管理。这种混合策略旨在平衡**核心架构的整洁性**与**UI开发的便捷性**，确保各层职责分明，降低长期维护复杂度。

### 1.1 核心哲学
*   **物理隔离**：核心逻辑层（Jacquard/Mnemosyne）不应依赖 UI 框架或特定的状态管理库。
*   **各司其职**：使用最适合该层特性的工具。
    *   **GetIt**：负责管理**静态**、**单例**、**纯逻辑**的服务。
    *   **Riverpod**：负责管理**动态**、**生命周期敏感**、**UI相关**的状态。

---

## 2. 技术分层 (Technical Layering)

| 层级 (Layer) | 主要技术 (Tech) | 职责 (Responsibility) | 典型组件 (Examples) |
| :--- | :--- | :--- | :--- |
| **Presentation (L3)** | **Riverpod** | UI 状态绑定、视图逻辑、局部刷新 | `ChatScreen`, `SettingsPanel`, `SessionState` |
| **Bridge (L2)** | **Providers** | 桥接层，将 GetIt 服务暴露给 Riverpod | `databaseProvider`, `pipelineProvider` |
| **Core (L1)** | **GetIt** | 业务逻辑、编排引擎、数据存取 | `JacquardPipeline`, `MnemosyneEngine`, `Scheduler` |
| **Infrastructure (L0)** | **GetIt** | 基础服务、单例工具 | `SqliteService`, `HttpClient`, `FileSystem` |

---

## 3. 实施规范 (Implementation Guidelines)

为了避免架构混乱，开发过程中必须严格遵守以下 **"三条铁律"**：

### 规则 1：UI 层严禁触碰 GetIt
**Presentation Layer** 的 Widget 和 Controller **禁止**直接调用 `GetIt.I<T>()`。
*   ❌ **错误**: `final db = GetIt.I<DatabaseService>();`
*   ✅ **正确**: `final db = ref.watch(databaseServiceProvider);`
*   **理由**: 保持 UI 层的响应式特性，便于测试时通过 `ProviderScope` 进行 Override。

### 规则 2：核心层严禁触碰 Riverpod
**Jacquard** 和 **Mnemosyne** 的核心类 **禁止** 导入 `flutter_riverpod` 包，也禁止在构造函数中传递 `Ref`。
*   ❌ **错误**: `class Pipeline { Pipeline(this.ref); ... }`
*   ✅ **正确**: `class Pipeline { Pipeline(this.database); ... }`
*   **理由**: 保证核心算法是纯净的 Dart 代码，甚至可以在非 Flutter 环境（如 CLI、Isolate）中运行。

### 规则 3：单向桥接
仅在专门的 **Bridge 文件** (如 `providers.dart`) 中，定义 Riverpod Provider 来读取 GetIt 中的服务。
*   **模式**: `final myServiceProvider = Provider((ref) => GetIt.I<MyService>());`

---

## 4. 详细设计 (Detailed Design)

### 4.1 Infrastructure & Core (GetIt)
我们建议配合 `injectable` 代码生成库使用，以简化注册过程。

```dart
// 示例：定义一个纯 Dart 服务
@singleton // 使用 injectable 注解
class MnemosyneService {
  final SqliteDatabase _db;

  // 依赖通过构造函数注入
  MnemosyneService(this._db);

  Future<void> saveMemory(Memory memory) async {
    // ...
  }
}
```

### 4.2 The Bridge (Riverpod Providers)
在每一层的边界处（通常是 `lib/providers/` 或模块入口），定义桥接 Provider。

```dart
// lib/providers/core_providers.dart

// 1. 定义桥接 Provider
final mnemosyneProvider = Provider<MnemosyneService>((ref) {
  // 从 GetIt 获取单例实例
  return GetIt.I<MnemosyneService>();
});

// 2. 定义派生 Provider (可选)
final recentMemoriesProvider = FutureProvider<List<Memory>>((ref) async {
  // 通过 Ref 获取服务，保持响应式链条
  final mnemosyne = ref.watch(mnemosyneProvider);
  return mnemosyne.getRecentMemories();
});
```

### 4.3 Presentation (Riverpod)
在 UI 中，只使用 `ref` 进行交互。

```dart
class ChatScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 watch 监听数据变化
    final memoriesAsync = ref.watch(recentMemoriesProvider);

    return memoriesAsync.when(
      data: (memories) => ListView(children: ...),
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

---

## 5. 测试策略 (Testing Strategy)

混合架构极大地简化了单元测试和 Widget 测试：

*   **核心逻辑测试**: 由于 Core 类不依赖 Riverpod，直接实例化并 Mock 构造函数参数即可。
    ```dart
    test('Mnemosyne logic', () {
      final mockDb = MockDatabase();
      final service = MnemosyneService(mockDb); // 直接注入 Mock
      // ...
    });
    ```

*   **UI 测试**: 利用 Riverpod 的 `overrides` 特性替换底层服务。
    ```dart
    testWidgets('ChatScreen renders memories', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // 替换掉桥接 Provider，注入 Mock 服务
            mnemosyneProvider.overrideWithValue(MockMnemosyneService()),
          ],
          child: ChatScreen(),
        ),
      );
      // ...
    });
    ```
