---
name: clotho-architecture-navigator
description: Navigate and query Clotho architecture documents in 00_active_specs/, including subsystems (Jacquard/Mnemosyne/Presentation/Muse), protocols, workflows, and runtime layers. Use when exploring project architecture or locating specific design specifications.
---

# Clotho 架构文档导航 (Clotho Architecture Navigator)

## When to use this skill

Use this skill when:
- User asks about project architecture, components, or design decisions
- Need to locate specific subsystem documentation (Jacquard, Mnemosyne, Presentation, Muse)
- User wants to understand data flow, protocols, or runtime behavior
- Exploring the `00_active_specs/` directory for design specifications
- Answering questions about layered architecture (L0-L3)

## When NOT to use this skill

Do NOT use this skill when:
- Writing or modifying code (use Code mode with appropriate coding skills)
- Creating new documentation (use `clotho-documentation-author` skill)
- Working on external reference materials in `10_references/` or `99_archive/`
- User asks about implementation details not covered in design documents

## Inputs required from the user

- The topic or component they want to understand (e.g., "Jacquard Pipeline", "Mnemosyne data model")
- Optional: Specific question about architecture relationships or data flow

## Document Structure Overview

The `00_active_specs/` directory is organized into 6 main categories:

```
00_active_specs/
├── Overview (愿景与哲学、架构原则、术语表)
├── Subsystems (Jacquard/Mnemosyne/Presentation/Muse)
├── Protocols (Filament 协议、输入输出格式、宏系统)
├── Workflows (提示词处理、角色卡导入、迁移指南)
├── Runtime (分层运行时架构、状态管理)
└── Reference (文档标准、ACU 架构分析、宏参考)
```

## Workflow

### 1. Identify the query category

Determine which category the user's question falls into:

| Category | When to use | Key files |
|----------|-------------|-----------|
| **Overview** | High-level concepts, design philosophy, terminology | [`vision-and-philosophy.md`](00_active_specs/vision-and-philosophy.md), [`architecture-principles.md`](00_active_specs/architecture-principles.md), [`metaphor-glossary.md`](00_active_specs/metaphor-glossary.md) |
| **Jacquard** | Orchestration, Pipeline, Plugins, Planning | [`jacquard/README.md`](00_active_specs/jacquard/README.md), [`planner-component.md`](00_active_specs/jacquard/planner-component.md), [`plugin-architecture.md`](00_active_specs/jacquard/plugin-architecture.md) |
| **Mnemosyne** | Data engine, State management, Storage | [`mnemosyne/README.md`](00_active_specs/mnemosyne/README.md), [`sqlite-architecture.md`](00_active_specs/mnemosyne/sqlite-architecture.md), [`abstract-data-structures.md`](00_active_specs/mnemosyne/abstract-data-structures.md) |
| **Presentation** | UI/UX, Flutter, Hybrid SDUI | [`presentation/README.md`](00_active_specs/presentation/README.md), [`state-sync-events.md`](00_active_specs/presentation/state-sync-events.md) |
| **Muse** | LLM Gateway, Agent hosting | [`muse/README.md`](00_active_specs/muse/README.md), [`muse-router-config.md`](00_active_specs/muse/muse-router-config.md) |
| **Protocols** | Filament protocol, Input/Output formats | [`protocols/filament-protocol-overview.md`](00_active_specs/protocols/filament-protocol-overview.md), [`filament-input-format.md`](00_active_specs/protocols/filament-input-format.md), [`filament-output-format.md`](00_active_specs/protocols/filament-output-format.md) |
| **Workflows** | Business processes, Migration | [`workflows/prompt-processing.md`](00_active_specs/workflows/prompt-processing.md), [`workflows/character-import-migration.md`](00_active_specs/workflows/character-import-migration.md) |
| **Runtime** | Layered architecture, State patching | [`runtime/layered-runtime-architecture.md`](00_active_specs/runtime/layered-runtime-architecture.md) |
| **Reference** | Standards, Analysis, Legacy | [`reference/documentation_standards.md`](00_active_specs/reference/documentation_standards.md), [`reference/architecture-audit-report.md`](00_active_specs/reference/architecture-audit-report.md) |

### 2. Navigate to the relevant document

Read the identified document using the `read_file` tool. If the document is large:
- Start with the overview section (first 100 lines)
- Use the table of contents to find specific sections
- Read only the sections relevant to the user's query

### 3. Cross-reference related documents

If the query involves multiple subsystems:
- Check the "Related Documents" or "See Also" sections
- Follow cross-references to understand the full picture
- Example: Understanding Filament protocol requires reading both the protocol overview and the parsing workflow

### 4. Provide structured answer

When answering architecture questions:
1. **State the component's purpose** (1 sentence)
2. **Explain its position in the architecture** (which layer, what it connects to)
3. **Describe key behaviors or data structures** (as documented)
4. **Link to related documents** for further reading

## Key Architecture Concepts

### Layered Runtime Architecture (L0-L3)

| Layer | Metaphor | Name | Read/Write |
|-------|----------|------|------------|
| L0 | 骨架 | Infrastructure | Read-Only |
| L1 | 环境 | Environment | Read-Only |
| L2 | 织谱 | The Pattern | Read-Only |
| L3 | 丝络 | The Threads | **Read-Write** |

### Core Subsystems

- **Jacquard (编排层)**: Pipeline Runner, orchestrates plugins for prompt assembly, LLM invocation, and result parsing
- **Mnemosyne (数据引擎)**: Dynamic context generation engine, manages long-term memory and instantaneous state
- **Presentation (表现层)**: Flutter-based UI with Hybrid SDUI (RFW native + WebView fallback)
- **Muse (智能服务)**: LLM Gateway and Agent hosting

### Terminology Mapping

Use terms from [`metaphor-glossary.md`](00_active_specs/metaphor-glossary.md):

| Use (Clotho) | Avoid (Legacy) |
|--------------|----------------|
| Pattern / 织谱 | Character Card |
| Tapestry / 织卷 | Chat / Session |
| Threads / 丝络 | Message History |
| Lore / Texture | World Info |
| Punchcards | Snapshot |

## Troubleshooting

### Document not found
- Check if the document is in `99_archive/` (deprecated)
- Check if the document is in `01_drafts/` or `02_active_plans/` (work in progress)
- Use `00_active_specs/README.md` as the index to find the correct path

### Conflicting information
- Refer to [`reference/architecture-audit-report.md`](00_active_specs/reference/architecture-audit-report.md) for known inconsistencies
- Prefer documents with status "Active" over "Draft"
- Check the document version and date

### Need implementation details
- Design documents in `00_active_specs/` describe the "what" and "why", not the "how"
- For implementation, check `08_demo/` for Flutter demo code
- For detailed analysis, check `10_references/` for third-party framework analysis
