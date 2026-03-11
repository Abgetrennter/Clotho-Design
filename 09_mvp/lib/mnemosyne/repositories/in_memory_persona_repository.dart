import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

import '../models/persona.dart';
import 'persona_repository.dart';

/// 内存版 Persona Repository 实现
///
/// 从 assets 目录加载 YAML Persona 文件
class InMemoryPersonaRepository implements PersonaRepository {
  final Map<String, Persona> _cache = {};
  final String _assetsPath;

  InMemoryPersonaRepository({String assetsPath = 'assets/personas/'})
      : _assetsPath = assetsPath;

  /// 预加载所有 Persona
  Future<void> preload() async {
    // MVP 简化：直接加载预设的 Persona 列表
    // 实际项目中可以扫描 assets 目录
    await _loadPersona('seraphina.yaml');
  }

  /// 从 YAML 文件加载 Persona
  Future<void> _loadPersona(String filename) async {
    try {
      final content =
          await rootBundle.loadString('$_assetsPath$filename');
      final yamlMap = loadYaml(content) as Map;
      
      // 转换为 Map<String, dynamic>
      final jsonMap = jsonDecode(jsonEncode(yamlMap)) as Map<String, dynamic>;
      
      final persona = Persona.fromYaml(jsonMap);
      _cache[persona.id] = persona;
    } catch (e) {
      throw Exception('Failed to load persona from $filename: $e');
    }
  }

  @override
  Future<Persona> getById(String id) async {
    if (!_cache.containsKey(id)) {
      throw Exception('Persona not found: $id');
    }
    return _cache[id]!;
  }

  @override
  Future<List<Persona>> getAll() async {
    return _cache.values.toList();
  }

  /// 注册 Persona（用于测试）
  void register(Persona persona) {
    _cache[persona.id] = persona;
  }
}
