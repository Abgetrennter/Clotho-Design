/// Persona - 角色设定
///
/// 对应隐喻体系中的 "Pattern (织谱)"
/// L2 层：静态只读，作为 Session 的蓝图
/// 对应设计文档 4.3.1 节
class Persona {
  final String id;
  final String name;
  final String description;
  final String systemPrompt;
  final String? firstMessage;
  final DateTime createdAt;

  const Persona({
    required this.id,
    required this.name,
    required this.description,
    required this.systemPrompt,
    this.firstMessage,
    required this.createdAt,
  });

  /// 从 YAML 内容创建 Persona
  factory Persona.fromYaml(Map<String, dynamic> yaml) => Persona(
        id: yaml['id'] as String,
        name: yaml['name'] as String,
        description: yaml['description'] as String,
        systemPrompt: yaml['systemPrompt'] as String,
        firstMessage: yaml['firstMessage'] as String?,
        createdAt: yaml['createdAt'] != null
            ? DateTime.parse(yaml['createdAt'] as String)
            : DateTime.now(),
      );

  /// 从 JSON 创建 Persona
  factory Persona.fromJson(Map<String, dynamic> json) => Persona(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        systemPrompt: json['systemPrompt'] as String,
        firstMessage: json['firstMessage'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'systemPrompt': systemPrompt,
        'firstMessage': firstMessage,
        'createdAt': createdAt.toIso8601String(),
      };

  /// 创建副本
  Persona copyWith({
    String? id,
    String? name,
    String? description,
    String? systemPrompt,
    String? firstMessage,
    DateTime? createdAt,
  }) {
    return Persona(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      firstMessage: firstMessage ?? this.firstMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Persona(id: $id, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Persona &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          systemPrompt == other.systemPrompt &&
          firstMessage == other.firstMessage &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        systemPrompt,
        firstMessage,
        createdAt,
      );
}
