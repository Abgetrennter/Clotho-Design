# 文件系统抽象规范 (File System Abstraction Specification)

**版本**: 1.0.0
**日期**: 2026-02-12
**状态**: Active
**关联文档**:
- `../mnemosyne/hybrid-resource-management.md` (资源管理)
- `dependency-injection.md` (依赖注入)

---

## 1. 概述 (Overview)

本规范定义了 Clotho 项目的基础文件系统抽象层 (File System Abstraction Layer)。旨在屏蔽不同操作系统（Windows, Android, iOS）之间的路径差异，提供统一、安全、语义化的文件访问接口。

该模块作为 `Infrastructure Layer` 的一部分，为 `Mnemosyne` (数据引擎) 和 `Asset Resolver` (资源解析器) 提供底层 I/O 支持。

## 2. 设计原则 (Design Principles)

1.  **路径无关性 (Path Agnosticism)**: 上层业务逻辑不应硬编码绝对路径（如 `C:\Users` 或 `/data/user`），必须使用语义化别名（如 `app_data://`）。
2.  **沙盒安全 (Sandbox Safety)**: 严格限制文件访问在应用授权目录内，防止路径遍历攻击 (Path Traversal)。
3.  **异步优先 (Async First)**: 所有 I/O 操作必须是异步的 (`Future`/`Stream`)，严禁阻塞 UI 线程。
4.  **跨平台一致性 (Cross-Platform Consistency)**: 确保在桌面端和移动端具有一致的行为预期。

---

## 3. 路径映射与别名 (Path Mapping & Aliases)

为了统一访问，系统定义了以下核心根目录别名。底层实现（如基于 `path_provider`）需根据运行平台将其解析为物理路径。

### 3.1 核心别名表

| 别名 (Alias) | 语义 (Semantics) | Windows 物理路径示例 | Android 物理路径示例 | iOS 物理路径示例 | 清理策略 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`app_data`** | 应用核心数据，用户不可直接见，随应用卸载删除 | `%APPDATA%\Clotho` | `/data/user/0/com.clotho/files` | `Documents/` | 永不自动清理 |
| **`cache`** | 临时缓存，系统可能回收 | `%LOCALAPPDATA%\Clotho\Cache` | `/data/user/0/com.clotho/cache` | `Library/Caches/` | OS 可自动清理 |
| **`temp`** | 会话级临时文件 | `%TEMP%\Clotho` | `/data/user/0/com.clotho/cache/tmp` | `tmp/` | App 重启时清理 |
| **`documents`** | 用户可见文档，用于导出/导入 | `%USERPROFILE%\Documents\Clotho` | `/storage/emulated/0/Documents/Clotho` | `Documents/Public/` | 用户手动管理 |

### 3.2 目录结构规范 (Directory Structure)

在 `app_data` 根目录下，Clotho 强制执行以下子目录结构（对应 Mnemosyne 规范）：

```text
app_data/
├── library/                 # L2: 静态资源库 (Patterns)
│   ├── {uuid}/              # 特定 Pattern 包
│   └── ...
├── userdata/                # L3: 用户数据
│   ├── sessions/            # 会话存档 (Tapestries)
│   └── settings/            # 全局配置 (Preferences)
└── vault/                   # Global Cache: 共享资源库
    ├── blobs/               # 内容寻址文件存储
    └── index.db             # 资源索引数据库
```

---

## 4. 接口定义 (Interface Definition)

在 Dart 代码层面，通过依赖注入 (`GetIt`) 提供 `FileSystemService` 抽象类。

### 4.1 核心接口 (Dart)

