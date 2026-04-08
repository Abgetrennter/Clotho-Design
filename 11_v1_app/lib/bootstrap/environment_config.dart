class EnvironmentConfig {
  const EnvironmentConfig({
    required this.appName,
    required this.enableDiagnostics,
    required this.defaultSessionTitle,
  });

  final String appName;
  final bool enableDiagnostics;
  final String defaultSessionTitle;

  factory EnvironmentConfig.fromEnvironment() {
    return const EnvironmentConfig(
      appName: String.fromEnvironment(
        'CLOTHO_APP_NAME',
        defaultValue: 'Clotho V1',
      ),
      enableDiagnostics: bool.fromEnvironment(
        'CLOTHO_ENABLE_DIAGNOSTICS',
        defaultValue: true,
      ),
      defaultSessionTitle: String.fromEnvironment(
        'CLOTHO_DEFAULT_SESSION_TITLE',
        defaultValue: 'Untitled Session',
      ),
    );
  }
}
