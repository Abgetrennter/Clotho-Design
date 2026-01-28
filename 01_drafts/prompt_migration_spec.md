# Prompt 排序与注入逻辑迁移规范 (Migration Spec: Prompt Ordering & Injection)

**版本**: 1.0.0
**日期**: 2025-12-27
**状态**: Draft
**关联文档**: `doc/architecture/02_jacquard_orchestration.md`, `plans/preset-import-design-spec.md`

## 1. 背景与目标

在从 SillyTavern 迁移到 Clotho 架构时，Prompt 的注入顺序 (Injection Order) 和动态位置 (Dynamic Position) 是最容易出错的环节。ST 使用 `prompt_order` 数组定义绝对顺序，而 Clotho 的 Jacquard 引擎使用基于策略的动态注入 (`InjectionConfig`)。

本规范定义了如何将 ST 的排序逻辑无损迁移到 Jacquard 流水线中，确保 Prompt 上下文的一致性。

## 2. 核心概念映射

| ST 概念 | Clotho Jacquard 概念 | 描述 |
| :--- | :--- | :--- |
| **Prompt Order** | **Sequence Strategy** | 定义 Prompt 块在上下文中的线性排列顺序。 |
| **Injection Depth** | **Depth Strategy (relativeToEnd)** | 定义 Prompt 块相对于上下文末尾（通常是最新消息）的偏移量。 |
| **Role** | **Block Role** | System, User, Assistant 等角色定义。 |
| **Placeholder** | **Jinja2 Macro** | `{{user}}`, `{{char}}` 等动态变量的替换机制。 |

## 3. 注入策略规范 (Injection Strategies)

Jacquard 引入 `InjectionStrategy` 接口来处理复杂的排序需求。针对 ST 迁移，我们需要实现以下两种策略：

### 3.1 基于序列的排序 (Sequence Strategy)

适用于 System Prompt、世界书、角色描述等通常位于上下文头部的静态或半静态内容。

*   **配置参数**:
    *   `index` (int): 全局排序索引，值越小越靠前。
*   **迁移逻辑**:
    1.  解析 ST 的 `prompt_order` 数组。
    2.  为数组中的每个 Item 分配一个递增的 `index` (0, 100, 200...)。
    3.  建议使用 100 作为步长，以便后续插入中间层。

### 3.2 基于深度的注入 (Depth Strategy)

适用于 "Jailbreak" (越狱)、"Author's Note" (作者注)、"Main Prompt" (主提示词) 等需要紧贴最新消息的内容。

*   **配置参数**:
    *   `depth` (int): 距离末尾的消息数。`0` 表示并在最新消息之后，`1` 表示在最新消息之前。
    *   `priority` (int): 当多个块具有相同 depth 时的同级排序权重。
*   **迁移逻辑**:
    1.  检查 ST Item 的 `injection_depth` 属性。
    2.  若 `injection_depth > 0`，则转换为 Depth Strategy。
    3.  **注意**: ST 的 depth 计算逻辑可能与 Clotho 略有差异（例如是否包含 System 消息），迁移时需进行 `depth + offset` 的校准。

## 4. 迁移算法 (Migration Algorithm)

### 4.1 输入
*   ST `prompts` 列表
*   ST `prompt_order` 列表

### 4.2 处理流程

```python
def migrate_prompt_order(st_prompts, st_order):
    clotho_blocks = []
    
    # 1. 建立 ID 映射
    prompt_map = {p['identifier']: p for p in st_prompts}
    
    # 2. 遍历 Order 列表 (处理 Sequence)
    current_sequence = 0
    for item in st_order:
        prompt_id = item['identifier']
        prompt_data = prompt_map.get(prompt_id)
        
        if not prompt_data: continue
        
        # 3. 判断策略
        if prompt_data.get('injection_depth', 0) > 0:
            # Depth Strategy
            config = InjectionConfig(
                strategy='depth',
                depth=prompt_data['injection_depth'],
                priority=current_sequence # 保持同级相对顺序
            )
        else:
            # Sequence Strategy
            config = InjectionConfig(
                strategy='sequence',
                index=current_sequence
            )
            current_sequence += 100
            
        # 4. 构建 Clotho Block
        block = PromptBlock(
            id=prompt_id,
            content=convert_to_jinja2(prompt_data['content']),
            role=map_role(prompt_data['role']),
            injection_config=config
        )
        clotho_blocks.append(block)
        
    return clotho_blocks
```

## 5. 数据结构定义 (YAML Schema)

生成的 Clotho 预设文件将遵循以下 YAML 结构：

```yaml
version: "1.0"
preset:
  name: "GrayWill Migration"
  source: "SillyTavern"

pipeline:
  # 静态序列区
  sequence:
    - id: "worldInfoBefore"
      index: 0
      enabled: true
    - id: "charDescription"
      index: 100
      enabled: true
      
  # 深度注入区
  depth:
    - id: "jailbreak"
      depth: 4
      priority: 10
      enabled: true

blocks:
  - id: "worldInfoBefore"
    role: "system"
    content: |
      {{ world_info.before }}
      
  - id: "jailbreak"
    role: "system"
    content: |
      [System Note: Always stay in character...]
```

## 6. 特殊情况处理

### 6.1 锚点冲突 (Anchor Conflicts)
如果 ST 预设中包含与 Clotho 内部锚点（如 `ChatHistory`）重名的 ID，迁移器应自动重命名（例如 `st_ChatHistory`）以避免冲突，并在 Sequence 中显式保留其位置。

### 6.2 动态启用条件
ST 的 Prompt 常常包含 `enabled` 字段。Clotho 将其映射为 Jacquard 的 `Condition`：
*   `true/false` -> 静态配置。
*   复杂逻辑 -> 需要转换为 Jinja2 `{% if ... %}` 块包裹内容。

## 7. 验证标准

1.  **顺序一致性**: 迁移后的 `Sequence` 索引必须严格对应 ST 的 `prompt_order`。
2.  **深度准确性**: `Depth` 注入的块必须出现在相对于聊天记录末尾的正确位置。
3.  **变量可解析**: 所有 ST 宏 (`{{...}}`) 都必须被转换为有效的 Jinja2 表达式或保留为字面量（若无对应）。
