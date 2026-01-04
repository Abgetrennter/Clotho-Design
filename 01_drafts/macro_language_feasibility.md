# Macro Language Feasibility Analysis

## 1. Executive Summary
This document analyzes the feasibility of replacing the current XML-based Filament logic control (e.g., `<if>`) with a macro-based meta-programming language.
We compare two primary approaches: **Template Engines (Jinja2/Liquid)** vs. **Embedded Scripting Languages (Lua/Rhai)**.

**Recommendation:** Adopt **Jinja2 (via `jinja` Dart package)** as the primary macro system for Prompt Assembly, while reserving **Lua (via `lua_dardo`)** for complex, sandbox-isolated plugin logic if needed in the future.

## 2. Requirements Analysis
The user requires "simple programming capabilities" to replace XML logic control.
Key requirements:
*   **Logic Control**: conditionals (`if/else`), loops (`for`), variable assignment (`set`).
*   **Safety**: Prevent infinite loops, file system access, and malicious code execution.
*   **Readability**: Easier to write/read than verbose XML tags.
*   **Integration**: Must work within the `Jacquard Pipeline` (Dart/Flutter environment).

## 3. Option 1: Template Engines (Jinja2/Liquid)

### 3.1 Overview
Template engines are designed specifically for text generation with embedded logic. They are "logic-less" or "logic-limited" by design, forcing a separation of concerns.

*   **Dart Implementation**: `jinja` package (Python Jinja2 port).
*   **Syntax**: `{{ variable }}`, `{% if condition %} ... {% endif %}`.

### 3.2 Pros
*   **Safety by Design**: Cannot access file system or arbitrary system calls. Limited to the context provided (Skein state).
*   **Readability**: concise and familiar syntax for text interpolation.
*   **Performance**: Parsing is generally fast; AST is simple.
*   **Caesar Principle Alignment**: Naturally restricts complex logic (Business Logic) from leaking into the Presentation/Prompt layer.

### 3.3 Cons
*   **Limited Power**: Cannot define complex functions or algorithms easily within the template.
*   **Dart Ecosystem**: The `jinja` package is community-maintained, though stable.

### 3.4 Feature Mapping
| XML Feature | Jinja2 Equivalent |
| :--- | :--- |
| `<if condition="...">` | `{% if condition %} ... {% endif %}` |
| `<foreach>` | `{% for item in list %} ... {% endfor %}` |
| `<let name="x">` | `{% set x = ... %}` |
| `{{state.hp}}` | `{{ state.hp }}` |

## 4. Option 2: Embedded Scripting (Lua/Rhai)

### 4.1 Overview
Full Turing-complete scripting languages embedded into the host application.

*   **Dart Implementation**: `lua_dardo` (Lua 5.3 VM in pure Dart).
*   **Syntax**: `if condition then ... end`.

### 4.2 Pros
*   **Maximum Power**: Full programming capabilities (functions, closures, complex math).
*   **Extensibility**: Users can write complex plugins/mods directly in the macro system.

### 4.3 Cons
*   **Security Risk**: Requires strict sandboxing. `lua_dardo` allows removing standard libraries (OS, IO), but "DoS via infinite loop" is harder to prevent without instruction counting.
*   **Complexity**: Overkill for simple prompt conditional logic.
*   **Performance**: Interpreting a VM is heavier than a template AST walk.

## 5. Architectural Impact (Jacquard Pipeline)

### 5.1 Current Flow
`SkeinBuilder` -> `PromptASTExecutor` (XML Parsing) -> `MacroResolver` -> `String`

### 5.2 Proposed Flow (Jinja2)
`SkeinBuilder` -> **`TemplateRenderer` (Jinja)** -> `String`

*   **Simplification**: The `PromptASTExecutor` and `MacroResolver` merge into a single `TemplateRenderer` step.
*   **State Injection**: The `Mnemosyne` state snapshot is passed as the `context` dictionary to the Jinja template.

## 6. Safety & Sandboxing Strategy (Crucial)

### 6.1 For Template Engines
*   **Context Isolation**: Only pass the `Skein` and `Mnemosyne` snapshot. No `dart:io` or `Process` objects.
*   **Resource Limits**: Implement a timeout or token limit for the rendering process to prevent ReDoS (Regex Denial of Service) or heavy loops.

### 6.2 For Scripting (if adopted)
*   **Instruction Counting**: Lua debug hooks to throw error after N instructions.
*   **Environment Stripping**: Remove `io`, `os`, `package` modules.

## 7. Migration Strategy
*   **Phase 1**: Introduce `TemplateRenderer` alongside XML parser.
*   **Phase 2**: Convert core prompts to Jinja2 syntax.
*   **Phase 3**: Deprecate XML logic tags.

## 8. Conclusion
For the specific goal of "replacing XML for logic control in Filament", **Jinja2 is the superior choice**. It balances power with safety and readability. Lua is better reserved for a separate "Plugin System" layer (Action logic), not Prompt Templating.
