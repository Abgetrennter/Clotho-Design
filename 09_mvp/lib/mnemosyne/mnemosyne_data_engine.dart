import 'package:uuid/uuid.dart';

import 'models/persona.dart';
import 'models/session.dart';
import 'models/turn.dart';
import 'models/message.dart';
import 'models/session_context.dart';
import 'repositories/persona_repository.dart';
import 'repositories/session_repository.dart';
import 'repositories/turn_repository.dart';

/// Mnemosyne 数据引擎
///
/// 统一数据访问入口，提供高层业务方法
/// 对应设计文档 4.5.2 节
class MnemosyneDataEngine {
  final PersonaRepository _personaRepo;
  final SessionRepository _sessionRepo;
  final TurnRepository _turnRepo;
  final Uuid _uuid = const Uuid();

  MnemosyneDataEngine({
    required PersonaRepository personaRepo,
    required SessionRepository sessionRepo,
    required TurnRepository turnRepo,
  })  : _personaRepo = personaRepo,
        _sessionRepo = sessionRepo,
        _turnRepo = turnRepo;

  /// 获取 Session 及其 Context
  Future<SessionContext> getSessionContext(String sessionId) async {
    final session = await _sessionRepo.getById(sessionId);
    final turns = await _turnRepo.getBySession(sessionId);
    final persona = await _personaRepo.getById(session.personaId);

    return SessionContext(
      session: session,
      persona: persona,
      turns: turns,
    );
  }

  /// 获取 Persona
  Future<Persona> getPersona(String personaId) async {
    return await _personaRepo.getById(personaId);
  }

  /// 获取所有 Personas
  Future<List<Persona>> getAllPersonas() async {
    return await _personaRepo.getAll();
  }

  /// 获取 TurnHistory
  Future<List<Turn>> getTurnHistory(String sessionId) async {
    return await _turnRepo.getBySession(sessionId);
  }

  /// 创建新 Session
  Future<Session> createSession({
    required String personaId,
    String? title,
  }) async {
    final now = DateTime.now();
    final session = Session(
      id: 'ses_${_uuid.v4()}',
      personaId: personaId,
      title: title ?? 'New Session',
      createdAt: now,
      updatedAt: now,
    );

    return await _sessionRepo.create(session);
  }

  /// 创建新 Turn
  Future<Turn> createTurn({
    required String sessionId,
    required List<Message> messages,
  }) async {
    final lastTurn = await _turnRepo.getLastTurn(sessionId);
    final nextIndex = (lastTurn?.index ?? 0) + 1;

    final turn = Turn(
      id: 'trn_${_uuid.v4()}',
      sessionId: sessionId,
      index: nextIndex,
      createdAt: DateTime.now(),
      messages: messages,
    );

    return await _turnRepo.create(turn);
  }

  /// 删除 Session 及其所有 Turns
  Future<void> deleteSession(String sessionId) async {
    // 注意：TurnRepository 需要支持清除会话的所有 Turns
    // MVP 简化版：仅删除 Session 记录
    await _sessionRepo.delete(sessionId);
  }

  /// 获取最近的 Sessions
  Future<List<Session>> getRecentSessions({int limit = 10}) async {
    return await _sessionRepo.getRecent(limit: limit);
  }

  /// 更新 Session
  Future<void> updateSession(Session session) async {
    await _sessionRepo.update(session);
  }
}
