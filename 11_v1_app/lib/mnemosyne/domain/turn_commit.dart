import 'message.dart';
import 'state_operation.dart';

class DraftMessage {
  const DraftMessage({
    required this.role,
    required this.content,
    this.type = MessageType.text,
    this.meta = const <String, Object?>{},
  });

  final MessageRole role;
  final String content;
  final MessageType type;
  final Map<String, Object?> meta;
}

class TurnCommitRequest {
  const TurnCommitRequest({
    required this.sessionId,
    required this.messages,
    required this.activeState,
    this.stateOperations = const <StateOperation>[],
    this.summary,
  });

  final String sessionId;
  final List<DraftMessage> messages;
  final List<StateOperation> stateOperations;
  final Map<String, Object?> activeState;
  final String? summary;
}
