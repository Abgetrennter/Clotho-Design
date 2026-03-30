---
name: clotho-documentation-author
description: Ensure all Clotho project documents comply with documentation standards including SSOT principle, textile metaphor terminology, formatting rules, and AI review checklist. Use when creating or updating documents in 00_active_specs/ or related documentation.
---

# Clotho 文档撰写规范 (Clotho Documentation Author)

## When to use this skill

Use this skill when:
- Creating new documentation files in `00_active_specs/`
- Updating existing Clotho architecture documents
- Writing design specifications, workflow documents, or protocol definitions
- Reviewing documentation for compliance with project standards
- Converting legacy documentation to Clotho standards

## When NOT to use this skill

Do NOT use this skill when:
- Writing code comments or inline documentation (use normal coding conventions)
- Creating user-facing UI text or help strings
- Writing README files outside the `00_active_specs/` directory
- Working on external reference materials in `10_references/`

## Inputs required from the user

- The document type (Overview, Subsystem, Protocol, Workflow, Runtime, or Reference)
- The target file path within `00_active_specs/`
- The content to be documented (architecture decisions, workflows, specifications, etc.)
- Optional: Related documents for cross-referencing

## Workflow

### 1. Verify document placement

1. Determine the document category based on content:
   - **Overview**: `00_active_specs/` root (vision, principles, glossary)
   - **Subsystems**: `00_active_specs/{subsystem}/` (jacquard, mnemosyne, presentation, muse)
   - **Protocols**: `00_active_specs/protocols/`
   - **Workflows**: `00_active_specs/workflows/`
   - **Runtime**: `00_active_specs/runtime/`
   - **Reference**: `00_active_specs/reference/`

2. Confirm the target file path is correct for the category.

### 2. Apply document header metadata

Every document MUST include YAML-style frontmatter at the top:

```markdown
# 文档标题
**版本**: x.x.x
**日期**: YYYY-MM-DD
**状态**: Draft/Active/Deprecated
```

### 3. Ensure terminology consistency

Use Clotho textile metaphor terms as defined in [`00_active_specs/metaphor-glossary.md`](../00_active_specs/metaphor-glossary.md):

| New Term (Use) | Legacy Term (Avoid) |
|----------------|-------------------|
| Clotho | - |
| Jacquard | Orchestration Layer |
| Mnemosyne | Data Engine |
| The Pattern / 织谱 | Character Card |
| The Tapestry / 织卷 | Chat / Session |
| Threads / 丝络 | Message History |
| Lore / Texture | World Info |
| Punchcards | Snapshot |

**Prohibited**: Do not use "SillyTavern", "Character Card", "Chat History" to describe new architecture (except when mapping legacy concepts).

### 4. Verify language and tone

- **Language**: Simplified Chinese (zh-CN) by default
- **Proper nouns**: Use "中文 (English)" format on first occurrence, then maintain consistency
- **Tone**: Professional and Direct
  - ❌ "太棒了！下面我为您展示如何配置..."
  - ✅ "配置步骤如下..."

### 5. Apply formatting rules

- Use standard Markdown headings (`#`, `##`, `###`)
- Specify language for all code blocks (````typescript`, ````xml`, ````mermaid`)
- Use relative paths for all cross-document links
- Avoid double quotes `""` or parentheses `()` inside `[]` in Mermaid diagrams

### 6. Execute AI review checklist

Before finalizing any document change, verify:

- [ ] **SSOT 检查**: Content does not conflict with `00_active_specs/` specifications
- [ ] **重复性检查**: Content is not duplicated elsewhere; use references instead
- [ ] **链接有效性**: All `[Link](path)` relative paths exist and are correct
- [ ] **术语一致性**: Uses standard terms (Pattern, Tapestry, Jacquard, etc.)
- [ ] **目录位置**: File is in the correct subdirectory
- [ ] **语调检查**: Removed conversational fillers like "Great", "Sure"

### 7. Add document associations

Include a "关联文档" (Related Documents) section when applicable:

```markdown
**关联文档**:
- [Document Name](../path/to/document.md) - Brief description
- [Document Name](../path/to/document.md) - Brief description
```

## Examples

### Example 1: Creating a new subsystem document

**Task**: Create a new Jacquard component specification

**Steps**:
1. Place file at `00_active_specs/jacquard/new-component.md`
2. Add frontmatter with version, date, and status
3. Use "Jacquard" not "Orchestration Layer"
4. Link to `00_active_specs/jacquard/README.md` in related documents
5. Run review checklist before completion

### Example 2: Updating an existing workflow

**Task**: Update prompt processing workflow

**Steps**:
1. Read existing `00_active_specs/workflows/prompt-processing.md`
2. Verify changes don't conflict with `00_active_specs/jacquard/README.md`
3. Update version number in frontmatter
4. Ensure all links still point to valid files
5. Confirm terminology uses "Skein", "Threads", "Tapestry"

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Unsure which directory to use | Check [`00_active_specs/README.md`](../00_active_specs/README.md) for directory structure overview |
| Conflicting terminology | Reference [`00_active_specs/metaphor-glossary.md`](../00_active_specs/metaphor-glossary.md) for the canonical term list |
| Link validation fails | Use `list_files` to verify the target file exists before creating the link |
| Content duplicates existing material | Search `00_active_specs/` for similar content and add a cross-reference instead |

## References

- **Documentation Standards**: [`00_active_specs/reference/documentation_standards.md`](../00_active_specs/reference/documentation_standards.md)
- **Metaphor Glossary**: [`00_active_specs/metaphor-glossary.md`](../00_active_specs/metaphor-glossary.md)
- **Architecture Index**: [`00_active_specs/README.md`](../00_active_specs/README.md)
