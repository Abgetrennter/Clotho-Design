# Documentation Refactoring Plan: Core Sink & Overview Float

**Objective**: Eliminate "knowledge fragmentation" by organizing documentation by domain (e.g., `jacquard/`) rather than abstraction level (e.g., `core/`). Establish a flatter, more accessible directory structure.

## 1. Directory Structure Changes

### 1.1 New Directories to Create
- `00_active_specs/presentation/`
- `00_active_specs/infrastructure/`
- `00_active_specs/muse/`

### 1.2 Directories to Remove (After Move)
- `00_active_specs/core/`
- `00_active_specs/overview/`

## 2. File Moves & Renames

### 2.1 Sink Core Docs (To Subsystems)
| Source File | Destination | Rationale |
| :--- | :--- | :--- |
| `core/jacquard-orchestration.md` | `jacquard/README.md` | Becomes the SSOT index for Jacquard |
| `core/mnemosyne-data-engine.md` | `mnemosyne/README.md` | Becomes the SSOT index for Mnemosyne |
| `core/presentation-layer.md` | `presentation/README.md` | New domain root |
| `core/infrastructure-layer.md` | `infrastructure/README.md` | New domain root |
| `core/muse-intelligence-service.md` | `muse/README.md` | New domain root |
| `core/README.md` | *(Delete/Merge info to root)* | No longer needed |

### 2.2 Float Overview Docs (To Root)
| Source File | Destination | Rationale |
| :--- | :--- | :--- |
| `overview/vision-and-philosophy.md` | `vision-and-philosophy.md` | Core axiom |
| `overview/architecture-principles.md` | `architecture-principles.md` | Core axiom |
| `overview/metaphor-glossary.md` | `metaphor-glossary.md` | Global reference |
| `overview/architecture-panorama.md` | *(Merge into root README.md)* | Single map optimization |
| `overview/README.md` | *(Delete)* | No longer needed |

## 3. Link Updates Strategy
*Regex Search & Replace across `00_active_specs/`*

1.  **Jacquard Links**:
    - `../core/jacquard-orchestration.md` -> `../jacquard/README.md`
    - `core/jacquard-orchestration.md` -> `jacquard/README.md`

2.  **Mnemosyne Links**:
    - `../core/mnemosyne-data-engine.md` -> `../mnemosyne/README.md`
    - `core/mnemosyne-data-engine.md` -> `mnemosyne/README.md`

3.  **Presentation Links**:
    - `../core/presentation-layer.md` -> `../presentation/README.md`

4.  **Infrastructure Links**:
    - `../core/infrastructure-layer.md` -> `../infrastructure/README.md`

5.  **Overview Links**:
    - `../overview/vision-and-philosophy.md` -> `../vision-and-philosophy.md`
    - `overview/vision-and-philosophy.md` -> `vision-and-philosophy.md`
    - (Repeat for principles and glossary)

## 4. Execution Steps (Automated)

1.  Create new directories.
2.  Move files to new locations.
3.  Update root `README.md`:
    - Integrate `architecture-panorama.md` content (Directory Map).
    - Update navigation tree.
4.  Perform regex search/replace for link fixing.
5.  Delete empty `core` and `overview` directories.
6.  Verify `README.md` integrity.
