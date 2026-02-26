---
name: clotho-filament-protocol-author
description: Author and validate Filament protocol documents including input format (XML+YAML), output format (XML+JSON), Jinja2 macro system, and parsing workflow. Use when creating protocol specifications or LLM interaction documentation in 00_active_specs/protocols/.
---

# Filament 协议文档撰写 (Filament Protocol Author)

## When to use this skill

Use this skill when:
- Creating or modifying Filament protocol documentation in `00_active_specs/protocols/`
- Defining LLM input/output format specifications
- Writing Jinja2 macro templates or documentation
- Documenting prompt assembly and parsing workflows
- Validating protocol compliance for LLM interactions

## When NOT to use this skill

Do NOT use this skill when:
- Writing code comments or inline documentation
- Creating user-facing UI text or help strings
- Working on non-protocol documentation (use `clotho-documentation-author` skill)
- Defining internal component interfaces (use Dart/TypeScript directly)

## Inputs required from the user

- The protocol aspect to document (Input Format, Output Format, Macro System, Parsing Workflow)
- The specific use case or example to illustrate
- Optional: Related schema definitions or template examples

## Protocol Overview

**Filament 协议** is Clotho's native interaction language for LLM communication, designed to eliminate ambiguity between "natural language" and "machine instructions".

### Core Design Philosophy

| Aspect | Approach | Rationale |
|--------|----------|-----------|
| **Input** | XML + YAML | XML for structure, YAML for human-readable data (lower token count) |
| **Output** | XML + JSON | XML for intent tags, JSON for strict parameter parsing |
| **Extension** | Mixed Strategy | Core strictness + Edge flexibility |

### Protocol Scope

Filament applies **only at the LLM boundary**:
- **Prompt Assembly**: XML+YAML structured context injection
- **LLM Output Parsing**: XML+JSON response extraction
- **Tag Semantics**: Standardized intent tags (`<thought>`, `<content>`, `<variable_update>`)
- **Embedded UI**: LLM-requested native components via `<mini_app>` tags

> **Important**: Internal components (Jacquard, Mnemosyne, Presentation) use Dart objects directly, NOT Filament protocol.

## Workflow

### 1. Identify the document type

Determine which Filament specification to create or update:

| Document | Purpose | Key Content |
|----------|---------|-------------|
| [`filament-protocol-overview.md`](00_active_specs/protocols/filament-protocol-overview.md) | Protocol introduction | Design philosophy, version history, architecture relationships |
| [`filament-input-format.md`](00_active_specs/protocols/filament-input-format.md) | LLM input specification | Skein Blocks, YAML data format, context injection |
| [`filament-output-format.md`](00_active_specs/protocols/filament-output-format.md) | LLM output specification | Intent tags, JSON parameters, ESR registry |
| [`jinja2-macro-system.md`](00_active_specs/protocols/jinja2-macro-system.md) | Template engine | Macro syntax, security filters, inheritance |
| [`filament-parsing-workflow.md`](00_active_specs/protocols/filament-parsing-workflow.md) | Real-time parsing | Stream parsing, DFA correction, event dispatch |

### 2. Apply document structure

Every Filament protocol document MUST include:

```markdown
# Document Title

**Version**: x.x.x
**Date**: YYYY-MM-DD
**Status**: Draft/Active/Deprecated

---

## Protocol Positioning

Where does this protocol fit in the system architecture?

## Core Design Philosophy

Why was this design chosen? What trade-offs were made?

## Specification

The actual format/grammar/rules definition.

## Examples

Concrete, realistic examples showing the format in use.

## Validation Rules

How to verify compliance (schema, parser rules, etc.)

## Related Documents

Links to other protocol documents and subsystems.
```

### 3. Write Input Format specifications

For [`filament-input-format.md`](00_active_specs/protocols/filament-input-format.md):

```xml
<!-- Skein Block Structure -->
<skein_block type="pattern">
  <metadata>
    <pattern_id>char_001</pattern_id>
    <version>1.0</version>
  </metadata>
  <content yaml:space="preserve">
    name: 角色名称
    description: |
      角色背景描述
    personality_traits:
      - 特质 1
      - 特质 2
  </content>
</skein_block>

<skein_block type="threads">
  <thread id="msg_001" role="user">
    <content>用户消息内容</content>
    <timestamp>2026-02-26T14:00:00Z</timestamp>
  </thread>
  <thread id="msg_002" role="assistant">
    <content>助手回复内容</content>
    <state_update>
      {"op": "set", "path": "mood", "value": "happy"}
    </state_update>
  </thread>
</skein_block>
```


  