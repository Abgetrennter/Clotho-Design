# Mnemosyne 多级模板继承实现方案

**版本**: 1.0.0
**日期**: 2025-12-28
**状态**: Draft
**作者**: Architect Mode

---

## 一、 方案概述

本方案详细描述了如何在 Clotho 的数据中枢 Mnemosyne 中实现类似 ERA 的多级模板继承机制。核心思想是在状态树中引入 `$meta.template` 元数据，并在数据查询 (Read) 和插入 (Write) 时，动态计算并应用继承的默认值。

**主要特性**:
- **继承链**: 子节点自动继承父节点的模板定义。
- **覆盖机制**: 子级模板可以覆盖父级模板，具体数据可以覆盖所有模板。
- **透明性**: 对于上层应用（如 UI 或 Jacquard），继承是透明的，获取到的始终是完整合并后的数据。

---

## 二、 数据结构定义

### 2.1 Meta 元数据扩展

在状态树的每个节点中，允许存在一个特殊的 `$meta` 字段。

```typescript
// 数据节点结构
interface StateNode {
  [key: string]: any; // 普通数据字段
  $meta?: MetaData;   // 元数据字段
}

// 元数据定义
interface MetaData {
  // 模板定义：定义当前层级及其子层级的默认结构
  template?: Record<string, any>;
  
  // 权限控制
  updatable?: boolean; // 默认 true
  necessary?: 'self' | 'children' | 'all'; // 默认 undefined (无保护)
  
  // 描述信息 (VWD)
  description?: string;
  
  // 其他扩展字段
  [key: string]: any;
}
```

### 2.2 示例数据结构

```json
{
  "characters": {
    "$meta": {
      "template": {
        // 所有 character 的默认属性
        "level": 1,
        "hp": 100,
        "inventory": [],
        "$meta": { "necessary": "self" } // 模板自带的 meta
      }
    },
    
    "npcs": {
      "$meta": {
        "template": {
          // 所有 npc 的额外默认属性，继承并覆盖 characters 的模板
          "faction": "neutral",
          "dialogue": []
        }
      },
      
      "guard_001": {
        // 实际数据
        "class": "Warrior"
        // 隐含继承: level=1, hp=100, faction="neutral", ...
      }
    }
  }
}
```

---

## 三、 核心算法

### 3.1 模板解析算法 (Template Resolution)

`resolveTemplate` 函数负责计算指定路径下的有效模板。

**输入**: `path` (目标节点的路径，例如 `"characters.npcs.guard_001"`)
**输出**: `mergedTemplate` (合并后的模板对象)

**执行步骤**:
1.  **路径分解**: 将路径分解为片段 `['characters', 'npcs', 'guard_001']`。
2.  **向上遍历**: 从根节点开始，逐层向下遍历到目标节点的父节点 (`characters` -> `npcs`)。
3.  **收集模板**: 在每一层，检查是否存在 `$meta.template`。如果存在，将其加入收集列表。
4.  **深度合并**: 按层级顺序（从顶层到底层）将收集到的模板进行深度合并 (Deep Merge)。
    - 后层级的属性覆盖前层级。
    - 数组通常替换而非合并（取决于具体策略，建议默认替换）。
    - `$meta` 字段本身也需要合并。

### 3.2 快照生成 (Snapshot Generation)

在 `Mnemosyne.getPunchcards()` 生成快照时，需要将模板应用到实际数据上。

**执行步骤**:
1.  遍历状态树的每个节点。
2.  对每个节点，调用 `resolveTemplate` 获取其应当继承的模板。
3.  将 **模板** 作为底板 (Base)。
4.  将 **实际数据 (Delta)** 覆盖在底板上。
5.  输出合并后的对象作为快照的一部分。

**性能优化 (Dirty Check & Caching)**:
- 由于全量计算开销大，必须引入缓存。
- 维护一个 `TemplateCache`，Key 为路径，Value 为计算后的模板。
- 仅当路径上的 `$meta.template` 发生变更时，才失效相关联的缓存（该节点及其所有子孙节点的缓存）。

### 3.3 插入操作 (Insert Operation)

当处理 `<variable_insert>` 或 `["SET", ...]` 操作时：

**执行步骤**:
1.  确定目标路径 `path`。
2.  获取该路径的有效模板 `tpl = resolveTemplate(path)`.
3.  如果插入的数据 `value` 中包含字段缺失，尝试从 `tpl` 中补全。
4.  (可选) 如果插入的数据完全符合模板默认值，可以仅存储差异部分，以节省空间。但在 Clotho 中，为了确定性，建议存储完整数据，而在传输时可进行压缩。

---

## 四、 实现接口 (Dart 伪代码)

```dart
abstract class ITemplateEngine {
  /// 获取指定路径的有效合并模板
  Map<String, dynamic> resolveTemplate(List<String> pathSegments);

  /// 将模板应用到原始数据上，生成完整视图
  Map<String, dynamic> applyTemplate(Map<String, dynamic> rawData, List<String> pathSegments);
}

class MnemosyneTemplateEngine implements ITemplateEngine {
  final Map<String, dynamic> _stateTree;
  final Map<String, Map<String, dynamic>> _cache = {};

  MnemosyneTemplateEngine(this._stateTree);

  @override
  Map<String, dynamic> resolveTemplate(List<String> pathSegments) {
    String cacheKey = pathSegments.join('.');
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    Map<String, dynamic> mergedTpl = {};
    List<String> currentPath = [];
    
    // 遍历路径寻找所有相关的 $meta.template
    // 注意：只遍历到父级，因为目标节点自己的 template 是给它的子节点用的
    for (int i = 0; i < pathSegments.length; i++) {
       // ... 获取当前层级的 template ...
       // ... mergedTpl = deepMerge(mergedTpl, currentLevelTemplate) ...
    }

    _cache[cacheKey] = mergedTpl;
    return mergedTpl;
  }
  
  // ... deepMerge 实现 ...
}
```

---

## 五、 边界情况与注意事项

1.  **循环引用**: 确保模板定义中不包含循环引用，否则会导致合并死循环。
2.  **数组合并**: 默认策略为 **替换**。如果需要数组追加，建议在应用层逻辑处理，而非模板层。
3.  **$meta 继承**: `$meta` 本身也是数据的一部分，子节点的 `$meta` 会覆盖模板中的 `$meta`。例如，模板定义 `necessary: self`，子节点可以定义 `necessary: undefined` 来取消保护。
4.  **性能**: 模板层级不宜过深（建议不超过 5 层），否则每次读写都会有可感知的性能损耗。
