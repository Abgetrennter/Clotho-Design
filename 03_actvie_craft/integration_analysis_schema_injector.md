# Schema Injector 与工作流文档整合分析

**分析日期**: 2026-02-19
**分析范围**: 
- `schema-injector.md` (新建)
- `prompt-processing.md`
- `post-generation-processing.md`
- `skein-and-weaving.md`

---

## 1. 整合概述

Schema Injector 作为 Jacquard 流水线的新组件（优先级 350），成功填补了 Skein Builder (300) 和 Template Renderer (400) 之间的功能空白。经过整合分析，主要发现了以下协同点和已修复的接口。

---

## 2. 协同点验证

### 2.1 流水线位置 ✅ 已确认

```
Prompt Processing Pipeline:
Planning (100) → Skein Builder (300) → Schema Injector (350) → Template Renderer (400) → Assembler (450) → Invoker (500)
```

**验证结果**: Schema Injector 的位置正确，位于 Skein 构建之后、模板渲染之前。

### 2.2 Skein 集成 ✅ 已确认

| Schema Injector 输出 | Skein 目标位置 | Weaving 阶段处理 |
|---------------------|---------------|-----------------|
| `instruction` (META_FORMAT) | `systemChain` | 直接拼接 |
| `examples` (COGNITION_EXAMPLE) | `floatingChain` → `user_anchor` | Step 3: 浮线缝合 |
| `lore_context` (ENCYCLOPEDIA) | `floatingChain` → `floating_relative` | Step 3: 浮线缝合 |

**验证结果**: Schema Injector 注入的 Block 会被 Skein Weaving 流程正确处理。

### 2.3 Parser Hints 接口 ✅ 已确认

**数据流**:
```
Schema Injector (生成前)
  ↓ 写入 blackboard['parser_hints']
Filament Parser (生成后)
  ↓ 读取并动态扩展路由表
Tag Router (实时解析)
```

**验证结果**: 接口设计正确，前后流程衔接完整。

---

## 3. 已执行的整合修改

### 3.1 `prompt-processing.md` 更新

1. **添加关联文档引用**: 添加 `schema-injector.md` 链接
2. **更新第 2.2 阶段标题**: 明确包含 Schema Injector
3. **添加阶段说明表格**: 区分 Skein Builder (300) 和 Schema Injector (350) 的职责
4. **扩展装填操作表**: 添加 Schema 注入和 Parser Hints 写入

### 3.2 `post-generation-processing.md` 更新

1. **添加关联文档引用**: 添加 `schema-injector.md` 链接
2. **更新解析状态机说明**: 添加动态标签注册机制说明
3. **扩展标签类型表**: 
   - 添加 "来源" 列区分 Core/Extension/Mode Schema
   - 添加动态标签处理说明

### 3.3 `schema-injector.md` 更新

1. **添加关联文档引用**: 添加 workflow 文档链接
2. **更新依赖注册说明**: 添加消费端说明，指向 post-generation-processing.md

---

## 4. 一致性检查

### 4.1 BlockType 映射一致性 ✅

| 文档 | META_FORMAT (extension) | META_FORMAT_OVERRIDE (mode) | COGNITION_EXAMPLE | ENCYCLOPEDIA |
|------|------------------------|----------------------------|-------------------|--------------|
| `schema-injector.md` | system_end | system_start | before_history | floating |
| `preset-system.md` | ✓ 对齐 | ✓ 对齐 | ✓ 对齐 | ✓ 对齐 |
| `skein-and-weaving.md` | ✓ 支持 | ✓ 支持 | ✓ 支持 | ✓ 支持 |

### 4.2 Blackboard Key 一致性 ✅

| Key | 写入者 | 读取者 | 一致性 |
|-----|--------|--------|--------|
| `parser_hints` | Schema Injector | Filament Parser | ✅ 已确认 |
| `active_schemas` | Schema Injector | (调试/监控) | ✅ 已确认 |

### 4.3 优先级一致性 ✅

| 插件 | schema-injector.md | plugin-architecture.md | 一致性 |
|------|-------------------|----------------------|--------|
| Skein Builder | 300 | 300 | ✅ |
| Schema Injector | 350 | (新增) | ✅ |
| Template Renderer | 400 | 400 | ✅ |

---

## 5. 潜在边界情况

### 5.1 Schema 注入与 Weaving 规则冲突

**场景**: Schema Injector 注入的 `FloatingAsset` 与 `SkeinTemplate.weavingRules` 配置冲突。

**当前行为**: Schema Injector 设置 `sourceType: 'schema_*'`，Weaving Rules 需要显式配置匹配规则。

**建议**: 在 `skein-and-weaving.md` 中添加默认规则：
```yaml
weaving_rules:
  - asset_type: 'schema_instruction'
    default_position: 'system_end'
    priority: 150
  - asset_type: 'schema_example'
    default_position: 'user_anchor'
    priority: 80
```

### 5.2 动态标签未注册解析失败

**场景**: Schema 定义了 `parser_hints.root_tag`，但 Filament Parser 未正确读取 blackboard。

**当前行为**: Parser 会将未知标签作为普通文本处理。

**建议**: 在 `post-generation-processing.md` 中添加 fallback 处理说明。

---

## 6. 结论

Schema Injector 与现有工作流文档整合成功，未发现严重冲突。主要接口（Skein 注入、Parser Hints、BlockType 映射）均已对齐。

**整合完成度**: 95%

**剩余工作**:
1. 在 `skein-and-weaving.md` 中明确 Schema 类型资产的默认 Weaving 规则
2. 在 `filament-parsing-workflow.md` 中补充动态标签注册细节

---

*分析完成*: 2026-02-19
