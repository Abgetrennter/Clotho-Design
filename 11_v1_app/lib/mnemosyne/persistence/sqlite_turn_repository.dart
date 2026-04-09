import 'dart:convert';

import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../domain/active_state.dart';
import '../domain/message.dart';
import '../domain/state_operation.dart';
import '../domain/turn.dart';
import '../domain/turn_commit.dart';
import '../domain/turn_commit_result.dart';
import '../repositories/turn_repository.dart';
import 'sqlite_database.dart';

class SqliteTurnRepository implements TurnRepository {
  SqliteTurnRepository(this._database);

  final SqliteDatabase _database;
  int _turnIdCounter = 0;
  int _messageIdCounter = 0;

  @override
  Future<TurnCommitResult> commitTurn(TurnCommitRequest request) async {
    final now = DateTime.now();

    return _database.transaction((db) {
      final nextTurnIndex = _readNextTurnIndex(db, request.sessionId);
      final turn = Turn(
        id: _createTurnId(now),
        sessionId: request.sessionId,
        index: nextTurnIndex,
        createdAt: now,
        summary: request.summary,
      );

      db.execute(
        '''
        INSERT INTO turns (
          id,
          session_id,
          turn_index,
          created_at,
          summary
        ) VALUES (?, ?, ?, ?, ?)
        ''',
        [
          turn.id,
          turn.sessionId,
          turn.index,
          turn.createdAt.millisecondsSinceEpoch,
          turn.summary,
        ],
      );

      final messages = <Message>[
        for (final draft in request.messages)
          Message(
            id: _createMessageId(turn.id),
            turnId: turn.id,
            role: draft.role,
            content: draft.content,
            type: draft.type,
            meta: draft.meta,
          ),
      ];

      for (final message in messages) {
        db.execute(
          '''
          INSERT INTO messages (
            id,
            turn_id,
            role,
            content,
            msg_type,
            is_active,
            meta_json
          ) VALUES (?, ?, ?, ?, ?, ?, ?)
          ''',
          [
            message.id,
            message.turnId,
            _encodeMessageRole(message.role),
            message.content,
            _encodeMessageType(message.type),
            message.isActive ? 1 : 0,
            jsonEncode(message.meta),
          ],
        );
      }

      for (final operation in request.stateOperations) {
        db.execute(
          '''
          INSERT INTO state_oplogs (
            turn_id,
            op,
            path,
            value_json,
            reason
          ) VALUES (?, ?, ?, ?, ?)
          ''',
          [
            turn.id,
            _encodeStateOperationType(operation.type),
            operation.path,
            operation.value == null ? null : jsonEncode(operation.value),
            operation.reason,
          ],
        );
      }

      final activeState = ActiveState(
        sessionId: request.sessionId,
        turnId: turn.id,
        state: request.activeState,
        updatedAt: now,
      );

      db.execute(
        '''
        INSERT INTO active_states (
          session_id,
          turn_id,
          state_json,
          updated_at
        ) VALUES (?, ?, ?, ?)
        ON CONFLICT(session_id) DO UPDATE SET
          turn_id = excluded.turn_id,
          state_json = excluded.state_json,
          updated_at = excluded.updated_at
        ''',
        [
          activeState.sessionId,
          activeState.turnId,
          jsonEncode(activeState.state),
          activeState.updatedAt.millisecondsSinceEpoch,
        ],
      );

      db.execute(
        '''
        UPDATE sessions
        SET updated_at = ?
        WHERE id = ?
        ''',
        [
          now.millisecondsSinceEpoch,
          request.sessionId,
        ],
      );

      return TurnCommitResult(
        turn: turn,
        messages: messages,
        activeState: activeState,
      );
    });
  }

  @override
  Future<ActiveState?> getActiveState(String sessionId) async {
    final result = _database.rawDatabase.select(
      '''
      SELECT
        session_id,
        turn_id,
        state_json,
        updated_at
      FROM active_states
      WHERE session_id = ?
      LIMIT 1
      ''',
      [sessionId],
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first;
    return ActiveState(
      sessionId: row['session_id'] as String,
      turnId: row['turn_id'] as String,
      state: Map<String, Object?>.from(
        jsonDecode(row['state_json'] as String) as Map<String, dynamic>,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }

  @override
  Future<List<Message>> listMessagesForTurn(String turnId) async {
    final result = _database.rawDatabase.select(
      '''
      SELECT
        id,
        turn_id,
        role,
        content,
        msg_type,
        is_active,
        meta_json
      FROM messages
      WHERE turn_id = ?
      ORDER BY rowid ASC
      ''',
      [turnId],
    );

    return result.map(_mapMessage).toList(growable: false);
  }

  @override
  Future<List<Turn>> listTurnsForSession(String sessionId) async {
    final result = _database.rawDatabase.select(
      '''
      SELECT
        id,
        session_id,
        turn_index,
        created_at,
        summary
      FROM turns
      WHERE session_id = ?
      ORDER BY turn_index ASC
      ''',
      [sessionId],
    );

    return result.map(_mapTurn).toList(growable: false);
  }

  Message _mapMessage(sqlite3.Row row) {
    final metaJson = row['meta_json'] as String? ?? '{}';
    return Message(
      id: row['id'] as String,
      turnId: row['turn_id'] as String,
      role: _decodeMessageRole(row['role'] as String),
      content: row['content'] as String,
      type: _decodeMessageType(row['msg_type'] as String),
      isActive: (row['is_active'] as int) == 1,
      meta: Map<String, Object?>.from(
        jsonDecode(metaJson) as Map<String, dynamic>,
      ),
    );
  }

  Turn _mapTurn(sqlite3.Row row) {
    return Turn(
      id: row['id'] as String,
      sessionId: row['session_id'] as String,
      index: row['turn_index'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      summary: row['summary'] as String?,
    );
  }

  String _createMessageId(String turnId) {
    _messageIdCounter += 1;
    return 'message_${turnId}_$_messageIdCounter';
  }

  String _createTurnId(DateTime timestamp) {
    _turnIdCounter += 1;
    return 'turn_${timestamp.microsecondsSinceEpoch}_$_turnIdCounter';
  }

  String _encodeMessageRole(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
    }
  }

  String _encodeMessageType(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.thought:
        return 'thought';
      case MessageType.command:
        return 'command';
    }
  }

  MessageRole _decodeMessageRole(String role) {
    switch (role) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
    }

    throw StateError('Unsupported message role: $role');
  }

  MessageType _decodeMessageType(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'thought':
        return MessageType.thought;
      case 'command':
        return MessageType.command;
    }

    throw StateError('Unsupported message type: $type');
  }

  String _encodeStateOperationType(StateOperationType type) {
    switch (type) {
      case StateOperationType.add:
        return 'add';
      case StateOperationType.replace:
        return 'replace';
      case StateOperationType.remove:
        return 'remove';
    }
  }

  int _readNextTurnIndex(sqlite3.Database db, String sessionId) {
    final result = db.select(
      '''
      SELECT COALESCE(MAX(turn_index), 0) AS max_turn_index
      FROM turns
      WHERE session_id = ?
      ''',
      [sessionId],
    );

    final maxTurnIndex = result.first['max_turn_index'] as int;
    return maxTurnIndex + 1;
  }
}
