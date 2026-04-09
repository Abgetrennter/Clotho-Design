class Turn {
  const Turn({
    required this.id,
    required this.sessionId,
    required this.index,
    required this.createdAt,
    this.summary,
  });

  final String id;
  final String sessionId;
  final int index;
  final DateTime createdAt;
  final String? summary;
}
