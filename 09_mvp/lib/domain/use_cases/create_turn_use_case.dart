import '../../mnemosyne/mnemosyne_data_engine.dart';
import '../../mnemosyne/models/message.dart';
import '../../mnemosyne/models/turn.dart';

/// 创建回合用例的输入参数
class CreateTurnParams {
  final String sessionId;
  final String userContent;

  const CreateTurnParams({
    required this.sessionId,
    required this.userContent,
  });
}

/// CreateTurnUseCase - 创建回合用例
///
/// 负责处理用户输入并创建新的对话回合
/// 对应设计文档 4.4.2 节
class CreateTurnUseCase {
  final MnemosyneDataEngine _dataEngine;

  CreateTurnUseCase(this._dataEngine);

  /// 执行创建回合用例
  Future<Turn> execute(CreateTurnParams params) async {
    // 创建用户消息
    final userMessage = Message(
      id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
      turnId: 'pending',
      role: MessageRole.user,
      content: params.userContent,
      type: MessageType.text,
      timestamp: DateTime.now(),
    );

    // 创建 Turn
    return await _dataEngine.createTurn(
      sessionId: params.sessionId,
      messages: [userMessage],
    );
  }
}
