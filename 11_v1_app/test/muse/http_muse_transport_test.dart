import 'dart:convert';

import 'package:clotho_v1_app/muse/config/muse_provider_config.dart';
import 'package:clotho_v1_app/muse/gateway/http_muse_transport.dart';
import 'package:clotho_v1_app/muse/gateway/muse_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HttpMuseTransport', () {
    test('sends an OpenAI-compatible chat completions request', () async {
      late Uri requestedUri;
      late Map<String, String> requestedHeaders;
      late Map<String, dynamic> requestedBody;

      final client = MockClient((request) async {
        requestedUri = request.url;
        requestedHeaders = request.headers;
        requestedBody = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode(<String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'message': <String, Object?>{
                  'content': '<filament_output version="3.0"><content>Remote ok.</content></filament_output>',
                },
              },
            ],
          }),
          200,
          headers: <String, String>{
            'content-type': 'application/json',
          },
        );
      });

      final transport = HttpMuseTransport(client: client);
      final result = await transport.requestCompletion(
        MuseTransportRequest(
          config: const MuseProviderConfig(
            providerId: 'openai-compatible',
            model: 'demo-model',
            baseUrl: 'https://example.com/v1',
            apiKey: 'secret-key',
            temperature: 0.3,
          ),
          prompt: 'Prompt body.',
        ),
      );

      expect(requestedUri.toString(), 'https://example.com/v1/chat/completions');
      expect(requestedHeaders['Authorization'], 'Bearer secret-key');
      expect(requestedHeaders['Content-Type'], 'application/json');
      expect(requestedBody['model'], 'demo-model');
      expect(requestedBody['temperature'], 0.3);
      expect(requestedBody['messages'], <Object?>[
        <String, Object?>{
          'role': 'user',
          'content': 'Prompt body.',
        },
      ]);
      expect(result, contains('Remote ok.'));
    });

    test('throws when the remote payload is missing choices', () async {
      final transport = HttpMuseTransport(
        client: MockClient(
          (_) async => http.Response('{}', 200),
        ),
      );

      expect(
        () => transport.requestCompletion(
          MuseTransportRequest(
            config: const MuseProviderConfig(
              providerId: 'openai-compatible',
              model: 'demo-model',
              baseUrl: 'https://example.com/v1',
              apiKey: 'secret-key',
            ),
            prompt: 'Prompt body.',
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
