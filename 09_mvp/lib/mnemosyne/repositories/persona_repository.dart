import '../models/persona.dart';

/// Persona 数据访问接口
///
/// 对应设计文档 4.4.1 节
abstract class PersonaRepository {
  /// 根据 ID 获取 Persona
  Future<Persona> getById(String id);

  /// 获取所有 Personas
  Future<List<Persona>> getAll();
}
