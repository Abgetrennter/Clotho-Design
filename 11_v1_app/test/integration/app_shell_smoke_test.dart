import 'package:clotho_v1_app/app/clotho_app.dart';
import 'package:clotho_v1_app/bootstrap/app_bootstrap.dart';
import 'package:clotho_v1_app/bootstrap/environment_config.dart';
import 'package:clotho_v1_app/bootstrap/service_registry.dart';
import 'package:clotho_v1_app/jacquard/application/load_session_view_use_case.dart';
import 'package:clotho_v1_app/jacquard/application/send_message_use_case.dart';
import 'package:clotho_v1_app/mnemosyne/domain/active_state.dart';
import 'package:clotho_v1_app/mnemosyne/domain/message.dart';
import 'package:clotho_v1_app/mnemosyne/domain/session.dart';
import 'package:clotho_v1_app/mnemosyne/domain/turn.dart';
import 'package:clotho_v1_app/mnemosyne/domain/turn_commit.dart';
import 'package:clotho_v1_app/mnemosyne/domain/turn_commit_result.dart';
import 'package:clotho_v1_app/mnemosyne/repositories/session_repository.dart';
import 'package:clotho_v1_app/mnemosyne/repositories/turn_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shell renders V1 destinations', (tester) async {
    const environment = EnvironmentConfig(
      appName: 'Clotho Test',
      enableDiagnostics: true,
      defaultSessionTitle: 'Test Session',
    );
    final bootstrap = BootstrapResult(
      environment: environment,
      registry: ServiceRegistry.bootstrap(
        environment: environment,
        sessionRepository: _FakeSessionRepository(),
        turnRepository: _FakeTurnRepository(),
        loadSessionViewUseCase: const _FakeLoadSessionViewUseCase(),
        sendMessageUseCase: const _FakeSendMessageUseCase(),
        activeSessionId: 'session_test',
      ),
    );

    await tester.pumpWidget(ClothoApp(bootstrap: bootstrap));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Stage'), findsWidgets);
    expect(find.text('Inspector'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}

class _FakeSessionRepository implements SessionRepository {
  @override
  Future<Session> createSession({
    required String title,
    required String activeCharacterId,
    Map<String, Object?> meta = const <String, Object?>{},
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteSession(String id) {
    throw UnimplementedError();
  }

  @override
  Future<Session?> getSessionById(String id) {
    throw UnimplementedError();
  }

  @override
  Future<List<Session>> listRecentSessions({int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateSession(Session session) {
    throw UnimplementedError();
  }
}

class _FakeTurnRepository implements TurnRepository {
  @override
  Future<TurnCommitResult> commitTurn(TurnCommitRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<ActiveState?> getActiveState(String sessionId) async => null;

  @override
  Future<List<Message>> listMessagesForTurn(String turnId) async =>
      const <Message>[];

  @override
  Future<List<Turn>> listTurnsForSession(String sessionId) async =>
      const <Turn>[];
}

class _FakeLoadSessionViewUseCase implements LoadSessionViewUseCase {
  const _FakeLoadSessionViewUseCase();

  @override
  Future<SessionView> execute(String sessionId) async {
    return const SessionView(
      messages: <Message>[],
      activeState: <String, Object?>{
        'character': <String, Object?>{},
        'session': <String, Object?>{'turnCount': 0},
      },
    );
  }
}

class _FakeSendMessageUseCase implements SendMessageUseCase {
  const _FakeSendMessageUseCase();

  @override
  Future<SendMessageResult> execute(SendMessageRequest request) {
    throw UnimplementedError();
  }
}
