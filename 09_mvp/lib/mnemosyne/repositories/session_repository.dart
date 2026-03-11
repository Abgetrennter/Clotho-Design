import '../models/session.dart';

/// Session 数据访问接口
///
/// 对应设计文档 4.4.1 节
abstract class SessionRepository {
  /// 根据 ID 获取 Session
  Future<Session> getById(String id);

  /// 创建新 Session
  Future<Session> create(Session session);

  /// 更新 Session
  Future<void> update(Session session);

  /// 删除 Session 及其所有 Turns
  Future<void> delete(String id);

  /// 获取所有 Sessions
  Future<List<Session>> getAll();

  /// 获取最近的 Sessions
  Future<List<Session>> getRecent({int limit = 10});
}
