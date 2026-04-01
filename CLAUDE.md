# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Clotho** is a next-generation AI RPG client with a design-docs-first workflow. This repository (`design`) contains architecture specifications, design documents, reference materials, and Flutter-based prototypes/MVP implementations. The project follows a "specification drives implementation" philosophy — design docs in `00_active_specs/` are the source of truth.

## Repository Structure

- `00_active_specs/` — Active architecture specifications (source of truth). Organized by subsystem: `jacquard/`, `mnemosyne/`, `presentation/`, `muse/`, `protocols/`, `workflows/`, `runtime/`, `reference/`, `infrastructure/`
- `08_demo/` — Flutter UI demo (presentation layer only, Material 3 design system)
- `09_mvp/` — Flutter MVP with full layered architecture (Jacquard + Mnemosyne + Stage)
- `10_references/` — Third-party reference projects (agentskills, ERA, PeroCore-tauri, character-card-spec-v3). Read-only, not part of Clotho.
- `04_prototype/` — Prototype directory (gitkept, currently empty)

## Build & Development Commands

### 08_demo (Flutter UI Demo)
```bash
cd 08_demo
flutter pub get
flutter run -d chrome          # Web (recommended)
flutter run -d windows         # Desktop
flutter build web              # Production build
```

### 09_mvp (Flutter MVP)
```bash
cd 09_mvp
flutter pub get
flutter run -d chrome          # Web (recommended)
flutter run -d windows         # Desktop
flutter test                   # Run tests
flutter analyze                # Static analysis
```

Requires Flutter SDK >= 3.10.8, Dart SDK >= 3.0.0. LLM API key must be configured in `lib/stage/providers/chat_provider.dart`.

## Architecture

Clotho uses a **four-subsystem layered architecture** with strict physical isolation:

```
Stage (Presentation) → Domain (UseCases) → Jacquard (Orchestration) → Mnemosyne (Data)
```

### Key Subsystems

| Subsystem | Code Namespace | Responsibility |
|-----------|---------------|----------------|
| **Jacquard** | `jacquard/` | Orchestration engine: Prompt assembly (PromptBundle/Skein), LLM invocation, Filament protocol parsing |
| **Mnemosyne** | `mnemosyne/` | Data engine: SQLite storage, state management, snapshots, history (SSOT for all state) |
| **Stage** | `stage/` | Presentation layer: Flutter UI, widgets, screens. Must NOT contain business logic |
| **Muse** | `muse/` | AI service layer: LLM provider adapters, streaming, billing |

### Core Principles

- **Caesar Principle**: Code handles deterministic logic; LLMs handle semantics/creativity. Never mix responsibilities.
- **Filament Protocol**: Standardized LLM communication — "XML+YAML IN, XML+JSON OUT"
- **Unidirectional data flow**: UI generates Intents → Jacquard orchestrates → Mnemosyne is the state authority → Events flow back via ClothoNexus (event bus) → Riverpod updates UI
- **Three-layer state management**: L1 (Mnemosyne/SQLite persistence) → L2 (ClothoNexus event bus) → L3 (Riverpod UI projection)

## Terminology

Clotho uses a **dual terminology system**. Code must always use the **technical terms**, never the metaphor terms:

| Metaphor | Technical Term (use in code) | Concept |
|----------|------------------------------|---------|
| Tapestry | `Session` | Runtime conversation instance |
| Pattern | `Persona` | Character definition (static blueprint) |
| Threads | `Context` / `SessionContext` | Dynamic state + history |
| Punchcards | `Snapshot` | World state snapshot for serialization |
| Skein | `PromptBundle` | Structured prompt container |
| Shuttle | `Plugin` | Jacquard pipeline plugin |
| Lore | `Worldbook` | Background knowledge base |

Full mapping: `00_active_specs/naming-convention.md` and `00_active_specs/metaphor-glossary.md`

## Naming Conventions

- Dart `snake_case` for files, `PascalCase` for classes
- Code uses technical terms exclusively (e.g., `Session`, `Persona`, `PromptBundle` — not `Tapestry`, `Pattern`, `Skein`)
- Subsystem namespaces as directory prefixes: `jacquard/`, `mnemosyne/`, `stage/`, `muse/`, `core/`

## Key Specs to Consult

- Architecture principles: `00_active_specs/architecture-principles.md`
- Naming conventions: `00_active_specs/naming-convention.md`
- Filament protocol: `00_active_specs/protocols/filament-protocol-overview.md`
- State management: `00_active_specs/mnemosyne/`
- Prompt processing: `00_active_specs/jacquard/` and `00_active_specs/workflows/prompt-processing.md`

## Language

Documentation and specs are written in **Chinese (中文)**. Code identifiers and comments use English. UI-facing strings are in Chinese.
