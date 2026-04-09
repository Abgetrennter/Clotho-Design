import '../domain/session.dart';

abstract class SessionRepository {
  Future<Session> createSession({
    required String title,
    required String activeCharacterId,
    Map<String, Object?> meta = const <String, Object?>{},
  });

  Future<void> deleteSession(String id);

  Future<Session?> getSessionById(String id);

  Future<List<Session>> listRecentSessions({int limit = 20});

  Future<void> updateSession(Session session);
}
