# Clotho 宏系统设计规范 (Macro System Specification) 

**版本**: 1.0.0
**状态**: Draft
**关联文档**: `doc/architecture/02_jacquard_orchestration.md`, `doc/architecture/03_mnemosyne_data_engine.md`

---

## 1. 设计哲学与核心原则

Clotho 的宏系统设计严格遵循 **凯撒原则 (The Caesar Principle)**。我们采用 **Jinja2 (Dart Port)** 作为标准模板引擎，替代自定义的 XML 逻辑解析。

### 1.1 核心差异：模板渲染 vs 脚本执行
*   **SillyTavern**: 依赖正则替换和 JS `eval`，逻辑分散且不安全。
*   **Clotho (Jinja2)**: 
    *   **PromptASTExecutor (Template Renderer)**: 负责编译和执行 Jinja2 模板。
    *   **Filament 结构支撑**: XML (`<thought>`, `<reply>`) 依然作为 **结构骨架** 存在，用于 LLM 输出解析；而 **逻辑控制** (`{% if %}`, `{{ var }}`) 则完全由 Jinja2 接管。
    *   **纯净输出**: 所有 Jinja2 标签在送入 LLM 前都会被渲染为纯文本，LLM 看到的只是最终结果。

### 1.2 解决“副作用拼装”需求
利用 Jinja2 的原生能力，我们可以优雅地处理变量定义与内容注入，且不产生持久化副作用。

*   **场景**: 定义一个变量 `fragment`，存储一段复杂的 Prompt 文本，稍后注入。
*   **Clotho 方案**: 使用 Jinja2 的 `{% set %}` 块级赋值。

---

## 2. 宏分类与规范 (Jinja2 Syntax)

### 2.1 身份与上下文宏 (Context Variables)
直接作为 Jinja2 模板的上下文变量传入。

| 宏 (Clotho) | ST 对应 | 描述 |
| :--- | :--- | :--- |
| `{{ user }}` | `{{user}}` | 当前用户名 |
| `{{ char }}` | `{{char}}` | 当前角色名 |

### 2.2 状态与记忆宏 (State Variables)
Mnemosyne 的状态树以只读字典形式注入 Jinja2 上下文。

**语法**: `{{ state.path }}`

| 宏示例 | ST 对应 | 描述 |
| :--- | :--- | :--- |
| `{{ state.hp }}` | `{{getvar::hp}}` | 获取数值 |
| `{{ state.inventory[0].name }}` | - | 列表访问 |
| `{{ state_desc.hp }}` | - | 获取语义描述 |

### 2.3 逻辑控制与结构化拼装 (Logic & Assembly)
使用标准的 Jinja2 控制流标签。

| 语法 (Jinja2) | ST 对应 | 描述 | 实现方式 |
| :--- | :--- | :--- | :--- |
| `{% if condition %}...{% endif %}` | `<if>` | 条件渲染 | Jinja2 Native |
| `{{ random([a, b]) }}` | `{{random}}` | 随机选择 | Custom Filter / Function |
| `{% set var = "..." %}` | `{{setvar}}` | **定义临时变量** | Jinja2 Scoped Context |
| `{{ var }}` | `{{var}}` | **注入变量内容** | Jinja2 Variable Interpolation |

#### 2.3.1 解决 Prompt 动态内容注入案例

**ST 写法**:
```
{{setvar::灰魂4::\n- 灰魂会在...}}
...
{{灰魂4}}
```

**Clotho (Jinja2) 写法**:
```jinja
{# 1. 定义复杂内容块 (Block Assignment) #}
{% set grey_soul_fragment %}
- 灰魂会在任何用户需要的情况下合理的出现在用户所处场景，但不一定会帮助用户
{% endset %}

{# ... 在后续文档位置 ... #}

{# 2. 注入内容 #}
{{ grey_soul_fragment }}
```

**优势**:
1.  **Block Set**: `{% set var %}...{% endset %}` 语法原生支持多行文本和复杂结构。
2.  **Scope Safety**: `grey_soul_fragment` 仅存在于模板渲染上下文中，**绝对不会** 写入 Mnemosyne 数据库。

---

## 3. 安全沙箱 (Security Sandbox)

为了维护安全性，Jinja2 环境受到严格限制：

1.  **只读状态**: `state` 对象是不可变的 (Immutable) 或只读代理，模板无法执行 `state.hp = 0`。
2.  **禁用系统调用**: 无法访问文件系统 (`import 'io'`) 或网络。
3.  **函数白名单**: 仅暴露安全的辅助函数（如 `random`, `time`, `format`）。

---

## 4. 迁移映射表 (Migration Map)

| SillyTavern Macro | Clotho (Jinja2) |
| :--- | :--- |
| `{{user}}` | `{{ user }}` |
| `{{getvar::x}}` | `{{ state.x }}` |
| `{{setvar::x::y}}` (Temp) | `{% set x = y %}` |
| `{{#if x}}...{{/if}}` | `{% if x %}...{% endif %}` |
| `{{random:a,b}}` | `{{ random(['a', 'b']) }}` |
| `{{// comment}}` | `{# comment #}` |

---

## 5. 实现架构 (Architectural Integration)

1.  **Component**: `PromptASTExecutor` 重命名为 **`TemplateRenderer`**。
2.  **Engine**: 集成 `jinja` (Dart package)。
3.  **Pipeline**:
    *   **Input**: `Skein` (包含 `systemPrompt`, `lore` 等原始文本，可能包含 Jinja2 标签)。
    *   **Context Build**: 将 `Skein.metadata`, `Mnemosyne.state` 包装为 `Map<String, dynamic>` 上下文。
    *   **Render**: 调用 `jinja.render(template, context)`。
    *   **Output**: 纯净字符串，送往 LLM。


