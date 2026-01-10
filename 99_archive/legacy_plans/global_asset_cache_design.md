# 全局资源缓存设计 (Global Asset Cache Design)

**版本**: 1.0.0
**日期**: 2026-01-10
**状态**: Draft
**作者**: 资深系统架构师 (Architect Mode)
**关联文档**: `00_active_specs/core/infrastructure-layer.md`

---

## 1. 核心理念：藏宝阁 (The Vault)

为了解决多媒体资源（图片、音频、字体）在不同 **织谱 (Patterns)** 和 **会话 (Sessions)** 之间的高频复用问题，以及应对网络下载的不确定性，我们引入 **"藏宝阁 (The Vault)"** —— 一个基于内容寻址 (Content-Addressable) 的全局资源缓存系统。

### 1.1 设计原则

1.  **只存一份 (Single Instance Storage)**: 无论有多少个角色卡引用了同一张背景图，磁盘上只物理存储一份。
2.  **引用透明 (Referential Transparency)**: 上层业务通过统一的 `asset://` URI 访问资源，无需关心资源是在包内、缓存中还是网络上。
3.  **惰性加载 (Lazy Loading)**: 资源仅在被实际请求（渲染）时才进行下载或加载。

---

## 2. 架构设计 (Architecture)

全局资源缓存作为一个子系统，位于 **Infrastructure Layer**，向下管理文件系统，向上为 Presentation Layer 提供服务。

```mermaid
graph TD
    subgraph "Application Layer"
        UI[Presentation Layer]
        PatternA[Pattern A (L2)]
        PatternB[Pattern B (L2)]
    end

    subgraph "Infrastructure Layer: Asset Resolver"
        Resolver[Asset Resolver Service]
        Index[Cache Index (SQLite/KV)]
        Downloader[Download Manager]
    end

    subgraph "File System (The Vault)"
        CacheDir[global_cache/blobs/]
        File1[a1b2c3... .png]
        File2[f9e8d7... .mp3]
    end

    UI -->|Request URL| Resolver
    PatternA -->|Ref URL| Resolver
    PatternB -->|Ref Same URL| Resolver

    Resolver -->|Check| Index
    Index -->|Hit| CacheDir
    Index -->|Miss| Downloader
    Downloader -->|Save & Hash| CacheDir
    Downloader -->|Update| Index
```

### 2.1 物理存储结构

*   **根目录**: `app_data/cache/global_assets/`
*   **Blob 存储**: `blobs/`
    *   文件名: `<SHA-256 Hash>` (无扩展名，或作为前缀)
    *   示例: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
*   **索引数据库**: `asset_index.db` (SQLite)

---

## 3. 数据库 Schema (asset_index.db)

用于维护 `Source URL` 与 `Local Blob` 之间的映射关系。

### 3.1 `assets` 表

| 字段 | 类型 | 说明 |
| :--- | :--- | :--- |
| `url_hash` | TEXT (PK) | 原始 URL 的哈希 (便于快速查找) |
| `original_url` | TEXT | 原始网络 URL (用于调试和重新下载) |
| `content_hash` | TEXT | 文件内容的 SHA-256 (指向 blobs/) |
| `mime_type` | TEXT | 资源类型 (image/png, audio/mpeg) |
| `size_bytes` | INTEGER | 文件大小 |
| `last_accessed` | INTEGER | 最后访问时间戳 (用于 LRU 清理) |
| `etag` | TEXT | HTTP ETag (用于校验更新) |

### 3.2 `asset_refs` 表 (可选，用于 GC)

如果需要精确的垃圾回收，可以维护引用计数。

| 字段 | 类型 | 说明 |
| :--- | :--- | :--- |
| `id` | INTEGER (PK) | 自增 ID |
| `content_hash` | TEXT | 关联的资源 |
| `owner_type` | TEXT | 引用者类型 (pattern, session) |
| `owner_id` | TEXT | 引用者 ID |

---

## 4. 关键工作流 (Workflows)

### 4.1 资源解析与下载 (Resolve & Download)

当 UI 组件请求加载一个图片 URL 时：

1.  **拦截**: `AssetResolver` 拦截请求。
2.  **查表**: 根据 URL 查询 `assets` 表。
3.  **命中 (Hit)**:
    *   获取 `content_hash`。
    *   检查 `blobs/{content_hash}` 文件是否存在。
    *   如果存在，更新 `last_accessed`，返回本地文件流。
4.  **未命中 (Miss) / 文件丢失**:
    *   启动 `DownloadManager` 下载任务。
    *   下载到临时文件。
    *   计算文件 SHA-256 (`content_hash`)。
    *   **去重**: 检查 `blobs/` 下是否已有同名文件。
        *   若有，直接使用现有文件。
        *   若无，将临时文件移动到 `blobs/`。
    *   写入/更新 `assets` 表。
    *   返回本地文件流。

### 4.2 引用机制 (Referencing)

在 L3 Session 数据中，建议 **始终存储原始 URL** 或 **Asset URI**。

*   **Asset URI 格式**: `asset://remote/{url_base64}` (可选，用于显式标识这是远程资源)
*   **普通 URL**: `https://example.com/image.png` (由 Resolver 自动处理)

这保证了数据的 **可移植性**。如果用户将存档迁移到新设备（只有 DB，没有 Cache），系统可以根据 URL 重新下载资源，而不会出现资源丢失。

### 4.3 缓存清理 (Eviction & GC)

由于多媒体文件体积大，必须实施严格的清理策略。

1.  **LRU (Least Recently Used)**:
    *   设置缓存上限 (e.g., 2GB)。
    *   当空间不足时，查询 `assets` 表，按 `last_accessed` 升序删除最久未使用的记录和对应的 Blob 文件。
2.  **孤儿清理 (Orphan Cleanup)**:
    *   (如果实现了引用计数) 定期扫描 `asset_refs`，删除引用计数为 0 的 Blob。

---

## 5. 跨织谱共享示例

假设用户导入了两个不同的 Pattern，它们都使用了同一张网路图片 `http://img.com/hero.png`：

1.  **导入 Pattern A**:
    *   系统解析 URL，下载图片，计算 Hash 为 `H1`。
    *   存储 `blobs/H1`。
    *   索引: `http://img.com/hero.png` -> `H1`。
2.  **导入 Pattern B**:
    *   系统解析 URL，查询索引发现已存在。
    *   直接复用 `blobs/H1`。
    *   **磁盘占用**: 仅 1 份文件大小。

---

## 6. 安全性考量

1.  **路径遍历防护**: 严格校验 Hash 值格式，防止恶意构造的文件名包含 `../`。
2.  **文件类型校验**: 下载后必须校验 Magic Bytes，确保扩展名与实际内容匹配，防止伪装的恶意脚本。
