# 情感与叙事的元模型设计

**版本**: 0.1.0
**日期**: 2026-02-13
**状态**: Draft
**优先级**: Low
**作者**: Clotho Design Team

---

## 1. 概述

本文档定义 Clotho 中**叙事层面**的元模型设计，用于指导 AI 生成长文本时保持情感连贯性、叙事节奏和主题一致性。

**设计目标**:
- 为长对话提供结构化的叙事框架
- 在确定性逻辑与 LLM 创造性之间建立桥梁
- 保持 Clotho 「凯撒的归凯撒」原则——框架由代码掌控，内容由 LLM 生成

**适用范围**: 作为未来扩展功能，当前优先级较低。

---

## 2. 核心概念映射

| 叙事概念 | Clotho 隐喻映射 | 技术载体 |
|---------|----------------|---------|
| 情感弧线 (Emotional Arc) | **丝络走向 (Thread Trajectory)** | Pattern 扩展 + Mnemosyne 追踪 |
| 叙事节拍 (Narrative Beat) | **织卷章节 (Tapestry Chapter)** | Tapestry 元数据标记 |
| 主题一致性 (Thematic Consistency) | **织谱底色 (Pattern Ground)** | Pattern 主题锚点 + 运行时检测 |

---

## 3. 情感弧线 (Emotional Arc)

### 3.1 定义

情感弧线描述角色情绪状态随剧情发展的预期轨迹。它不等于强制 LLM 输出特定情绪，而是提供一个**参考框架**，让编排层能够检测偏离并进行引导。

### 3.2 数据结构

在 **织谱 (Pattern)** 中定义情感签名:

```yaml
# pattern.yml - emotional_signature 扩展
emotional_signature:
  baseline: "neutral"           # 基线情绪状态
  volatility: 0.3               # 波动系数 (0.0-1.0)
  
  # 预定义的情感弧线模板
  arc_templates:
    - name: "trust_building"
      description: "从戒备到信任的情感建立过程"
      trigger_condition: "intimacy > 30"
      stages:
        - order: 1
          target_mood: "curious"
          tolerance: 0.2          # 允许偏离度
          transition_hints: 
            - "开始询问个人问题"
            - "对对方的背景表示兴趣"
        - order: 2
          target_mood: "cautiously_open"
          tolerance: 0.25
          transition_hints:
            - "分享不重要的秘密"
            - "轻微的自我暴露"
        - order: 3
          target_mood: "trusting"
          tolerance: 0.3
          transition_hints:
            - "表达脆弱时刻"
            - "主动寻求建议"
```

### 3.3 运行时追踪

**Mnemosyne** 维护实际情感轨迹:

```yaml
# tapestry 运行时元数据
emotional_trajectory:
  character_id: "char_001"
  recorded_states:
    - turn: 12
      detected_mood: "curious"
      arc_alignment: 0.85        # 与目标弧线吻合度
    - turn: 15
      detected_mood: "distant"
      arc_alignment: 0.35        # 偏离警告
```

### 3.4 偏离处理

当 `arc_alignment` 低于阈值时，**Jacquard Planner** 可采取:

1. **软性引导**: 在 Prompt 中加入 `transition_hints`
2. **事件干预**: 插入外部事件促使情绪转向
3. **弧线调整**: 如果偏离成为新趋势，更新目标弧线

---

## 4. 叙事节拍 (Narrative Beat)

### 4.1 定义

叙事节拍是场景级别的结构单元，类似音乐的小节。它标记剧情的节奏节点，确保长对话不会陷入无限平铺。

### 4.2 数据结构

**织卷 (Tapestry)** 的节拍结构:

```yaml
# tapestry.yml - beat_structure 扩展
beat_structure:
  current_act: 2                  # 当前幕/章节
  
  beats:
    - id: "beat_001"
      type: "setup"
      status: "completed"
      turn_range: [1, 5]
      required_elements: []       # 建制阶段无强制要素
      
    - id: "beat_002"
      type: "rising_action"
      status: "completed" 
      turn_range: [6, 12]
      emotional_turn: "negative"  # 情绪走向
      
    - id: "beat_003"
      type: "climax"
      status: "in_progress"
      turn_range: [13, null]      # 进行中
      required_elements:          # 高潮必须包含
        - "confrontation"        # 对峙
        - "emotional_peak"       # 情绪顶点
      optional_elements:
        - "revelation"           # 真相揭露
        
    - id: "beat_004"
      type: "falling_action"
      status: "pending"
      prerequisites: ["beat_003"] # 依赖前置节拍完成
```

