import 'dart:convert';

import 'package:xml/xml.dart';

enum FilamentParseMode {
  strict,
  compat,
}

class FilamentParseException implements Exception {
  const FilamentParseException(this.message);

  final String message;

  @override
  String toString() => 'FilamentParseException: $message';
}

class FilamentParseResult {
  const FilamentParseResult({
    required this.content,
    this.thought,
    this.stateUpdate,
    this.stateUpdateRaw,
    this.stateUpdateError,
  });

  final String content;
  final String? thought;
  final Map<String, Object?>? stateUpdate;
  final String? stateUpdateRaw;
  final String? stateUpdateError;
}

abstract class FilamentParser {
  FilamentParseResult parse(
    String rawOutput, {
    FilamentParseMode mode = FilamentParseMode.strict,
  });
}

class XmlFilamentParser implements FilamentParser {
  const XmlFilamentParser();

  static const Map<String, String> _compatAliases = <String, String>{
    'think': 'thought',
    'reply': 'content',
    'variable_update': 'state_update',
  };

  static const Set<String> _v1Tags = <String>{
    'thought',
    'content',
    'state_update',
  };

  @override
  FilamentParseResult parse(
    String rawOutput, {
    FilamentParseMode mode = FilamentParseMode.strict,
  }) {
    final normalizedOutput = switch (mode) {
      FilamentParseMode.strict => rawOutput,
      FilamentParseMode.compat => _normalizeAliases(rawOutput),
    };

    final document = _parseXml(normalizedOutput);
    final root = document.rootElement;

    if (root.name.local != 'filament_output') {
      throw const FilamentParseException(
        'Expected <filament_output> as the root tag.',
      );
    }

    final children = root.childElements.toList(growable: false);
    for (final child in children) {
      if (!_v1Tags.contains(child.name.local)) {
        throw FilamentParseException(
          'Unsupported Filament tag for V1: <${child.name.local}>.',
        );
      }
    }

    final thought = _readFirstTag(children, 'thought');
    final content = _readFirstTag(children, 'content');
    if (content == null || content.trim().isEmpty) {
      throw const FilamentParseException(
        'Missing required <content> tag in filament output.',
      );
    }

    final stateUpdateRaw = _readFirstTag(children, 'state_update');
    final stateUpdateResult = _parseStateUpdate(stateUpdateRaw);

    return FilamentParseResult(
      content: content.trim(),
      thought: thought?.trim().isEmpty ?? true ? null : thought!.trim(),
      stateUpdate: stateUpdateResult.value,
      stateUpdateRaw: stateUpdateRaw?.trim(),
      stateUpdateError: stateUpdateResult.error,
    );
  }

  XmlDocument _parseXml(String rawOutput) {
    try {
      return XmlDocument.parse(rawOutput);
    } on XmlParserException catch (error) {
      throw FilamentParseException('Invalid Filament XML: ${error.message}');
    }
  }

  _ParsedStateUpdate _parseStateUpdate(String? rawStateUpdate) {
    if (rawStateUpdate == null || rawStateUpdate.trim().isEmpty) {
      return const _ParsedStateUpdate();
    }

    final normalized = rawStateUpdate.trim();
    try {
      final decoded = jsonDecode(normalized);
      if (decoded is! Map<String, dynamic>) {
        return const _ParsedStateUpdate(
          error: 'state_update body must decode to a JSON object.',
        );
      }

      final stateUpdate = Map<String, Object?>.from(decoded);
      final ops = stateUpdate['ops'];
      if (ops is! List) {
        return const _ParsedStateUpdate(
          error: 'state_update JSON must contain an ops array.',
        );
      }

      return _ParsedStateUpdate(value: stateUpdate);
    } on FormatException catch (error) {
      return _ParsedStateUpdate(
        error: 'Invalid state_update JSON: ${error.message}',
      );
    }
  }

  String? _readFirstTag(List<XmlElement> children, String tagName) {
    for (final child in children) {
      if (child.name.local == tagName) {
        return child.innerText;
      }
    }
    return null;
  }

  String _normalizeAliases(String rawOutput) {
    var normalized = rawOutput;
    for (final entry in _compatAliases.entries) {
      normalized = normalized.replaceAllMapped(
        RegExp('<${entry.key}(\\s|>)'),
        (match) => '<${entry.value}${match.group(1)}',
      );
      normalized = normalized.replaceAll('</${entry.key}>', '</${entry.value}>');
    }
    return normalized;
  }
}

class _ParsedStateUpdate {
  const _ParsedStateUpdate({
    this.value,
    this.error,
  });

  final Map<String, Object?>? value;
  final String? error;
}
