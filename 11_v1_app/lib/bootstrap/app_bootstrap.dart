import '../jacquard/application/load_session_view_use_case.dart';
import '../jacquard/application/send_message_use_case.dart';
import '../jacquard/domain/prompt_bundle.dart';
import '../jacquard/services/filament_parser.dart';
import '../mnemosyne/persistence/sqlite_database.dart';
import '../mnemosyne/persistence/sqlite_session_repository.dart';
import '../mnemosyne/persistence/sqlite_turn_repository.dart';
import '../mnemosyne/services/state_updater.dart';
import '../muse/gateway/demo_muse_raw_gateway.dart';
import 'environment_config.dart';
import 'service_registry.dart';

class BootstrapResult {
  const BootstrapResult({required this.environment, required this.registry});

  final EnvironmentConfig environment;
  final ServiceRegistry registry;
}

class AppBootstrap {
  AppBootstrap._();

  static Future<BootstrapResult> initialize() async {
    final environment = EnvironmentConfig.fromEnvironment();
    final database = SqliteDatabase.openInMemory();
    final sessionRepository = SqliteSessionRepository(database);
    final turnRepository = SqliteTurnRepository(database);
    final filamentParser = const XmlFilamentParser();
    final stateUpdater = const StateUpdater();
    final sendMessageUseCase = DefaultSendMessageUseCase(
      museGateway: DemoMuseRawGateway(),
      filamentParser: filamentParser,
      turnRepository: turnRepository,
      stateUpdater: stateUpdater,
    );
    final loadSessionViewUseCase = DefaultLoadSessionViewUseCase(
      turnRepository: turnRepository,
    );
    final session = await sessionRepository.createSession(
      title: environment.defaultSessionTitle,
      activeCharacterId: 'persona.demo',
      meta: const <String, Object?>{'seed': 'bootstrap'},
    );

    await sendMessageUseCase.execute(
      SendMessageRequest(
        sessionId: session.id,
        userMessage: 'Initialize the demo session.',
        promptBundle: const PromptBundle(
          systemPrompt:
              'Return canonical filament_output with thought and content.',
          userPrompt:
              'This is the initial bootstrap turn for the local demo session.',
        ),
      ),
    );

    final registry = ServiceRegistry.bootstrap(
      environment: environment,
      sessionRepository: sessionRepository,
      turnRepository: turnRepository,
      loadSessionViewUseCase: loadSessionViewUseCase,
      sendMessageUseCase: sendMessageUseCase,
      activeSessionId: session.id,
    );

    return BootstrapResult(environment: environment, registry: registry);
  }
}
