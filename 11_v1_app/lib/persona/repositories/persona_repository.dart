import '../domain/persona_manifest.dart';

abstract class PersonaRepository {
  Future<List<PersonaManifest>> listPersonas();
}
