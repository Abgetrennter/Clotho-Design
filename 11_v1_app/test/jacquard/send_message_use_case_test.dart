import 'package:clotho_v1_app/jacquard/application/send_message_use_case.dart';
import 'package:clotho_v1_app/jacquard/domain/prompt_bundle.dart';
import 'package:clotho_v1_app/jacquard/services/filament_parser.dart';
import 'package:clotho_v1_app/mnemosyne/persistence/sqlite_database.dart';
import 'package:clotho_v1_app/mnemosyne/persistence/sqlite_session_repository.dart';
import 'package:clotho_v1_app/mnemosyne/persistence/sqlite_turn_repository.dart';
import 'package:clotho_v1_app/mnemosyne/services/state_updater.dart';
import 'package:clotho_v1_app/muse/gateway/muse_raw_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultSendMessageUseCase', () {
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

    test('commits parsed content, thought, and state updates', () async {
      final session = await sessionRepository.createSession(
        title: 'Stage Session',
        activeCharacterId: 'persona.seraphina',
      );
      final gateway = _FakeMuseRawGateway([
        '<filament_output version="3.0">',
        '<thought>Plan the move.</thought>',
        '<state_update>{"ops":[{"op":"replace","path":"/character/mood","value":"focused"}]}</state_update>',
        '<content>Move executed.</content>',
        '</filament_output>',
      ]);
      final useCase = DefaultSendMessageUseCase(
        museGateway: gateway,
        filamentParser: const XmlFilamentParser(),
        turnRepository: turnRepository,
        stateUpdater: const StateUpdater(),
      );

      final result = await useCase.execute(
        SendMessageRequest(
          sessionId: session.id,
          userMessage: 'Proceed.',
          promptBundle: const PromptBundle(
            systemPrompt: 'System block.',
            userPrompt: 'User block.',
          ),
        ),
      );

      final turns = await turnRepository.listTurnsForSession(session.id);
      final messages = await turnRepository.listMessagesForTurn(result.commit.turn.id);
      final activeState = await turnRepository.getActiveState(session.id);

      expect(gateway.lastPrompt, contains('System block.'));
      expect(gateway.lastPrompt, contains('User block.'));
      expect(gateway.lastPrompt, contains('Proceed.'));
      expect(turns, hasLength(1));
      expect(messages, hasLength(3));
      expect(messages[1].content, 'Move executed.');
      expect(messages[2].content, 'Plan the move.');
      expect(
        activeState!.state['character'],
        <String, Object?>{'mood': 'focused'},
      );
      expect(
        activeState.state['session'],
        <String, Object?>{'turnCount': 1},
      );
      expect(result.parseResult.stateUpdateError, isNull);
    });

    test('keeps assistant content when state_update is invalid', () async {
      final session = await sessionRepository.createSession(
        title: 'Invalid Update Session',
        activeCharacterId: 'persona.seraphina',
      );
      final gateway = _FakeMuseRawGateway([
        '<filament_output version="3.0">',
        '<content>Keep visible content.</content>',
        '<state_update>{"ops":[{"op":"replace","path":"/session/turnCount","value":1,}]}</state_update>',
        '</filament_output>',
      ]);
      final useCase = DefaultSendMessageUseCase(
        museGateway: gateway,
        filamentParser: const XmlFilamentParser(),
        turnRepository: turnRepository,
        stateUpdater: const StateUpdater(),
      );

      final result = await useCase.execute(
        SendMessageRequest(
          sessionId: session.id,
          userMessage: 'Trigger malformed update.',
          promptBundle: const PromptBundle(
            systemPrompt: 'System block.',
            userPrompt: 'User block.',
          ),
        ),
      );

      final messages = await turnRepository.listMessagesForTurn(result.commit.turn.id);
      final activeState = await turnRepository.getActiveState(session.id);

      expect(messages, hasLength(2));
      expect(messages[1].content, 'Keep visible content.');
      expect(result.parseResult.stateUpdate, isNull);
      expect(result.parseResult.stateUpdateError, isNotNull);
      expect(
        activeState!.state,
        <String, Object?>{
          'character': <String, Object?>{},
          'session': <String, Object?>{'turnCount': 1},
        },
      );
    });
  });
}

class _FakeMuseRawGateway implements MuseRawGateway {
  _FakeMuseRawGateway(this._chunks);

  final List<String> _chunks;
  String? lastPrompt;

  @override
  Stream<String> streamResponse(String prompt) async* {
    lastPrompt = prompt;
    for (final chunk in _chunks) {
      yield chunk;
    }
  }
}
