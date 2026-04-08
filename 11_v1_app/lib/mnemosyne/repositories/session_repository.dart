import '../domain/session_summary.dart';

abstract class SessionRepository {
  Future<List<SessionSummary>> listSessions();

  Future<SessionSummary> createSession({
    required String title,
    required String personaId,
  });
}
