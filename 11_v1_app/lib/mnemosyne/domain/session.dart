class Session {
  const Session({
    required this.id,
    required this.title,
    required this.activeCharacterId,
    required this.createdAt,
    required this.updatedAt,
    this.meta = const <String, Object?>{},
  });

  final String id;
  final String title;
  final String activeCharacterId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, Object?> meta;

  Session copyWith({
    String? id,
    String? title,
    String? activeCharacterId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, Object?>? meta,
  }) {
    return Session(
      id: id ?? this.id,
      title: title ?? this.title,
      activeCharacterId: activeCharacterId ?? this.activeCharacterId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      meta: meta ?? this.meta,
    );
  }
}
