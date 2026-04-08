import '../domain/persona_manifest.dart';

abstract class PersonaLoader {
  Future<PersonaManifest> load(String personaId);
}