### 4.3 节拍类型标准

| 类型 | 代码标识 | 功能 | 典型长度 |
|------|---------|------|---------|
| 建制 | `setup` | 建立场景、引入角色 | 3-5 轮 |
| 上升动作 | `rising_action` | 冲突升级、张力积累 | 5-10 轮 |
| 高潮 | `climax` | 情绪/剧情顶点 | 2-4 轮 |
| 回落动作 | `falling_action` | 冲突余波、后果处理 | 3-5 轮 |
| 收束 | `resolution` | 阶段性收尾、状态更新 | 2-3 轮 |

### 4.4 运行时流程

```
Jacquard Planner
    │
    ├── 读取当前 Beat
    ├── 检查 required_elements 完成度
    ├── 组装 Prompt (包含节拍上下文)
    │
    LLM 生成
    │
    Filament Parser
    │
    ├── 解析 <beat_complete> 标签
    ├── 更新 Beat 状态
    └── 触发下一 Beat 或保持当前
```

### 4.5 Filament 协议扩展

输出格式支持节拍标记:

```xml
<filament>
  <thought>这是一个情感对峙的高潮时刻...</thought>
  <content>"你为什么要瞒着我？"她的声音颤抖着。</content>
  <beat_complete>
    <completed_elements>
      <element>confrontation</element>
      <element>emotional_peak</element>
    </completed_elements>
    <suggested_next_beat>falling_action</suggested_next_beat>
  </beat_complete>
</filament>
```

---

## 5. 主题一致性 (Thematic Consistency)

### 5.1 定义

主题锚点确保剧情不偏离核心主题。它是一套防御机制，而非创意枷锁——允许在主题框架内的自由发挥。

### 5.2 三层防御架构

#### L1: Pattern 层 - 主题声明

```yaml
# pattern.yml - thematic_anchors 扩展
thematic_anchors:
  core_theme: "redemption"        # 核心主题
  
  sub_themes:                     # 子主题
    - "guilt_vs_duty"
    - "forgiveness"
    - "second_chances"
  
  thematic_keywords:              # 主题关键词云
    positive: ["救赎", "原谅", "新生", "弥补"]
    negative: ["罪孽", "愧疚", "逃避", "执念"]
  
  forbidden_drifts:               # 明确禁止的偏离
    - theme: "pure_romance"
      reason: "非恋爱向故事"
    - theme: "comedy_focus" 
      reason: "整体基调严肃"
    
  drift_tolerance: 0.3            # 全局偏离容忍度
```

#### L2: Jacquard 层 - 实时检测

轻量级主题偏离检测:

```dart
class ThematicDriftDetector {
  /// 检测生成内容是否偏离主题
  DriftReport checkDrift(String content, ThematicAnchor anchor) {
    // 1. 关键词频率分析
    final keywordScore = analyzeKeywordPresence(content, anchor);
    
    // 2. 语义相似度检测 (可选，使用轻量模型)
    final semanticScore = semanticSimilarity(content, anchor.core_theme);
    
    // 3. 禁忌主题检测
    final forbiddenHits = detectForbiddenThemes(content, anchor.forbidden_drifts);
    
    return DriftReport(
      overallScore: calculateCompositeScore(keywordScore, semanticScore),
      forbiddenDetected: forbiddenHits.isNotEmpty,
      recommendations: generateRecommendations(anchor),
    );
  }
}
```

#### L3: Mnemosyne 层 - 主题熵监控

长期趋势追踪:

```yaml
thematic_entropy:
  window_size: 20                 # 滑动窗口大小（轮次）
  
  history:
    - window: [1, 20]
      theme_alignment: 0.82       # 主题吻合度
      dominant_sub_themes: ["guilt_vs_duty"]
      
    - window: [21, 40]
      theme_alignment: 0.45       # 偏离警告
      dominant_sub_themes: ["comedy_focus"]  # 禁忌主题出现
      alert_triggered: true
```

### 5.3 偏离响应策略

