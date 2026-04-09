import 'package:clotho_v1_app/muse/config/muse_provider_config.dart';
import 'package:clotho_v1_app/muse/gateway/demo_muse_raw_gateway.dart';
import 'package:clotho_v1_app/muse/gateway/muse_transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DemoMuseRawGateway', () {
    test('falls back to local filament output when no remote config exists', () async {
      final gateway = DemoMuseRawGateway(
        config: const MuseProviderConfig(
          providerId: 'demo',
          model: '',
          baseUrl: 'https://api.openai.com/v1',
          apiKey: '',
        ),
        transport: _NeverCalledTransport(),
      );

      final output = await gateway.streamResponse('Please stay happy.').join();

      expect(output, contains('<filament_output version="3.0">'));
      expect(output, contains('<content>'));
      expect(output, contains('<state_update>'));
      expect(output, contains('"path":"/character/mood"'));
    });

    test('uses remote transport when config is present', () async {
      final transport = _RecordingTransport(
        completion: '''
<filament_output version="3.0">
  <content>Remote response.</content>
</filament_output>
''',
      );
      final gateway = DemoMuseRawGateway(
        config: const MuseProviderConfig(
          providerId: 'openai-compatible',
          model: 'demo-model',
          baseUrl: 'https://example.com/v1',
          apiKey: 'secret-key',
        ),
        transport: transport,
      );

      final output = await gateway.streamResponse('Remote prompt body.').join();

      expect(output, contains('Remote response.'));
      expect(transport.request, isNotNull);
      expect(transport.request!.config.chatCompletionsUri.toString(), 'https://example.com/v1/chat/completions');
      expect(transport.request!.prompt, 'Remote prompt body.');
    });
  });
}

class _RecordingTransport implements MuseTransport {
  _RecordingTransport({
    required this.completion,
  });

  final String completion;
  MuseTransportRequest? request;

  @override
  Future<String> requestCompletion(MuseTransportRequest request) async {
    this.request = request;
    return completion;
  }
}

class _NeverCalledTransport implements MuseTransport {
  @override
  Future<String> requestCompletion(MuseTransportRequest request) {
    throw StateError('Fallback path should not call remote transport.');
  }
}
