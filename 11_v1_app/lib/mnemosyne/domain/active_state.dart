class ActiveState {
  const ActiveState({
    required this.sessionId,
    required this.turnId,
    required this.state,
    required this.updatedAt,
  });

  final String sessionId;
  final String turnId;
  final Map<String, Object?> state;
  final DateTime updatedAt;
}
