import 'package:clotho_v1_app/jacquard/services/filament_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XmlFilamentParser', () {
    const parser = XmlFilamentParser();

    test('parses canonical thought, content, and state_update', () {
      final result = parser.parse(_canonicalOutput);

      expect(result.thought, 'Assess the request before responding.');
      expect(result.content, 'Response visible to the user.');
      expect(result.stateUpdate, isNotNull);
      expect(result.stateUpdate!['analysis'], 'State change accepted.');
      expect(result.stateUpdateError, isNull);
    });

    test('accepts missing thought', () {
      final result = parser.parse('''
<filament_output version="3.0">
  <content>Visible body only.</content>
</filament_output>
''');

      expect(result.content, 'Visible body only.');
      expect(result.thought, isNull);
      expect(result.stateUpdate, isNull);
    });

    test('fails when content is missing', () {
      expect(
        () => parser.parse('''
<filament_output version="3.0">
  <thought>Only thought.</thought>
</filament_output>
'''),
        throwsA(isA<FilamentParseException>()),
      );
    });

    test('compat mode normalizes legacy tags', () {
      final result = parser.parse(
        '''
<filament_output version="3.0">
  <think>Legacy thought.</think>
  <variable_update>
    {"ops":[{"op":"replace","path":"/character/mood","value":"focused"}]}
  </variable_update>
  <reply>Legacy content.</reply>
</filament_output>
''',
        mode: FilamentParseMode.compat,
      );

      expect(result.thought, 'Legacy thought.');
      expect(result.content, 'Legacy content.');
      expect(result.stateUpdate, isNotNull);
      expect(result.stateUpdate!['ops'], isA<List<Object?>>());
    });

    test('strict mode rejects legacy tags', () {
      expect(
        () => parser.parse(
          '''
<filament_output version="3.0">
  <reply>Legacy content.</reply>
</filament_output>
''',
        ),
        throwsA(isA<FilamentParseException>()),
      );
    });

    test('invalid state_update JSON does not drop content', () {
      final result = parser.parse('''
<filament_output version="3.0">
  <content>Keep this message.</content>
  <state_update>
    {"ops":[{"op":"replace","path":"/session/turnCount","value":1,}]}
  </state_update>
</filament_output>
''');

      expect(result.content, 'Keep this message.');
      expect(result.stateUpdate, isNull);
      expect(result.stateUpdateRaw, contains('/session/turnCount'));
      expect(result.stateUpdateError, isNotNull);
    });
  });
}

const String _canonicalOutput = '''
<filament_output version="3.0">
  <thought>Assess the request before responding.</thought>
  <state_update>
    {
      "ops": [
        { "op": "replace", "path": "/session/turnCount", "value": 3 }
      ],
      "analysis": "State change accepted."
    }
  </state_update>
  <content>Response visible to the user.</content>
</filament_output>
''';
