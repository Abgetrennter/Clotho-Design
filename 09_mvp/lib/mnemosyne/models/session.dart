/// Session - 运行时会话实例
///
/// 对应隐喻体系中的 "Tapestry (织卷)"
/// 用户感知的"一个存档"或"一段人生"
/// 对应设计文档 4.3.1 节
class Session {
  final String id;
  final String personaId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Session({
    required this.id,
    required this.personaId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 创建 Session
  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        personaId: json['personaId'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'personaId': personaId,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// 创建副本
  Session copyWith({
    String? id,
    String? personaId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      personaId: personaId ?? this.personaId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Session(id: $id, personaId: $personaId, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          personaId == other.personaId &&
          title == other.title &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        personaId,
        title,
        createdAt,
        updatedAt,
      );
}
