import 'environment_config.dart';

class ServiceRegistry {
  ServiceRegistry._(this.environment);

  final EnvironmentConfig environment;

  static ServiceRegistry? _instance;

  static ServiceRegistry bootstrap(EnvironmentConfig environment) {
    final registry = ServiceRegistry._(environment);
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
