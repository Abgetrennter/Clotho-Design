# 静态资源存储与引用设计 (Static Resource Storage & Referencing)

**版本**: 1.0.0
**日期**: 2026-01-10
**状态**: Draft
**关联文档**: 
- `00_active_specs/mnemosyne/sqlite-architecture.md` (L3 存储)
- `03_actvie_craft/global_asset_cache_design.md` (全局缓存)
- `00_active_specs/workflows/character-import-migration.md` (导入源)

---

## 1. 核心理念：动静分离 (Separation of Static & Dynamic)

Mnemosyne 的存储架构遵循严格的 **动静分离** 原则，以平衡性能、可维护性和存储效率。

*   **静态 (L2 Static)**: 定义世界的蓝图。包括角色设定、世界观、图片、音乐、UI 样式。这些资源通常是只读的（或作为版本化包更新），不应存入 SQLite。
*   **动态 (L3 Dynamic)**: 定义会话的状态。包括对话历史、变量变更、事件记录。这些数据存入 SQLite (`session.db`) 以支持 ACID 事务和高效查询。

---

## 2. 存储架构全景 (Storage Panorama)

```mermaid
graph TD
    subgraph "L3: Runtime (Session Storage)"
        SessionDB[session.db (SQLite)]
        SessionDB -->|Refers to| StaticRef[Asset URI / UUID]
        StateSnap[State Snapshots (JSON)]
    end

    subgraph "L2: Static Library (Pattern Storage)"
        Library[Library Directory]
        
        Package[Pattern Package (Folder/Zip)]
        Library --> Package
        
        Manifest[manifest.yaml]
        PatternDef[pattern.yaml]
        LorebookDir[lorebook/]
        AssetDir[assets/]
        
        Package --> Manifest
        Package --> PatternDef
        Package --> LorebookDir
        Package --> AssetDir
    end

    subgraph "Assets: Multimedia"
        AssetDir --> Img[avatar.png]
        AssetDir --> Audio[bgm.mp3]
        AssetDir --> Font[font.ttf]
    end

    subgraph "Infrastructure: Global Cache"
        Vault[The Vault (Global Asset Cache)]
    end

    SessionDB -.->|Hydrates| PatternDef
    SessionDB -.->|Indexes| LorebookDir
    PatternDef -.->|Refers to| Img
    AssetDir -.->|Dedup| Vault
```

---

## 3. L2 层静态资源：织谱包 (Pattern Package)

L2 层的资源（角色卡、世界书、预设规则）被封装为 **Pattern (织谱)**。它是 Mnemosyne 的基本分发单位。

### 3.1 物理目录结构

建议在应用数据目录 (`App Data`) 下建立 `library/`，每个织谱一个独立目录：

```text
/app_data/library/
  └── {uuid_or_slug}/         # 织谱根目录
      ├── manifest.yaml       # [元数据] 名称, 版本, 作者, 依赖, 协议版本
      ├── pattern.yaml        # [核心定义] Initial VWD State, Prompts, Scripts
      ├── assets/             # [多媒体] 图片, 音频, 字体
      │   ├── default_avatar.png
      │   ├── theme.mp3
      │   └── custom_font.ttf
      ├── lorebook/           # [世界书] 静态源文件 (YAML/Markdown)
      │   ├── main_world.yaml
      │   └── magic_system.yaml
      └── schemas/            # [可选] 复杂的独立 Schema 定义
          └── rpg_stats.json
```

### 3.2 关键文件职责

*   **`manifest.yaml`**: 包的身份证。定义了包的 ID、版本以及引用的外部资源（如全局缓存的资源 Hash）。
*   **`pattern.yaml`**: 对应 `ProjectedCharacter` 的静态底板。它定义了 `initial_state`（初始状态树），是会话启动时的“种子”。
*   **`lorebook/*.yaml`**: 静态的世界书条目。运行时，Mnemosyne 会读取这些文件构建索引（Vector Index 或 Keyword Index），但在物理上保持文件形式以便于人工编辑和 Git 管理。

---

## 4. 多媒体资源管理 (Multimedia Management)

为了避免 SQLite 数据库体积膨胀（Mobile/Desktop App 最佳实践），**严禁**将图片、音频、字体等二进制数据存入 SQLite BLOB。

