import '../models/session.dart';
import 'session_repository.dart';

/// 内存版 Session Repository 实现
///
/// MVP 简化版：使用内存存储，重启后数据丢失
class InMemorySessionRepository implements SessionRepository {
  final Map<String, Session> _cache = {};

  @override
  Future<Session> getById(String id) async {
    if (!_cache.containsKey(id)) {
      throw Exception('Session not found: $id');
    }
    return _cache[id]!;
  }

  @override
  Future<Session> create(Session session) async {
    _cache[session.id] = session;
    return session;
  }

  @override
  Future<void> update(Session session) async {
    if (!_cache.containsKey(session.id)) {
      throw Exception('Session not found: $session.id');
    }
    _cache[session.id] = session;
  }

  @override
  Future<void> delete(String id) async {
    _cache.remove(id);
  }

  @override
  Future<List<Session>> getAll() async {
    return _cache.values.toList();
  }

  @override
  Future<List<Session>> getRecent({int limit = 10}) async {
    final sessions = _cache.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions.take(limit).toList();
  }

  /// 注册 Session（用于测试）
  void register(Session session) {
    _cache[session.id] = session;
  }
}
