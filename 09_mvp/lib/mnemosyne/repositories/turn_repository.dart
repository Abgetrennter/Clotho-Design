import '../models/turn.dart';

/// Turn 数据访问接口
///
/// 对应设计文档 4.4.1 节
abstract class TurnRepository {
  /// 获取会话的所有 Turns
  Future<List<Turn>> getBySession(String sessionId);

  /// 创建新 Turn
  Future<Turn> create(Turn turn);

  /// 获取会话的最后一个 Turn
  Future<Turn?> getLastTurn(String sessionId);
}
