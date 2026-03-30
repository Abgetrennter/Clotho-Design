# Clotho AI Agents Context & Navigation Map (Mission Control)

This file serves as the **Supreme Navigation Hub** and **Directive Manual** for all AI agents (Cline, Roo, Cursor, Claude, etc.) operating within the Clotho project.

**BEFORE YOU WRITE ANY CODE OR PROPOSE ANY ARCHITECTURE, YOU MUST READ AND COMPLY WITH THIS DOCUMENT.**

---

## 1. 🌟 The North Star: Single Source of Truth (SSOT)

- **`00_active_specs/` is the absolute SSOT.**
- Do not hallucinate or guess implementation details, architecture, or data structures. If you are unsure, **STOP** and read the corresponding files in `00_active_specs/`.
- Legacy references (e.g., `10_references/`, `99_archive/`) are for historical context only and must never override `00_active_specs/`.

---

## 2. 🛡️ The Prime Directives (AI Behavior Rules)

When generating code or proposing solutions, you MUST pass these self-checks:

1.  **The Caesar Principle Check**:
    *   *Question*: "Am I putting business logic/math/state management into an LLM prompt?"
    *   *Rule*: **NEVER**. Deterministic logic belongs to Code (Jacquard/Mnemosyne). LLMs are strictly for semantic understanding, roleplay, and creative text generation.
2.  **The Filament Protocol Check**:
    *   *Question*: "How am I structuring data sent to or received from the LLM?"
    *   *Rule*: You MUST use the **Filament Protocol** (`XML+YAML` for input, `XML+JSON` for output). Do not invent custom markdown or JSON-only formats. See [`00_active_specs/protocols/filament-protocol-overview.md`](00_active_specs/protocols/filament-protocol-overview.md).
3.  **The Uni-Directional Data Flow Check**:
    *   *Question*: "Is the UI directly modifying the Mnemosyne database or state tree?"
    *   *Rule*: **NEVER**. The Presentation Layer (UI) is read-only. It must dispatch `Intents` via `JacquardUIAdapter` or ClothoNexus. State is uniquely managed by Mnemosyne. See [`00_active_specs/protocols/interface-definitions.md`](00_active_specs/protocols/interface-definitions.md).

---

## 3. 🗺️ Mission Control (Context Graph)

Before starting a task, identify your domain and **load the required context path** into your memory.

### Domain A: Orchestration & Logic (Jacquard / The Loom)
*   **Tasks**: Building Prompt pipelines, creating plugins (Shuttles), handling LLM requests.
*   **Required Context Path**:
    1.  [`00_active_specs/jacquard/README.md`](00_active_specs/jacquard/README.md) (Core Loom Architecture)
    2.  [`00_active_specs/jacquard/plugin-architecture.md`](00_active_specs/jacquard/plugin-architecture.md) (If writing a plugin)
    3.  [`00_active_specs/protocols/interface-definitions.md`](00_active_specs/protocols/interface-definitions.md) (Interface Contracts)

### Domain B: Data & State Management (Mnemosyne / The Memory)
*   **Tasks**: Modifying database schemas, managing Context/Threads, state patching, snapshots.
*   **Required Context Path**:
    1.  [`00_active_specs/mnemosyne/README.md`](00_active_specs/mnemosyne/README.md) (Core Data Engine Architecture)
    2.  [`00_active_specs/mnemosyne/sqlite-architecture.md`](00_active_specs/mnemosyne/sqlite-architecture.md) (Physical Schema)
    3.  [`00_active_specs/mnemosyne/abstract-data-structures.md`](00_active_specs/mnemosyne/abstract-data-structures.md) (In-Memory State)

### Domain C: UI & Presentation (The Stage)
*   **Tasks**: Building Flutter widgets, parsing SDUI, rendering Markdown, handling user interactions.
*   **Required Context Path**:
    1.  [`00_active_specs/presentation/README.md`](00_active_specs/presentation/README.md) (UI Principles: No Business Logic)
    2.  [`00_active_specs/presentation/clotho-nexus-integration.md`](00_active_specs/presentation/clotho-nexus-integration.md) (Event listening)
    3.  [`00_active_specs/protocols/interface-definitions.md`](00_active_specs/protocols/interface-definitions.md) -> Check `JacquardUIAdapter`

---

## 4. 🔤 The Rosetta Stone (Terminology Bridge)

Clotho uses a dual-terminology system.
- Use **Metaphor** terms when writing/updating *Architecture Documents*.
- Use **Technical** terms when writing *Code, Class Names, or Variables*.
- **NEVER** use legacy terms like "Character Card" or "Chat History".

| Metaphor (Architecture) | Technical (Code) | Legacy (DO NOT USE) | Definition |
| :--- | :--- | :--- | :--- |
| **Tapestry** (织卷) | `Session` | Chat / Save | The complete runtime instance. |
| **Pattern** (织谱) | `Persona` | Character Card | Static read-only definition blueprint. |
| **Threads** (丝络) | `Context` / `State` | Message History | Dynamic, read-write state and history. |
| **Punchcards** (穿孔卡)| `Snapshot` | Save File | Serialized static slice of the Tapestry. |
| **Skein** (绞纱) | `PromptBundle` | Prompt Array | Structured container for Prompt assembly. |
| **Lore / Texture** | `Worldbook` | World Info | Background knowledge base. |
| **Shuttle** (梭子) | `Plugin` | Extension | Execution module in Jacquard pipeline. |

*Full Definitions:*
- [`00_active_specs/metaphor-glossary.md`](00_active_specs/metaphor-glossary.md)
- [`00_active_specs/naming-convention.md`](00_active_specs/naming-convention.md) (Strict naming rules for code)

---

## 5. 🛠️ Daily Operations & Commands

The active codebase is primarily located in `08_demo/` (Flutter UI Prototype).

```bash
# General Setup
cd 08_demo && flutter pub get

# Run the App (Web is preferred for fast iteration)
cd 08_demo && flutter run -d chrome

# Code Quality (Run these before attempting completion)
cd 08_demo && flutter test
cd 08_demo && flutter analyze
```

## 6. 📝 Documentation Standards
When asked to update or create documentation, you MUST adhere to the standards defined in:
[`00_active_specs/reference/documentation_standards.md`](00_active_specs/reference/documentation_standards.md).