# Clotho 架构改进实施计划：ERA 特性融合

**版本**: 1.0.0
**日期**: 2025-12-28
**状态**: Draft
**作者**: Architect Mode

---

## 一、 计划概述

本计划旨在将 ERA 插件中验证成功的核心设计模式（多级模板继承、删除保护、语义化操作、数学表达式）融入 Clotho 架构。这些改进将增强 Clotho 的数据灵活性、操作直观性和系统安全性，同时保持 Clotho 现有的高性能和确定性优势。

**核心目标**：
1.  **数据层 (Mnemosyne)**: 实现支持 `$meta.template` 多级继承和 `$meta.necessary` 删除保护的数据引擎。
2.  **协议层 (Filament)**: 扩展 Filament v2.3 协议，支持 `<variable_insert>` 等语义化标签作为 OpCode 的高级封装。
3.  **编排层 (Jacquard)**: 增强 Updater 模块，支持安全的数学表达式求值。
4.  **通信层 (Infrastructure)**: 引入统一事件总线机制，实现模块解耦。

---

## 二、 详细实施步骤

### 阶段 1：数据引擎增强 (Mnemosyne Layer)

本阶段专注于数据结构的底层改造，使其支持 ERA 风格的模板和保护机制。

#### 1.1 实现 `$meta` 元数据解析器
- **目标**: 使 Mnemosyne 能够识别和处理嵌套对象中的 `$meta` 字段。
- **关键任务**:
    - 定义 `$meta` 结构 Schema：
      ```typescript
      interface MetaData {
        updatable?: boolean;
        necessary?: 'self' | 'children' | 'all';
        template?: Record<string, any>;
        description?: string; // 融合 VWD 概念
      }
      ```
    - 实现 `MetaParser`，在读取状态时自动提取元数据。

#### 1.2 实现多级模板继承逻辑
- **目标**: 在读取或插入数据时，自动应用多级模板默认值。
- **关键算法**: `resolveTemplate(path)`
    1.  从当前路径向上遍历父节点。
    2.  收集沿途所有 `$meta.template` 定义。
    3.  按 "父级 -> 子级 -> 自身" 的顺序深度合并模板。
    4.  将最终模板作为基准对象，叠加当前实际数据。
- **集成点**: 在 `Mnemosyne.getPunchcards()` 快照生成时应用，确保 LLM 看到的是完整数据。

#### 1.3 实现删除/更新保护校验
- **目标**: 在执行变更操作前，校验权限。
- **关键任务**:
    - 增强 `StateChain` 的变更验证逻辑。
    - **删除保护**: 检查 `$meta.necessary`。
        - `self`: 阻止删除当前节点。
        - `children`: 阻止删除子属性。
        - `all`: 阻止递归删除。
    - **更新保护**: 检查 `$meta.updatable`。
        - `false`: 阻止修改值（除非操作显式覆盖权限）。

---

### 阶段 2：协议层扩展 (Filament Protocol)

本阶段专注于扩展 Filament 协议，使其支持更具表达力的标签。

#### 2.1 定义语义化操作标签 (ERA-Compatible)
- **目标**: 在 Filament 中引入 ERA 风格的操作标签。
- **规范**:
    ```xml
    <!-- 插入: 非破坏性，支持模板 -->
    <variable_insert>
      <path>characters.new_npc</path>
      <value>{"name": "Alice"}</value> <!-- JSON 格式 -->
    </variable_insert>

    <!-- 编辑: 破坏性更新 -->
    <variable_edit>
      <path>player.hp</path>
      <value>80</value>
    </variable_edit>

    <!-- 删除 -->
    <variable_delete>
      <path>player.inventory.old_item</path>
    </variable_delete>
    ```

#### 2.2 实现标签到 OpCode 的转译器 (Transpiler)
- **目标**: 保持底层 OpCode 执行引擎的纯粹性，在解析层将高级标签转译为基础 OpCode。
- **逻辑映射**:
    - `<variable_insert>` -> 检查路径是否存在 -> (如果否) 生成 `["SET", path, merged_value]` (合并了模板)。
    - `<variable_edit>` -> 生成 `["SET", path, value]`。
    - `<variable_delete>` -> 生成 `["DELETE", path]`。
- **位置**: `FilamentParser` 的 `TagRouter` 中。

---

### 阶段 3：计算能力增强 (Jacquard Layer)

本阶段增强编排层的动态计算能力。

#### 3.1 集成安全数学表达式引擎
- **目标**: 支持 `+=10`, `max_hp * 0.5` 等动态赋值。
- **技术选型**: 使用 `math_expressions` (Dart) 或自定义的简易 AST 解析器，确保无副作用。
- **支持语法**:
    - 基础运算: `+`, `-`, `*`, `/`, `%`
    - 相对运算: `+=`, `-=`, `*=`, `/=`
    - 变量引用: 支持引用当前状态树中的其他变量 (e.g., `player.max_hp`)。

#### 3.2 增强 Updater 执行逻辑
- **流程**:
    1.  解析 OpCode 或语义标签中的 value 字符串。
    2.  检测是否包含表达式特征 (如以 `+=` 开头，或包含操作符)。
    3.  如果是表达式，从 Mnemosyne 获取相关变量的当前值。
    4.  计算结果。
    5.  执行最终的 `SET` 操作。

---

### 阶段 4：通信层重构 (Infrastructure)

本阶段引入事件总线，提升模块间的解耦。

#### 4.1 实现统一事件总线 (EventBus)
- **目标**: 替代目前紧耦合的组件调用。
- **设计**:
    ```dart
    // 定义核心事件流
    class ClothoEventBus {
      final _controller = StreamController<ClothoEvent>.broadcast();
      Stream<ClothoEvent> get onEvent => _controller.stream;
      void emit(ClothoEvent event) => _controller.add(event);
    }
    ```

#### 4.2 定义核心事件类型
- `StateUpdatedEvent`: 当 Mnemosyne 状态发生变更时触发 (携带 diff)。
- `SnapshotGeneratedEvent`: 当新快照生成时触发。
- `FilamentTagParsedEvent`: 当解析到特定标签时触发 (用于 UI 更新)。

---

## 三、 风险评估与对策

| 风险点 | 影响 | 对策 |
|--------|------|------|
| **性能损耗** | 多级模板继承需要在读取时进行深度合并，可能影响快照生成速度。 | 1. 实现模板缓存机制 (Cache)。<br>2. 仅在必要时 (Dirty Check) 重新计算合并结果。 |
| **OpCode 膨胀** | 引入语义标签可能导致指令集过于复杂。 | 坚持 "OpCode 为汇编，标签为高级语言" 的原则，底层只执行 OpCode，标签只在解析层存在。 |
| **表达式安全** | 允许执行字符串表达式可能带来注入风险。 | 严格限制表达式引擎的能力，禁止函数调用，仅允许预定义的数学运算和变量引用。 |

---

## 四、 后续行动建议

1.  **原型验证 (PoC)**: 优先实现 Mnemosyne 的多级模板继承逻辑，验证其对现有数据结构的影响。
2.  **协议文档更新**: 更新 `09_filament_protocol.md`，纳入 `<variable_insert>` 等新标签规范。
3.  **测试用例构建**: 编写针对模板继承、删除保护和数学表达式的单元测试。
