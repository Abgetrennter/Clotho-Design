import 'dart:async';

import '../config/muse_provider_config.dart';
import 'http_muse_transport.dart';
import 'muse_raw_gateway.dart';
import 'muse_transport.dart';

class DemoMuseRawGateway implements MuseRawGateway {
  DemoMuseRawGateway({
    MuseProviderConfig? config,
    MuseTransport? transport,
  }) : _config = config ?? MuseProviderConfig.fromEnvironment(),
       _transport = transport ?? HttpMuseTransport();

  final MuseProviderConfig _config;
  final MuseTransport _transport;

  @override
  Stream<String> streamResponse(String prompt) async* {
    if (_config.hasRemoteAccess) {
      final completion = await _transport.requestCompletion(
        MuseTransportRequest(
          config: _config,
          prompt: prompt,
        ),
      );

      for (final chunk in _chunk(completion)) {
        yield chunk;
      }
      return;
    }

    for (final chunk in _chunk(_buildFallbackOutput(prompt))) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
      yield chunk;
    }
  }

  String _buildFallbackOutput(String prompt) {
    final userMessage = _extractUserMessage(prompt);
    final lower = userMessage.toLowerCase();

    String? mood;
    if (lower.contains('happy') || userMessage.contains('高兴')) {
      mood = 'happy';
    } else if (lower.contains('sad') || userMessage.contains('难过')) {
      mood = 'sad';
    } else if (lower.contains('focus') || userMessage.contains('专注')) {
      mood = 'focused';
    }

    final stateUpdate = mood == null
        ? ''
        : '''
<state_update>
{"ops":[{"op":"replace","path":"/character/mood","value":"$mood"}]}
</state_update>
''';

    final content =
        'Received: $userMessage\n\nThis response is produced by the demo Muse gateway wired through Jacquard and Mnemosyne.';

    final output = '''
<filament_output version="3.0">
  <thought>Prepare a concise reply for the current session.</thought>
  $stateUpdate
  <content>$content</content>
</filament_output>
''';
    return output;
  }

  String _extractUserMessage(String prompt) {
    final lines = prompt
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
    return lines.isEmpty ? '' : lines.last;
  }

  Iterable<String> _chunk(String source) sync* {
    const size = 72;
    for (var index = 0; index < source.length; index += size) {
      final end = (index + size).clamp(0, source.length);
      yield source.substring(index, end);
    }
  }
}
