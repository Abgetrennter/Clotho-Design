# Mnemosyne 混合资源管理规范 (Hybrid Resource Management Specification)

**版本**: 1.0.0
**日期**: 2026-01-10
**状态**: Active
**作者**: 资深系统架构师 (Architect Mode)
**关联文档**:
- `sqlite-architecture.md` (L3 存储)
- `../core/infrastructure-layer.md` (资源服务)
- `../workflows/character-import-migration.md` (导入逻辑)

---

## 1. 核心理念与架构 (Core Philosophy & Architecture)

Mnemosyne 的存储架构遵循 **“动静分离，逻辑聚合 (Separate Physically, Aggregate Logically)”** 的核心原则。我们严格区分“只读资产”与“读写状态”，以解决长期运行导致的数据库膨胀和资源复用问题。

### 1.1 三大存储支柱 (Three Pillars of Storage)

系统将数据存储划分为三个物理隔离的区域，以满足不同的生命周期和管理需求：

1.  **Library (L2 Static)**: 存放 **织谱 (Patterns)**。
    *   **隐喻**: “游戏卡带”或“安装目录”。
    *   **特性**: 只读、可替换、版本化、易于分享。
    *   **内容**: 角色卡元数据、默认立绘、背景音乐、世界观设定 (Lorebook)。
2.  **Session Data (L3 Dynamic)**: 存放 **会话 (Sessions/Tapestries)**。
    *   **隐喻**: “游戏存档”。
    *   **特性**: 读写频繁、私有、依赖 L2 但不包含 L2。
    *   **内容**: 聊天记录、变量状态 (State Tree)、用户上传的图片 (Diff)、Schema 快照。
3.  **The Vault (Global Cache)**: 存放 **共享资源 (Blobs)**。
    *   **隐喻**: “系统动态链接库”或“Steam 公共资源库”。
    *   **特性**: 内容寻址 (Content-Addressable)、去重、惰性加载。
    *   **内容**: 网络图片缓存、跨 Pattern 复用的大型多媒体文件。

### 1.2 架构全景图

```mermaid
graph TD
    subgraph "Application Layer"
        UI[Presentation Layer]
        L3Session[Session Context (L3)]
    end

    subgraph "Infrastructure Layer: Resource Manager"
        Resolver[Asset Resolver]
        Index[Vault Index (SQLite)]
    end

    subgraph "File System"
        direction TB
        
        subgraph "L2: Library (Read-Only)"
            PatternA[Pattern A (v1.0)]
            PatternB[Pattern B (v2.0)]
        end

        subgraph "L3: User Data (Read-Write)"
            SessionDB[session.db (SQLite)]
            SessionAssets[session_assets/]
        end

        subgraph "The Vault (Global Cache)"
            BlobStore[blobs/]
            CacheIndex[index.db]
        end
    end

    UI -->|Request asset://| Resolver
    L3Session -->|Refers| PatternA
    
    Resolver -->|1. Check| PatternA
    Resolver -->|2. Check| SessionAssets
    Resolver -->|3. Check| BlobStore
    
    BlobStore -.->|Dedup| PatternA
    BlobStore -.->|Dedup| PatternB
```

---

## 2. 统一引用协议 (URI Scheme)

为了实现物理分离但逻辑透明，系统内部（数据库、内存状态）统一使用 `asset://` 协议引用资源。UI 层无需关心资源实际在何处。

**格式**: `asset://{scope}/{identifier}/{path}`

| Scope | Identifier | Path | 说明 | 物理路径映射示例 |
| :--- | :--- | :--- | :--- | :--- |
| **pattern** | `{uuid}` / `current` | `assets/bgm.mp3` | 引用 L2 织谱包内的资源 | `library/{uuid}/assets/bgm.mp3` |
| **session** | `{uuid}` / `current` | `uploads/img1.png` | 引用 L3 会话私有的资源 | `userdata/sessions/{uuid}/assets/uploads/img1.png` |
| **vault** | `N/A` | `{hash}` | 引用全局去重库的资源 | `cache/vault/blobs/{hash}` |
| **remote** | `N/A` | `{base64_url}` | 引用远程资源 (自动缓存到 Vault) | `cache/vault/blobs/{hash_of_url}` |
| **system** | `N/A` | `icons/user.png` | 引用 App 内置资源 | `FlutterAsset('assets/icons/user.png')` |

---

## 3. L2: 织谱库设计 (Library Structure)

L2 层的资源被封装为 **Pattern (织谱)**。它是 Mnemosyne 的基本分发单位。

### 3.1 目录结构
建议路径: `app_data/library/`

```text
/app_data/library/
  └── {pattern_uuid}/         # 织谱根目录
      ├── manifest.yaml       # [元数据] 名称, 版本, 作者, 依赖
      ├── pattern.yaml        # [核心定义] Initial State, Prompts, Scripts
      ├── assets/             # [多媒体] 随包分发的资源
      │   ├── default_avatar.png
      │   └── theme.mp3
      ├── lorebook/           # [世界书] 静态源文件
      │   └── main_world.yaml
      └── schemas/            # [可选] 复杂的独立 Schema 定义
```

### 3.2 关键文件职责
*   **`manifest.yaml`**: 定义包的身份。如果资源太大（如 100MB 的背景音乐包），可以在此声明引用远程资源，安装时由管理器下载到 Vault。
*   **`pattern.yaml`**: 定义 `initial_state`。引用的资源通常使用相对路径（解析为 `asset://pattern/current/...`）。

---

## 4. The Vault: 全局资源缓存 (Global Asset Cache)

