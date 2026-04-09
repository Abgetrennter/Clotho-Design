import 'package:clotho_v1_app/mnemosyne/domain/message.dart';
import 'package:clotho_v1_app/mnemosyne/domain/state_operation.dart';
import 'package:clotho_v1_app/mnemosyne/domain/turn_commit.dart';
import 'package:clotho_v1_app/mnemosyne/persistence/sqlite_database.dart';
import 'package:clotho_v1_app/mnemosyne/persistence/sqlite_session_repository.dart';
import 'package:clotho_v1_app/mnemosyne/persistence/sqlite_turn_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SqliteTurnRepository', () {
    late SqliteDatabase database;
    late SqliteSessionRepository sessionRepository;
    late SqliteTurnRepository turnRepository;

    setUp(() {
      database = SqliteDatabase.openInMemory();
      sessionRepository = SqliteSessionRepository(database);
      turnRepository = SqliteTurnRepository(database);
    });

    tearDown(() {
      database.close();
    });

    test('commits a turn with messages, active state, and oplogs', () async {
      final session = await sessionRepository.createSession(
        title: 'Demo Session',
        activeCharacterId: 'persona.seraphina',
      );

      final result = await turnRepository.commitTurn(
        TurnCommitRequest(
          sessionId: session.id,
          messages: const [
            DraftMessage(
              role: MessageRole.user,
              content: 'Hello there.',
            ),
            DraftMessage(
              role: MessageRole.assistant,
              content: 'Welcome back.',
            ),
            DraftMessage(
              role: MessageRole.assistant,
              content: 'Thinking trace.',
              type: MessageType.thought,
            ),
          ],
          stateOperations: const [
            StateOperation(
              type: StateOperationType.replace,
              path: '/character/mood',
              value: 'curious',
              reason: 'assistant response',
            ),
          ],
          activeState: const <String, Object?>{
            'character': <String, Object?>{'mood': 'curious'},
            'session': <String, Object?>{'turnCount': 1},
          },
          summary: 'The first turn settled the character mood.',
        ),
      );

      expect(result.turn.sessionId, session.id);
      expect(result.turn.index, 1);
      expect(result.messages, hasLength(3));
      expect(result.activeState.state['character'], isNotNull);

      final turns = await turnRepository.listTurnsForSession(session.id);
      final messages = await turnRepository.listMessagesForTurn(result.turn.id);
      final activeState = await turnRepository.getActiveState(session.id);

      expect(turns, hasLength(1));
      expect(turns.first.summary, 'The first turn settled the character mood.');
      expect(messages, hasLength(3));
      expect(messages.last.type, MessageType.thought);
      expect(
        activeState!.state,
        containsPair(
          'session',
          <String, Object?>{'turnCount': 1},
        ),
      );

      expect(_countRows(database, 'state_oplogs'), 1);
      expect(_countRows(database, 'active_states'), 1);
    });

    test('rolls back the whole turn commit when session does not exist', () async {
      expect(
        turnRepository.commitTurn(
          const TurnCommitRequest(
            sessionId: 'missing-session',
            messages: [
              DraftMessage(
                role: MessageRole.user,
                content: 'This should fail.',
              ),
            ],
            activeState: <String, Object?>{
              'session': <String, Object?>{'turnCount': 1},
            },
          ),
        ),
        throwsA(isA<Object>()),
      );

      expect(_countRows(database, 'turns'), 0);
      expect(_countRows(database, 'messages'), 0);
      expect(_countRows(database, 'state_oplogs'), 0);
      expect(_countRows(database, 'active_states'), 0);
    });
  });
}

int _countRows(SqliteDatabase database, String tableName) {
  final result = database.rawDatabase.select(
    'SELECT COUNT(*) AS count FROM $tableName',
  );
  return result.first['count'] as int;
}
