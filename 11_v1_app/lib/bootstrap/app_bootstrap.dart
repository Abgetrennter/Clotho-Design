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
    final registry = ServiceRegistry.bootstrap(environment);

    return BootstrapResult(environment: environment, registry: registry);
  }
}
