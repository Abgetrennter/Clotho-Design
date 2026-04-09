import '../../mnemosyne/domain/message.dart';
import '../../mnemosyne/domain/state_operation.dart';
import '../../mnemosyne/domain/turn_commit.dart';
import '../../mnemosyne/domain/turn_commit_result.dart';
import '../../mnemosyne/repositories/turn_repository.dart';
import '../../mnemosyne/services/state_updater.dart';
import '../../muse/gateway/muse_raw_gateway.dart';
import '../domain/prompt_bundle.dart';
import '../services/filament_parser.dart';

class SendMessageRequest {
  const SendMessageRequest({
    required this.sessionId,
    required this.userMessage,
    required this.promptBundle,
  });

  final String sessionId;
  final String userMessage;
  final PromptBundle promptBundle;
}

class SendMessageResult {
  const SendMessageResult({
    required this.commit,
    required this.rawOutput,
    required this.parseResult,
  });

  final TurnCommitResult commit;
  final String rawOutput;
  final FilamentParseResult parseResult;
}

abstract class SendMessageUseCase {
  Future<SendMessageResult> execute(SendMessageRequest request);
}

class DefaultSendMessageUseCase implements SendMessageUseCase {
  const DefaultSendMessageUseCase({
    required MuseRawGateway museGateway,
    required FilamentParser filamentParser,
    required TurnRepository turnRepository,
    required StateUpdater stateUpdater,
  }) : _museGateway = museGateway,
       _filamentParser = filamentParser,
       _turnRepository = turnRepository,
       _stateUpdater = stateUpdater;

  final MuseRawGateway _museGateway;
  final FilamentParser _filamentParser;
  final TurnRepository _turnRepository;
  final StateUpdater _stateUpdater;

  @override
  Future<SendMessageResult> execute(SendMessageRequest request) async {
    final prompt = _renderPrompt(request.promptBundle, request.userMessage);
    final rawOutput = await _collectOutput(_museGateway.streamResponse(prompt));
    final parseResult = _filamentParser.parse(rawOutput);

    final currentActiveState =
        await _turnRepository.getActiveState(request.sessionId);
    final baseState = currentActiveState?.state ??
        <String, Object?>{
          'character': <String, Object?>{},
          'session': <String, Object?>{},
        };

    final stateOperations = [
      ..._toStateOperations(parseResult.stateUpdate),
      ..._buildDeterministicSessionOperations(baseState),
    ];
    final nextState = stateOperations.isEmpty
        ? baseState
        : _stateUpdater.apply(
            currentState: baseState,
            operations: stateOperations,
          );

    final commit = await _turnRepository.commitTurn(
      TurnCommitRequest(
        sessionId: request.sessionId,
        messages: [
          DraftMessage(
            role: MessageRole.user,
            content: request.userMessage,
          ),
          DraftMessage(
            role: MessageRole.assistant,
            content: parseResult.content,
          ),
          if (parseResult.thought != null)
            DraftMessage(
              role: MessageRole.assistant,
              content: parseResult.thought!,
              type: MessageType.thought,
            ),
        ],
        stateOperations: stateOperations,
        activeState: nextState,
      ),
    );

    return SendMessageResult(
      commit: commit,
      rawOutput: rawOutput,
      parseResult: parseResult,
    );
  }

  Future<String> _collectOutput(Stream<String> chunks) async {
    final buffer = StringBuffer();
    await for (final chunk in chunks) {
      buffer.write(chunk);
    }
    return buffer.toString();
  }

  String _renderPrompt(PromptBundle bundle, String userMessage) {
    return '''
${bundle.systemPrompt}

${bundle.userPrompt}

$userMessage
'''.trim();
  }

  List<StateOperation> _toStateOperations(Map<String, Object?>? stateUpdate) {
    if (stateUpdate == null) {
      return const <StateOperation>[];
    }

    final ops = stateUpdate['ops'];
    if (ops is! List) {
      return const <StateOperation>[];
    }

    return ops
        .whereType<Map>()
        .map(
          (rawOp) => StateOperation(
            type: _decodeOperationType(rawOp['op']),
            path: rawOp['path'] as String,
            value: rawOp['value'],
          ),
        )
        .toList(growable: false);
  }

  List<StateOperation> _buildDeterministicSessionOperations(
    Map<String, Object?> baseState,
  ) {
    final sessionState = baseState['session'];
    final currentTurnCount = switch (sessionState) {
      {'turnCount': final int value} => value,
      _ => 0,
    };

    return [
      StateOperation(
        type: StateOperationType.replace,
        path: '/session/turnCount',
        value: currentTurnCount + 1,
      ),
    ];
  }

  StateOperationType _decodeOperationType(Object? value) {
    switch (value) {
      case 'add':
        return StateOperationType.add;
      case 'replace':
        return StateOperationType.replace;
      case 'remove':
        return StateOperationType.remove;
    }

    throw StateError('Unsupported state operation type: $value');
  }
}
