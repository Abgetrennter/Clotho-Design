import '../domain/active_state.dart';
import '../domain/message.dart';
import '../domain/turn.dart';
import '../domain/turn_commit.dart';
import '../domain/turn_commit_result.dart';

abstract class TurnRepository {
  Future<TurnCommitResult> commitTurn(TurnCommitRequest request);

  Future<ActiveState?> getActiveState(String sessionId);

  Future<List<Message>> listMessagesForTurn(String turnId);

  Future<List<Turn>> listTurnsForSession(String sessionId);
}