为了解决多媒体资源在不同织谱和会话之间的高频复用问题，以及网络下载的不确定性，引入 "藏宝阁 (The Vault)"。

### 4.1 设计原则
1.  **只存一份 (Single Instance Storage)**: 无论多少个角色卡引用同一张图，磁盘上只存一份。
2.  **惰性加载 (Lazy Loading)**: 仅在渲染时下载/加载。
3.  **内容寻址**: 文件名即内容的 SHA-256 哈希。

### 4.2 物理结构
建议路径: `app_data/cache/vault/`

*   `blobs/`: 存放实际文件，无扩展名（或作为前缀）。
    *   例如: `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`
*   `index.db`: SQLite 索引，维护 URL -> Hash 的映射。

### 4.3 索引 Schema (`asset_index.db`)

```sql
CREATE TABLE assets (
    url_hash TEXT PRIMARY KEY,      -- 原始 URL 的 Hash
    original_url TEXT,              -- 原始 URL (用于重新下载)
    content_hash TEXT,              -- 文件内容的 SHA-256 (指向 blobs/)
    mime_type TEXT,
    size_bytes INTEGER,
    last_accessed INTEGER,          -- 用于手动清理分析
    etag TEXT                       -- HTTP 缓存校验
);
```

### 4.4 垃圾回收策略 (Garbage Collection)
由于 Vault 存储的是全局共享资源，数据量相对可控。为了避免误删仍在使用中的资源（例如某个极少打开的历史会话引用了该资源），系统 **不自动执行** 基于 LRU 的自动删除。

*   **策略**: **手动清理 (Manual GC)**。
*   **机制**: 用户可以在设置中点击“清理缓存”，此时系统会：
    1.  扫描所有本地 Sessions 和 Library Patterns。
    2.  构建“活跃 Hash 集合” (Active Hash Set)。
    3.  对比 Vault 索引，删除不在集合中的 Blobs。

### 4.5 解析流程 (Resolve Flow)
当 UI 请求 `asset://remote/{base64_url}` 或普通 HTTP URL 时：
1.  **Check**: 查询 `index.db`。
2.  **Hit**: 如果存在且文件完整 -> 返回 `blobs/{content_hash}` 流。
3.  **Miss**:
    *   下载文件到临时区。
    *   计算 SHA-256。
    *   移动到 `blobs/` (如果同名文件已存在则直接删除临时文件)。
    *   更新 `index.db`。
    *   返回流。

---

## 5. L3: 会话数据存储 (Session Storage)

L3 层专注于存储“差异”和“状态”。

### 5.1 物理结构
建议路径: `app_data/userdata/sessions/`

```text
/app_data/userdata/sessions/
  └── {session_uuid}/
      ├── session.db          # [核心] SQLite 数据库
      └── assets/             # [私有资源] 用户上传的图片等
          └── 20260110_upload.png
```

### 5.2 数据库与资源的关系
*   **严禁**将图片、音频存入 `session.db` 的 BLOB 字段。
*   数据库中仅存储 URI，例如: `asset://session/current/assets/20260110_upload.png`。

### 5.3 引用 L2
L3 会话不包含 L2 数据，而是包含一个 **引用指针** (在 `session.db` 的元数据表中)。
*   `pattern_ref`: `{uuid}`
*   `pattern_version`: `1.0.0`

当加载会话时，系统根据指针去 `app_data/library/` 寻找对应的 L2 包。

### 5.4 资源丢失处理 (Dangling References)
如果用户删除了 L2 Pattern，或者 L2 更新后移除了某些资源，导致 `asset://pattern/...` 解析失败：
1.  **UI 表现**: 显示标准占位符（如 "Broken Image" 图标），点击可查看原始 URI。
2.  **修复机制**: 提供 "Asset Repair Wizard"，允许用户重新指定 Pattern 路径，或从 Vault 中查找历史缓存（如果曾经缓存过）。

### 5.5 导出与导入策略 (Export/Import)
为了平衡便携性和完整性，系统支持两种导出模式：

1.  **轻量导出 (Reference Only)**:
    *   **格式**: `.ctp` (Clotho Tapestry Protocol) - 仅包含 `session.db` 和 `session_assets/`。
    *   **场景**: 在同一设备备份，或对方已安装相同 L2 Pattern。
    *   **大小**: 小 (KB ~ MB 级)。

2.  **完整导出 (Self-Contained Bundle)**:
    *   **格式**: `.ctpb` (Clotho Tapestry Bundle) - ZIP 压缩包。
    *   **结构**: 包含 `.ctp` + `dependencies/` (L2 Pattern 的精简副本)。
    *   **场景**: 跨设备分享，确保“开箱即用”。
    *   **导入逻辑**: 导入时，如果本地缺失该 L2 Pattern，则自动将 `dependencies/` 下的内容安装到临时 Library 或提示用户安装。

---

## 6. 总结 (Summary)

| 场景 | 推荐存储位置 | 推荐 URI 协议 | 物理生命周期 |
| :--- | :--- | :--- | :--- |
| **角色立绘 (开发者提供)** | L2 Library (`assets/`) | `asset://pattern/...` | 随 Pattern 安装/卸载 |
| **背景音乐 (大文件/通用)** | The Vault | `asset://vault/...` 或 HTTP | 手动 GC 清理 |
| **用户发送的图片** | L3 Session (`assets/`) | `asset://session/...` | 随会话删除 |
| **App 内置图标** | App Binary | `asset://system/...` | 随 App 更新 |

本规范确保了 Mnemosyne 的存储结构既能灵活应对复杂的多对多引用（如群聊），又能保持数据的整洁和安全。
