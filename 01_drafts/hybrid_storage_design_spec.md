# Mnemosyne Hybrid Storage Design Specification

## 1. Overview
This document outlines the Hybrid Storage architecture for Mnemosyne, combining **SQLite** for structured data with **FileSystem** for static resources (images, audio, large text blobs). This approach ensures database performance while managing large assets efficiently.

## 2. Directory Structure (File System)

All paths are relative to the application's **Data Root** (e.g., `ApplicationDocumentsDirectory/clotho_data/` on mobile/desktop).

```text
clotho_data/
├── characters/             # Character-specific assets
│   └── {char_uuid}/
│       ├── card.json       # Original metadata (V2/V3 card)
│       ├── avatar.png      # Primary avatar
│       ├── portrait.png    # Full body portrait (optional)
│       └── assets/         # Additional assets referenced by the card
│           ├── emotion_happy.png
│           └── bg_office.jpg
├── worlds/                 # World/Lorebook assets
│   └── {world_uuid}/
│       ├── cover.jpg
│       └── map_v1.png
├── sessions/               # Session-generated content
│   └── {session_uuid}/
│       ├── generated/      # AI-generated images/audio
│       │   └── gen_001.png
│       └── logs/           # (Optional) Text logs backup
├── system/                 # System defaults
│   ├── default_avatar.png
│   └── default_bg.jpg
└── cache/                  # Temporary files (safe to clear)
    └── thumbnails/
```

## 3. URI Protocol (`asset://`)

To reference these files within the database (SQLite) and the UI, we use a unified URI scheme. This abstracts the physical file path, allowing the data directory to move without breaking links.

**Format**: `asset://{domain}/{id}/{path}`

| Domain | ID | Path | Example |
| :--- | :--- | :--- | :--- |
| `characters` | `{char_uuid}` | Relative path inside char folder | `asset://characters/123-abc/avatar.png` |
| `worlds` | `{world_uuid}` | Relative path inside world folder | `asset://worlds/456-def/cover.jpg` |
| `sessions` | `{session_uuid}` | Relative path inside session folder | `asset://sessions/789-ghi/generated/img1.png` |
| `system` | `default` | Relative path inside system folder | `asset://system/default/user_avatar.png` |

## 4. Resource Registry (SQLite)

While the FileSystem stores the actual bytes, SQLite maintains the **Truth** about resource existence and metadata.

### 4.1 New Table: `resources`

```sql
CREATE TABLE resources (
    uri TEXT PRIMARY KEY,          -- asset://...
    
    -- Physical Storage Metadata
    file_path TEXT NOT NULL,       -- Relative path from Data Root (e.g., "characters/123/avatar.png")
    mime_type TEXT,                -- e.g., "image/png", "audio/mpeg"
    file_size INTEGER,             -- Bytes
    file_hash TEXT,                -- SHA-256 for integrity check
    
    -- Management
    created_at INTEGER NOT NULL,
    last_accessed_at INTEGER,
    ref_count INTEGER DEFAULT 0    -- For Garbage Collection (optional)
);

CREATE INDEX idx_resources_hash ON resources(file_hash);
```

## 5. Integration Logic

### 5.1 Resolution Process
1.  UI requests `asset://characters/A/avatar.png`.
2.  **Mnemosyne Resource Manager** intercepts the request.
3.  (Optional) Check `resources` table for metadata/existence.
4.  Resolve to physical path: `$DATA_ROOT + /characters/A/avatar.png`.
5.  Return file stream to UI (Flutter).

### 5.2 Import Workflow
1.  User imports a Character Card (`.png` with embedded metadata).
2.  System extracts metadata -> SQLite (`state_snapshots`, etc.).
3.  System saves image -> FileSystem (`clotho_data/characters/{uuid}/avatar.png`).
4.  System registers URI -> SQLite (`resources` table).
5.  System updates Character State to use URI: `{"avatar": "asset://characters/{uuid}/avatar.png"}`.
