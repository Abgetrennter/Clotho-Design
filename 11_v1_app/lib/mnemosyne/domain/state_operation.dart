enum StateOperationType { add, replace, remove }

class StateOperation {
  const StateOperation({
    required this.type,
    required this.path,
    this.value,
    this.reason,
  });

  final StateOperationType type;
  final String path;
  final Object? value;
  final String? reason;
}