| 偏离级别 | 检测指标 | 响应措施 |
|---------|---------|---------|
| 轻微 (0.6-0.8) | 关键词频率略低 | Prompt 注入主题提示词 |
| 中度 (0.3-0.6) | 语义偏离明显 | 插入主题回归事件 |
| 严重 (<0.3) | 触及禁忌主题 | 触发人工审核/重写 |

---

## 6. 整合架构

```
┌─────────────────────────────────────────────────────────────────┐
│                         Pattern (织谱)                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ emotional_   │  │ beat_        │  │ thematic_anchors     │  │
│  │ signature    │  │ templates    │  │ (core_theme, etc.)   │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└──────────────────────────────┬──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                       Jacquard (编排层)                          │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Planner                                                    │ │
│  │  ├── selectBeat(): 选择当前叙事节拍                        │ │
│  │  ├── calculateEmotionalTarget(): 计算情感目标              │ │
│  │  └── assemblePrompt(): 将元模型要求织入 Prompt             │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ Post-Processor                                             │ │
│  │  ├── detectBeatCompletion(): 检测节拍完成                  │ │
│  │  ├── checkThematicDrift(): 主题偏离检测                    │ │
│  │  └── triggerCorrection(): 触发矫正机制                     │ │
│  └────────────────────────────────────────────────────────────┘ │
└──────────────────────────────┬──────────────────────────────────┘
                               │
┌──────────────────────────────▼──────────────────────────────────┐
│                      Tapestry (织卷运行时)                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ beat_        │  │ emotional_   │  │ thematic_entropy     │  │
│  │ structure    │  │ trajectory   │  │ (长期趋势追踪)       │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. 实现路线图

### Phase 1: 基础框架 (低优先级)
- [ ] 定义 `emotional_signature` Schema
- [ ] 实现 Mnemosyne 情绪轨迹追踪
- [ ] 基础偏离检测逻辑

### Phase 2: 节拍系统 (低优先级)
- [ ] 定义标准 Beat 类型库
- [ ] 实现 Beat 状态机
- [ ] Filament 协议 `<beat_complete>` 扩展

### Phase 3: 主题防御 (低优先级)
- [ ] 关键词检测实现
- [ ] 语义相似度集成 (可选)
- [ ] 主题熵监控系统

---

## 8. 与现有系统的关系

| 现有组件 | 关联方式 |
|---------|---------|
| **Narrative Director** | 本系统关注"故事如何被讲述"，Director 关注"世界中发生了什么"。两者独立但互补。 |
| **VWD (变量系统)** | 情感弧线可利用 VWD 追踪角色关系变量 (`intimacy`, `trust` 等) 作为触发条件。 |
| **Filament 协议** | 需要扩展输出格式以支持 Beat 完成标记。 |
| **Jacquard Planner** | Planner 需要增加元模型感知能力，作为 Prompt 组装的新维度。 |

---

## 9. 参考对比

### vs LittleWhiteBox 故事大纲

| 维度 | LittleWhiteBox | Clotho 元模型 |
|------|---------------|---------------|
| **设计哲学** | 预设剧本导向 | 涌现式叙事框架 |
| **控制力** | 强约束 (大纲驱动) | 弱约束 (偏离检测) |
| **灵活性** | 需要提前规划 | 允许动态调整 |
| **LLM 角色** | 执行者 | 创造参与者 |

---

## 10. 附录

### A. 情感词汇表建议

```yaml
emotional_vocabulary:
  positive:
    high_energy: ["兴奋", "狂喜", "激昂"]
    low_energy: ["平静", "满足", "安心"]
  
  negative:
    high_energy: ["愤怒", "焦虑", "恐惧"]
    low_energy: ["悲伤", "沮丧", "厌倦"]
  
  complex:
    - " bittersweet "      # 苦乐参半
    - "nostalgic"          # 怀旧
    - "melancholic"        # 忧郁
```

### B. 主题分类参考

```yaml
theme_categories:
  - "redemption"           # 救赎
  - "coming_of_age"        # 成长
  - "love_and_loss"        # 爱与失去
  - "power_and_corruption" # 权力与腐蚀
  - "identity"             # 身份认同
  - "survival"             # 生存
  - "justice"              # 正义
```

---

*本文档为草案阶段，具体实现需根据后续优先级调整。*
