# AGENTS.md

This file provides guidance to agents when working with code in this repository.

## Project Overview

Clotho 是一个面向 AI 角色扮演（RPG）的 Flutter 客户端设计文档仓库。当前阶段主要是设计文档，`08_demo/` 包含可运行的 Flutter UI 演示。

## 核心规则

**SSOT**: `00_active_specs/` 是唯一权威文档源。回答架构/功能/数据结构问题前，**必须**先查阅该目录。

**术语**: 使用纺织隐喻体系（Pattern/Tapestry/Threads/Jacquard/Mnemosyne），禁止使用 "Character Card/Chat History" 等旧术语。详见 [`00_active_specs/metaphor-glossary.md`](00_active_specs/metaphor-glossary.md)。

**文档标准**: 创建/更新文档时必须遵循 [`00_active_specs/reference/documentation_standards.md`](00_active_specs/reference/documentation_standards.md)。

## 命令

```bash
# Flutter 演示应用 (08_demo/)
cd 08_demo && flutter pub get
cd 08_demo && flutter run -d chrome  # 运行 Web 版
cd 08_demo && flutter test          # 运行测试
cd 08_demo && flutter analyze       # 代码分析
```

## 架构速查

| 层级 | 名称 | 职责 |
|------|------|------|
| L0 | Infrastructure | 依赖注入、日志、事件总线 |
| L1 | Environment | 全局 Lore、User Persona |
| L2 | Pattern | 静态定义（原角色卡） |
| L3 | Threads | 动态状态（历史记录、变量） |

## 现有规则

- **Cline 规则**: [`.clinerules`](.clinerules) - 文档引用和目录映射
- **Roo 技能**: [`.roo/skills/clotho-documentation-author/SKILL.md`](.roo/skills/clotho-documentation-author/SKILL.md) - 文档标准验证

## 关键文档入口

1. [`00_active_specs/README.md`](00_active_specs/README.md) - 架构文档索引
2. [`00_active_specs/vision-and-philosophy.md`](00_active_specs/vision-and-philosophy.md) - 凯撒原则
3. [`00_active_specs/protocols/interface-definitions.md`](00_active_specs/protocols/interface-definitions.md) - 公共接口定义
