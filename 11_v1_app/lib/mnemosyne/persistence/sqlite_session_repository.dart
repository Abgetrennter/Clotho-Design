import 'dart:convert';

import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../domain/session.dart';
import '../repositories/session_repository.dart';
import 'sqlite_database.dart';

class SqliteSessionRepository implements SessionRepository {
  SqliteSessionRepository(this._database);

  final SqliteDatabase _database;
  int _sessionIdCounter = 0;

  @override
  Future<Session> createSession({
    required String title,
    required String activeCharacterId,
    Map<String, Object?> meta = const <String, Object?>{},
  }) async {
    final now = DateTime.now();
    final session = Session(
      id: _createSessionId(now),
      title: title,
      activeCharacterId: activeCharacterId,
      createdAt: now,
      updatedAt: now,
      meta: meta,
    );

    _database.rawDatabase.execute(
      '''
      INSERT INTO sessions (
        id,
        title,
        active_character_id,
        created_at,
        updated_at,
        meta_json
      ) VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        session.id,
        session.title,
        session.activeCharacterId,
        session.createdAt.millisecondsSinceEpoch,
        session.updatedAt.millisecondsSinceEpoch,
        jsonEncode(session.meta),
      ],
    );

    return session;
  }

  @override
  Future<void> deleteSession(String id) async {
    _database.rawDatabase.execute('DELETE FROM sessions WHERE id = ?', [id]);
  }

  @override
  Future<Session?> getSessionById(String id) async {
    final result = _database.rawDatabase.select(
      '''
      SELECT
        id,
        title,
        active_character_id,
        created_at,
        updated_at,
        meta_json
      FROM sessions
      WHERE id = ?
      LIMIT 1
      ''',
      [id],
    );

    if (result.isEmpty) {
      return null;
    }

    return _mapSession(result.first);
  }

  @override
  Future<List<Session>> listRecentSessions({int limit = 20}) async {
    final result = _database.rawDatabase.select(
      '''
      SELECT
        id,
        title,
        active_character_id,
        created_at,
        updated_at,
        meta_json
      FROM sessions
      ORDER BY updated_at DESC
      LIMIT ?
      ''',
      [limit],
    );

    return result.map(_mapSession).toList(growable: false);
  }

  @override
  Future<void> updateSession(Session session) async {
    _database.rawDatabase.execute(
      '''
      UPDATE sessions
      SET
        title = ?,
        active_character_id = ?,
        created_at = ?,
        updated_at = ?,
        meta_json = ?
      WHERE id = ?
      ''',
      [
        session.title,
        session.activeCharacterId,
        session.createdAt.millisecondsSinceEpoch,
        session.updatedAt.millisecondsSinceEpoch,
        jsonEncode(session.meta),
        session.id,
      ],
    );
  }

  Session _mapSession(sqlite3.Row row) {
    final metaJson = row['meta_json'] as String? ?? '{}';
    return Session(
      id: row['id'] as String,
      title: row['title'] as String,
      activeCharacterId: row['active_character_id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      meta: Map<String, Object?>.from(
        jsonDecode(metaJson) as Map<String, dynamic>,
      ),
    );
  }

  String _createSessionId(DateTime timestamp) {
    _sessionIdCounter += 1;
    return 'session_${timestamp.microsecondsSinceEpoch}_$_sessionIdCounter';
  }
}
