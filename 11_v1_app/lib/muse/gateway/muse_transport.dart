import '../config/muse_provider_config.dart';

class MuseTransportRequest {
  const MuseTransportRequest({
    required this.config,
    required this.prompt,
  });

  final MuseProviderConfig config;
  final String prompt;
}

abstract class MuseTransport {
  Future<String> requestCompletion(MuseTransportRequest request);
}
