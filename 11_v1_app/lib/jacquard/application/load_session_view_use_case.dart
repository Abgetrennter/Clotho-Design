import '../../mnemosyne/domain/message.dart';
import '../../mnemosyne/repositories/turn_repository.dart';

class SessionView {
  const SessionView({
    required this.messages,
    required this.activeState,
  });

  final List<Message> messages;
  final Map<String, Object?> activeState;
}

abstract class LoadSessionViewUseCase {
  Future<SessionView> execute(String sessionId);
}

class DefaultLoadSessionViewUseCase implements LoadSessionViewUseCase {
  const DefaultLoadSessionViewUseCase({
    required TurnRepository turnRepository,
  }) : _turnRepository = turnRepository;

  final TurnRepository _turnRepository;

  @override
  Future<SessionView> execute(String sessionId) async {
    final turns = await _turnRepository.listTurnsForSession(sessionId);
    final messages = <Message>[];
    for (final turn in turns) {
      messages.addAll(await _turnRepository.listMessagesForTurn(turn.id));
    }

    final activeState = await _turnRepository.getActiveState(sessionId);
    return SessionView(
      messages: messages,
      activeState: activeState?.state ??
          <String, Object?>{
            'character': <String, Object?>{},
            'session': <String, Object?>{},
          },
    );
  }
}
