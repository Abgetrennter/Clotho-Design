class MuseProviderConfig {
  const MuseProviderConfig({
    required this.providerId,
    required this.model,
    required this.baseUrl,
    required this.apiKey,
    this.temperature = 0.2,
  });

  final String providerId;
  final String model;
  final String baseUrl;
  final String apiKey;
  final double temperature;

  bool get hasRemoteAccess =>
      apiKey.trim().isNotEmpty &&
      baseUrl.trim().isNotEmpty &&
      model.trim().isNotEmpty;

  Uri get chatCompletionsUri => Uri.parse('$baseUrl/chat/completions');

  factory MuseProviderConfig.fromEnvironment() {
    final temperatureRaw = String.fromEnvironment(
      'CLOTHO_MUSE_TEMPERATURE',
      defaultValue: '0.2',
    );

    return MuseProviderConfig(
      providerId: const String.fromEnvironment(
        'CLOTHO_MUSE_PROVIDER_ID',
        defaultValue: 'openai-compatible',
      ),
      model: const String.fromEnvironment(
        'CLOTHO_MUSE_MODEL',
        defaultValue: '',
      ),
      baseUrl: const String.fromEnvironment(
        'CLOTHO_MUSE_BASE_URL',
        defaultValue: 'https://api.openai.com/v1',
      ),
      apiKey: const String.fromEnvironment(
        'CLOTHO_MUSE_API_KEY',
        defaultValue: '',
      ),
      temperature: double.tryParse(temperatureRaw) ?? 0.2,
    );
  }
}
