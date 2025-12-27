# 角色卡导入与保存逻辑文档

本文档详细描述了 SillyTavern 中角色卡导入、解析和保存的内部逻辑。

## 1. 核心文件

*   **`src/endpoints/characters.js`**: 处理角色相关的 API 路由，包括导入、导出、编辑和删除。
*   **`src/character-card-parser.js`**: 专门用于处理 PNG 图片中嵌入的角色元数据（读取和写入）。

## 2. 导入流程 (Import Process)

角色导入主要通过 `/api/characters/import` POST 路由处理。

### 2.1 支持的格式

系统支持多种角色卡格式，通过文件扩展名或 `file_type` 参数区分：

*   **PNG**: 标准的角色卡图片，元数据嵌入在图片中。
*   **JSON**: 包含角色数据的 JSON 文件（支持 V1, V2, V3, Pygmalion 等格式）。
*   **YAML / YML**: YAML 格式的角色定义。
*   **CHARX**: TavernAI 角色卡压缩包格式。
*   **BYAF**: 另一种角色卡格式。

### 2.2 导入逻辑 (`src/endpoints/characters.js`)

路由处理函数位于 `src/endpoints/characters.js` 的 `/import` 端点。它根据文件类型分发给不同的处理函数：

1.  **`importFromPng`**:
    *   调用 `readCharacterData` 读取图片中的元数据。
    *   解析 JSON 数据。
    *   如果数据包含 `spec` 字段（V2/V3），调用 `readFromV2` 进行标准化。
    *   如果数据是旧版（V1），手动构建对象并调用 `convertToV2` 转换为 V2 格式。
    *   调用 `writeCharacterData` 保存文件。

2.  **`importFromJson`**:
    *   读取 JSON 内容。
    *   识别数据格式（V2/V3 规范, V1 旧版, 或 Gradio/Pygmalion 格式）。
    *   将数据转换为统一的 V2 格式。
    *   使用默认头像 (`DEFAULT_AVATAR_PATH`) 调用 `writeCharacterData` 保存。

3.  **`importFromYaml`**:
    *   解析 YAML 内容。
    *   映射字段并转换为 V2 格式。
    *   使用默认头像保存。

4.  **`importFromCharX`**:
    *   解压 ZIP 文件。
    *   提取 `card.json` 并解析。
    *   尝试从压缩包中提取头像图片，如果失败则使用默认头像。
    *   保存数据和头像。

## 3. 解析与保存逻辑 (Parsing & Saving)

### 3.1 PNG 元数据处理 (`src/character-card-parser.js`)

SillyTavern 使用 PNG 的 `tEXt` 数据块来存储角色数据。

*   **读取 (`read` 函数)**:
    *   提取 PNG 的所有数据块。
    *   优先查找关键字为 `ccv3` (Character Card V3) 的 `tEXt` 块。
    *   如果未找到，查找关键字为 `chara` (Character Card V2) 的 `tEXt` 块。
    *   将 Base64 编码的内容解码为 UTF-8 字符串。

*   **写入 (`write` 函数)**:
    *   接收图片 Buffer 和角色数据字符串。
    *   移除现有的 `chara` 或 `ccv3` 数据块。
    *   将数据编码为 Base64。
    *   插入新的 `chara` 数据块（V2 格式）。
    *   尝试将数据转换为 V3 格式并插入 `ccv3` 数据块（为了兼容性）。
    *   重新打包 PNG 数据块。

### 3.2 数据保存 (`src/endpoints/characters.js`)

**`writeCharacterData`** 是保存角色卡的核心函数：

1.  **缓存清理**: 清除内存缓存 (`memoryCache`) 中对应的条目。
2.  **图片处理**:
    *   如果输入是图片路径，读取图片。
    *   如果输入是 Buffer，直接使用。
    *   支持裁剪 (`crop`) 操作，使用 `Jimp` 库调整头像大小。
3.  **元数据写入**: 调用 `character-card-parser.js` 的 `write` 方法，将 JSON 数据嵌入图片。
4.  **文件写入**: 使用 `write-file-atomic` 将最终的 Buffer 写入磁盘（`public/characters` 目录）。

## 4. 数据规范转换

为了保证内部处理的一致性，所有导入的角色数据都会被转换为 **Character Card V2** 规范。

*   **`convertToV2`**: 将旧版 V1 字段（如 `description`, `personality` 等）映射到 V2 结构。
*   **`readFromV2`**: 读取 V2 数据，处理缺失字段的默认值，并处理扩展字段（如 `extensions.depth_prompt`）。
*   **`charaFormatData`**: 用于格式化来自前端表单的数据，确保符合 V2 规范，并处理世界书（World Info）的关联。
