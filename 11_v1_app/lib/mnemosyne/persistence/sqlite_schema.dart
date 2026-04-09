class SqliteSchema {
  SqliteSchema._();

  static const List<String> v1Statements = [
    '''
    CREATE TABLE IF NOT EXISTS sessions (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      active_character_id TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      meta_json TEXT NOT NULL DEFAULT '{}'
    ) STRICT;
    ''',
    '''
    CREATE TABLE IF NOT EXISTS turns (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
      turn_index INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      summary TEXT,
      UNIQUE(session_id, turn_index)
    ) STRICT;
    ''',
    '''
    CREATE TABLE IF NOT EXISTS messages (
      id TEXT PRIMARY KEY,
      turn_id TEXT NOT NULL REFERENCES turns(id) ON DELETE CASCADE,
      role TEXT NOT NULL CHECK(role IN ('user', 'assistant', 'system')),
      content TEXT NOT NULL,
      msg_type TEXT NOT NULL DEFAULT 'text'
        CHECK(msg_type IN ('text', 'thought', 'command')),
      is_active INTEGER NOT NULL DEFAULT 1 CHECK(is_active IN (0, 1)),
      meta_json TEXT NOT NULL DEFAULT '{}'
    ) STRICT;
    ''',
    '''
    CREATE TABLE IF NOT EXISTS active_states (
      session_id TEXT PRIMARY KEY REFERENCES sessions(id) ON DELETE CASCADE,
      turn_id TEXT NOT NULL REFERENCES turns(id) ON DELETE CASCADE,
      state_json TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    ) STRICT;
    ''',
    '''
    CREATE TABLE IF NOT EXISTS state_oplogs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      turn_id TEXT NOT NULL REFERENCES turns(id) ON DELETE CASCADE,
      op TEXT NOT NULL CHECK(op IN ('add', 'replace', 'remove')),
      path TEXT NOT NULL,
      value_json TEXT,
      reason TEXT
    ) STRICT;
    ''',
    '''
    CREATE INDEX IF NOT EXISTS idx_turns_session_index
      ON turns(session_id, turn_index);
    ''',
    '''
    CREATE INDEX IF NOT EXISTS idx_messages_turn
      ON messages(turn_id);
    ''',
    '''
    CREATE INDEX IF NOT EXISTS idx_state_oplogs_turn
      ON state_oplogs(turn_id);
    ''',
  ];
}
