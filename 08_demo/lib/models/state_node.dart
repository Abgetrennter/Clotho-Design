/// Mnemosyne 状态节点模型
library;

/// 节点类型
enum NodeType {
  /// 根节点
  root,
  /// 对象节点
  object,
  /// 数组节点
  array,
  /// 值节点
  value,
}

/// 状态节点模型
class StateNode {
  StateNode({
    required this.id,
    required this.name,
    required this.type,
    this.value,
    this.children = const [],
    this.isExpanded = false,
  });

  final String id;
  final String name;
  final NodeType type;
  final dynamic value;
  final List<StateNode> children;
  bool isExpanded;

  /// 创建根节点
  factory StateNode.root({
    required String id,
    required String name,
    List<StateNode> children = const [],
  }) {
    return StateNode(
      id: id,
      name: name,
      type: NodeType.root,
      children: children,
    );
  }

  /// 创建对象节点
  factory StateNode.object({
    required String id,
    required String name,
    List<StateNode> children = const [],
  }) {
    return StateNode(
      id: id,
      name: name,
      type: NodeType.object,
      children: children,
    );
  }

  /// 创建数组节点
  factory StateNode.array({
    required String id,
    required String name,
    List<StateNode> children = const [],
  }) {
    return StateNode(
      id: id,
      name: name,
      type: NodeType.array,
      children: children,
    );
  }

  /// 创建值节点
  factory StateNode.value({
    required String id,
    required String name,
    required dynamic value,
  }) {
    return StateNode(
      id: id,
      name: name,
      type: NodeType.value,
      value: value,
    );
  }

  /// 是否有子节点
  bool get hasChildren => children.isNotEmpty;

  /// 切换展开状态
  void toggleExpanded() {
    isExpanded = !isExpanded;
  }
}