```dart
/// 文件系统服务抽象接口
abstract class FileSystemService {
  /// 初始化服务（如创建基础目录结构）
  Future<void> initialize();

  /// 获取指定类型的根目录物理路径
  /// [type]: appData, cache, temp, documents
  Future<String> getDirectoryPath(DirectoryType type);

  /// 将语义化路径解析为物理路径
  /// 输入: "app_data://library/abc/manifest.yaml"
  /// 输出: "C:\Users\...\Clotho\library\abc\manifest.yaml"
  Future<String> resolvePath(String uri);

  // --- 文件操作 (File Operations) ---

  /// 检查文件或目录是否存在
  Future<bool> exists(String uri);

  /// 读取文本文件
  Future<String> readString(String uri);

  /// 写入文本文件 (默认覆盖)
  Future<void> writeString(String uri, String content, {bool append = false});

  /// 读取二进制文件
  Future<List<int>> readBytes(String uri);

  /// 写入二进制文件
  Future<void> writeBytes(String uri, List<int> bytes);

  /// 删除文件
  Future<void> deleteFile(String uri);

  // --- 目录操作 (Directory Operations) ---

  /// 递归创建目录
  Future<void> createDirectory(String uri);

  /// 列出目录内容
  /// [recursive]: 是否递归
  /// 返回: 文件 URI 列表
  Future<List<String>> listFiles(String uri, {bool recursive = false});

  /// 删除目录（及其内容）
  Future<void> deleteDirectory(String uri);

  // --- 流式操作 (Streaming Operations) ---
  
  /// 打开文件读取流 (用于大文件/媒体)
  Stream<List<int>> openReadStream(String uri);

  /// 打开文件写入流
  Sink<List<int>> openWriteStream(String uri);
}

enum DirectoryType {
  appData,
  cache,
  temp,
  documents
}
```

### 4.2 错误处理 (Error Handling)

所有方法在失败时应抛出统一的 `FileSystemException`：

*   `FileSystemException.notFound`: 文件或路径不存在。
*   `FileSystemException.permissionDenied`: 无权访问该路径。
*   `FileSystemException.invalidPath`: 路径格式非法或试图越权访问（如 `../`）。
*   `FileSystemException.ioError`: 底层 I/O 错误（磁盘满、被占用）。

---

## 5. 平台特定适配 (Platform-Specific Adaptation)

### 5.1 Windows
*   **库**: `path_provider_windows`
*   **注意事项**:
    *   必须处理长路径问题（路径 > 260 字符），建议内部统一添加 `\\?\` 前缀或确保 Windows Registry 开启长路径支持。
    *   文件占用锁（File Locking）较严格，写入前需确保流已关闭。

### 5.2 Android
*   **库**: `path_provider_android`
*   **权限**:
    *   内部存储 (`app_data`, `cache`) 无需额外权限。
    *   外部存储 (`documents`) 需申请 `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` (Android 10 以下) 或使用 Scoped Storage API。
    *   建议尽量避免使用 `documents` 存储核心数据，仅用于用户明确的导出操作。

### 5.3 iOS
*   **库**: `path_provider_ios`
*   **注意事项**:
    *   `Documents` 目录下的文件会被 iCloud 自动备份。对于 `library` (可重新下载) 和 `vault` (缓存)，应设置 `NSURLIsExcludedFromBackupKey` 属性，防止占用用户 iCloud 空间。
    *   严格的沙盒限制，无法访问应用外部文件。

---

## 6. 与 Asset Protocol 的集成

`FileSystemService` 是 `AssetResolver` 的下游依赖。

*   **AssetResolver**: 负责解析 `asset://pattern/{id}/image.png` 这种高层协议。
*   **FileSystemService**: 负责将解析后的 `app_data://library/{id}/assets/image.png` 转换为物理路径并执行 I/O。

### 6.1 解析流程示例

1.  UI 请求: `asset://pattern/uuid-123/bg.png`
2.  **AssetResolver**:
    *   识别 Scope 为 `pattern`。
    *   查找 `uuid-123` 对应的安装路径。
    *   生成内部 URI: `app_data://library/uuid-123/assets/bg.png`。
3.  **FileSystemService**:
    *   调用 `resolvePath("app_data://library/uuid-123/assets/bg.png")`。
    *   映射 `app_data` -> `/data/user/.../files`.
    *   返回物理路径: `/data/user/.../files/library/uuid-123/assets/bg.png`。
4.  **FileSystemService**:
    *   调用 `readBytes` 读取该物理路径。