### 4.1 存储策略

1.  **包内资源 (Package Assets)**: 存放在 L2 包的 `assets/` 目录下。随包的安装/卸载而生命周期流转。
2.  **用户资源 (User Assets)**: 用户在对话中发送的图片，应存放在 `session_data/{session_id}/assets/` 目录下。
3.  **全局资源 (Global Assets)**: 通过 `The Vault` (见 `global_asset_cache_design.md`) 管理的去重资源。

### 4.2 统一引用协议 (URI Scheme)

在 SQLite 数据库（如 `Message` 内容或 `State` 变量）中，使用统一的 URI 协议引用资源，实现 **引用透明性 (Referential Transparency)**。

**协议格式**: `asset://{scope}/{path}`

| Scope | 说明 | 示例 URI | 物理路径解析 (伪代码) |
| :--- | :--- | :--- | :--- |
| **pattern** | 当前活跃织谱 | `asset://pattern/assets/bgm.mp3` | `$LIBRARY_DIR/$CURRENT_PATTERN_ID/assets/bgm.mp3` |
| **{uuid}** | 指定 ID 的织谱 | `asset://uuid-1234/assets/avatar.png` | `$LIBRARY_DIR/uuid-1234/assets/avatar.png` |
| **session** | 当前会话私有 | `asset://session/uploads/img_01.jpg` | `$SESSION_DIR/$CURRENT_SESSION_ID/assets/img_01.jpg` |
| **system** | App 内置资源 | `asset://system/icons/potion.png` | `FlutterAsset('assets/icons/potion.png')` |
| **remote** | 远程资源 (Cached) | `asset://remote/{base64_url}` | `AssetResolver.resolve(url)` -> `The Vault` |

### 4.3 运行时解析 (Runtime Resolution)

Presentation Layer (UI) 通过 `AssetResolver` 服务将 URI 转换为 Flutter 可用的 `ImageProvider` 或文件路径。

```dart
// 伪代码示例
class AssetResolver {
  Future<File> resolve(String uri) async {
    if (uri.startsWith('asset://pattern/')) {
       // 获取当前 Pattern ID，拼接路径
       return File(path.join(libraryDir, currentPatternId, uri.path));
    }
    // ... 处理其他协议
  }
}
```

---

## 5. Schema 的寄生存储 (Parasitic Schema Storage)

在 Mnemosyne 中，Schema 不是独立的数据库表结构，而是 **VWD (Value With Description)** 数据模型的一部分，采用“数据即定义 (Self-describing Data)”的策略。

### 5.1 静态定义 (Static Definition in L2)

在 `pattern.yaml` 中，通过 `$meta` 字段定义初始 Schema。这是“出厂设置”。

```yaml
# pattern.yaml
initial_state:
  character:
    inventory:
      $meta:
        description: "背包系统"
        template:  # 定义列表项的默认 Schema
          name: "Unknown"
          count: 1
          $meta:
            uiSchema: { "icon": "backpack", "viewType": "card" }
            necessary: "self"
```

### 5.2 动态快照 (Dynamic Snapshot in L3)

当会话运行时，Schema 随状态树存在于内存中。用户或脚本可以修改 `$meta`（例如改变 UI 样式，或增加新的属性定义）。

*   **变更记录**: Schema 的修改与其他数据的修改一样，生成 `OpLog`。
*   **持久化**: 当生成快照时，修改后的 Schema 随完整的状态树被保存在 `session.db` 的 `state_snapshots` 表的 JSON 字段中。

**优势**: 允许每个会话拥有“进化”的 Schema，而不影响原始 Pattern 或其他会话。

---

## 6. 总结 (Summary)

| 资源类型 | 存储位置 (Storage) | 引用方式 (Reference) | 加载时机 |
| :--- | :--- | :--- | :--- |
| **L2 Pattern** | `library/{id}/` | UUID | 会话初始化/重置 |
| **L3 Data** | `session.db` | SQL Query | 实时 |
| **Multimedia** | File System (`assets/` or `Vault`) | `asset://` URI | UI 渲染时 (Lazy) |
| **Schema** | Embedded in State Tree | JSON Path | 随状态加载 |

本设计完善了 Mnemosyne 的物理存储层细节，确保了资源的高效管理和系统的可移植性。
