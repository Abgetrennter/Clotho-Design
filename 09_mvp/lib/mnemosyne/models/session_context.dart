import 'persona.dart';
import 'session.dart';
import 'turn.dart';

/// SessionContext - 会话上下文
///
/// 包含 Session 及其关联的 Persona 和 Turns
/// 用于在运行时提供完整的会话数据
class SessionContext {
  final Session session;
  final Persona persona;
  final List<Turn> turns;

  const SessionContext({
    required this.session,
    required this.persona,
    required this.turns,
  });

  /// 获取最新的 Turn
  Turn? get lastTurn => turns.isEmpty ? null : turns.last;

  /// 获取所有消息（按时间顺序）
  List<Turn> get sortedTurns => List.unmodifiable(
        turns..sort((a, b) => a.index.compareTo(b.index)),
      );

  @override
  String toString() => 'SessionContext(session: $session, persona: $persona)';
}
