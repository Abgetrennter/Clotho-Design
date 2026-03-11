import '../models/turn.dart';
import 'turn_repository.dart';

/// 内存版 Turn Repository 实现
///
/// MVP 简化版：使用内存存储，重启后数据丢失
class InMemoryTurnRepository implements TurnRepository {
  final Map<String, List<Turn>> _sessions = {};

  @override
  Future<List<Turn>> getBySession(String sessionId) async {
    final turns = _sessions[sessionId] ?? [];
    return List.unmodifiable(
      turns..sort((a, b) => a.index.compareTo(b.index)),
    );
  }

  @override
  Future<Turn> create(Turn turn) async {
    _sessions.putIfAbsent(turn.sessionId, () => []);
    _sessions[turn.sessionId]!.add(turn);
    return turn;
  }

  @override
  Future<Turn?> getLastTurn(String sessionId) async {
    final turns = _sessions[sessionId] ?? [];
    if (turns.isEmpty) return null;
    return turns.reduce((a, b) => a.index > b.index ? a : b);
  }

  /// 注册 Turn（用于测试）
  void register(Turn turn) {
    _sessions.putIfAbsent(turn.sessionId, () => []);
    _sessions[turn.sessionId]!.add(turn);
  }

  /// 清除会话的所有 Turns
  void clearSession(String sessionId) {
    _sessions.remove(sessionId);
  }
}
