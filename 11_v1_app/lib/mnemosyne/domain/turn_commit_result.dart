import 'active_state.dart';
import 'message.dart';
import 'turn.dart';

class TurnCommitResult {
  const TurnCommitResult({
    required this.turn,
    required this.messages,
    required this.activeState,
  });

  final Turn turn;
  final List<Message> messages;
  final ActiveState activeState;
}
