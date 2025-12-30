# Filament Protocol v2.3 扩展：ERA 语义化标签与简化 OpCode

**版本**: 1.1.0
**日期**: 2025-12-28
**状态**: Draft
**作者**: Architect Mode

---

## 一、 规范概述

本规范定义了 Filament Protocol v2.3 的扩展部分，旨在引入 ERA 风格的语义化变量操作标签，并**进一步简化底层 OpCode 的格式**。

**设计原则**:
1.  **高级语义**: 标签表达意图 (Intent)。
2.  **极致简洁**: OpCode 支持 **Bare Word (裸词)** 格式，去除不必要的 JSON 引号，最大化 Token 效率。
3.  **严格结构**: 外部标签保持 XML 结构，确保解析边界清晰。

---

## 二、 简化 OpCode 格式 (v2.4 Draft)

为了进一步降低 Token 消耗并提高 LLM 输出的流畅度，引入 **Bare Word OpCode** 格式。该格式允许在不引起歧义的情况下省略字符串的引号。

### 2.1 格式定义

标准 JSON: `["SET", "player.hp", 10]`
**简化格式**: `[SET, player.hp, 10]`

**解析规则 (Loose Parser)**:
1.  **分隔符**: 以 `[` 开始，以 `]` 结束，内部元素以 `,` 分隔。
2.  **类型推断**:
    - **数字**: 如果元素能被解析为数字 (如 `10`, `-5.5`)，则视为 Number。
    - **布尔**: `true` / `false` (不区分大小写) 视为 Boolean。
    - **字符串**: 其他情况默认为 String。
        - **裸词 (Bare Word)**: `player.hp`, `happy`, `SET` -> 视为字符串 `"player.hp"`, `"happy"`, `"SET"`。
        - **引用字符串 (Quoted String)**: 如果包含空格或特殊字符 (如 `,`, `]`)，必须使用双引号包裹，如 `"He is happy"`。

### 2.2 示例对比

| 操作 | 标准 JSON (v2.0) | 简化格式 (v2.4) | Token 节省 |
| :--- | :--- | :--- | :--- |
| **数值更新** | `["SET", "hp", 100]` | `[SET, hp, 100]` | ~4 tokens |
| **状态枚举** | `["SET", "mood", "sad"]` | `[SET, mood, sad]` | ~4 tokens |
| **含空格文本** | `["SET", "desc", "A B"]` | `[SET, desc, "A B"]` | ~2 tokens |
| **布尔值** | `["SET", "dead", false]` | `[SET, dead, false]` | ~4 tokens |

---

## 三、 新增语义化标签定义

### 3.1 插入操作 `<variable_insert>`

用于向状态树中添加新节点。

**结构**:
```xml
<variable_insert>
  <path>目标路径</path>
  <value>JSON 值 (支持简化格式)</value>
  <analysis>操作意图说明</analysis>
</variable_insert>
```

**示例**:
```xml
<variable_insert>
  <analysis>获得治疗药水</analysis>
  <path>player.inventory.potion_01</path>
  <value>{ name: "Healing Potion", effect: "Heal 50 HP" }</value> <!-- 支持简化 JSON -->
</variable_insert>
```

### 3.2 编辑操作 `<variable_edit>`

用于修改已存在的节点。

**结构**:
```xml
<variable_edit>
  <path>目标路径</path>
  <value>值 或 表达式</value>
  <analysis>操作意图说明</analysis>
</variable_edit>
```

**示例**:
```xml
<variable_edit>
  <analysis>受到伤害</analysis>
  <path>player.hp</path>
  <value>-= 20</value> <!-- 直接写表达式，无需引号 -->
</variable_edit>
```

### 3.3 批量更新 `<variable_update>` (推荐)

结合语义化外壳与简化 OpCode 内核的最佳实践。

**结构**:
```xml
<variable_update>
  <analysis>...</analysis>
  [
    [OpCode, Path, Value],
    [OpCode, Path, Value]
  ]
</variable_update>
```

**示例**:
```xml
<variable_update>
  <analysis>战斗结算：扣血，加经验，心情变化</analysis>
  [
    [SUB, player.hp, 20],
    [ADD, player.exp, 50],
    [SET, player.mood, tired]
  ]
</variable_update>
```

---

## 四、 解析器实现规范

`FilamentParser` 需要实现一个自定义的 **Loose JSON Parser**。

**算法伪代码 (Dart)**:
```dart
List<dynamic> parseLooseArray(String input) {
  // 1. 去除首尾 []
  var content = input.trim();
  if (content.startsWith('[') && content.endsWith(']')) {
    content = content.substring(1, content.length - 1);
  }
  
  // 2. 按逗号分割，但忽略引号内的逗号
  var tokens = splitByComma(content);
  
  return tokens.map((t) {
    t = t.trim();
    if (isNumber(t)) return parseNumber(t);
    if (isBool(t)) return parseBool(t);
    if (isQuoted(t)) return unquote(t);
    return t; // Bare word -> String
  }).toList();
}
```

---

## 五、 兼容性与迁移

- **混合支持**: 解析器应同时支持标准 JSON 和简化格式。
- **System Prompt**: 提示词中应展示简化格式的示例，引导 LLM 使用更高效的格式。
