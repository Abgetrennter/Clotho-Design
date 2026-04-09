import '../domain/state_operation.dart';

class StateUpdater {
  const StateUpdater();

  Map<String, Object?> apply({
    required Map<String, Object?> currentState,
    required List<StateOperation> operations,
  }) {
    final nextState = _deepCloneMap(currentState);

    for (final operation in operations) {
      final segments = _parseJsonPointer(operation.path);
      if (segments.isEmpty) {
        throw StateError('Root-level state operations are not supported.');
      }

      switch (operation.type) {
        case StateOperationType.add:
        case StateOperationType.replace:
          _writeValue(nextState, segments, operation.value);
        case StateOperationType.remove:
          _removeValue(nextState, segments);
      }
    }

    return nextState;
  }

  List<String> _parseJsonPointer(String path) {
    if (!path.startsWith('/')) {
      throw StateError('State path must use JSON Pointer syntax: $path');
    }

    if (path == '/') {
      return const <String>[];
    }

    return path
        .split('/')
        .skip(1)
        .map((segment) => segment.replaceAll('~1', '/').replaceAll('~0', '~'))
        .toList(growable: false);
  }

  void _writeValue(
    Map<String, Object?> target,
    List<String> segments,
    Object? value,
  ) {
    var current = target;
    for (var index = 0; index < segments.length - 1; index += 1) {
      final segment = segments[index];
      final nested = current[segment];
      if (nested is Map<String, Object?>) {
        current = nested;
        continue;
      }

      final created = <String, Object?>{};
      current[segment] = created;
      current = created;
    }

    current[segments.last] = _deepCloneValue(value);
  }

  void _removeValue(Map<String, Object?> target, List<String> segments) {
    var current = target;
    for (var index = 0; index < segments.length - 1; index += 1) {
      final nested = current[segments[index]];
      if (nested is! Map<String, Object?>) {
        return;
      }
      current = nested;
    }

    current.remove(segments.last);
  }

  Map<String, Object?> _deepCloneMap(Map<String, Object?> source) {
    return source.map(
      (key, value) => MapEntry(key, _deepCloneValue(value)),
    );
  }

  Object? _deepCloneValue(Object? value) {
    if (value is Map<String, Object?>) {
      return _deepCloneMap(value);
    }
    if (value is List<Object?>) {
      return value.map(_deepCloneValue).toList(growable: false);
    }
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _deepCloneValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_deepCloneValue).toList(growable: false);
    }
    return value;
  }
}
