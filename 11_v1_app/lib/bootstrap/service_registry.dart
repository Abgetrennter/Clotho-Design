import 'environment_config.dart';
import '../jacquard/application/load_session_view_use_case.dart';
import '../jacquard/application/send_message_use_case.dart';
import '../mnemosyne/repositories/session_repository.dart';
import '../mnemosyne/repositories/turn_repository.dart';

class ServiceRegistry {
  ServiceRegistry._({
    required this.environment,
    required this.sessionRepository,
    required this.turnRepository,
    required this.loadSessionViewUseCase,
    required this.sendMessageUseCase,
    required this.activeSessionId,
  });

  final EnvironmentConfig environment;
  final SessionRepository sessionRepository;
  final TurnRepository turnRepository;
  final LoadSessionViewUseCase loadSessionViewUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final String activeSessionId;

  static ServiceRegistry? _instance;

  static ServiceRegistry bootstrap({
    required EnvironmentConfig environment,
    required SessionRepository sessionRepository,
    required TurnRepository turnRepository,
    required LoadSessionViewUseCase loadSessionViewUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required String activeSessionId,
  }) {
    final registry = ServiceRegistry._(
      environment: environment,
      sessionRepository: sessionRepository,
      turnRepository: turnRepository,
      loadSessionViewUseCase: loadSessionViewUseCase,
      sendMessageUseCase: sendMessageUseCase,
      activeSessionId: activeSessionId,
    );
    _instance = registry;
    return registry;
  }

  static ServiceRegistry get instance {
    final registry = _instance;
    if (registry == null) {
      throw StateError(
        'ServiceRegistry has not been initialized. Call AppBootstrap.initialize() first.',
      );
    }
    return registry;
  }
}
