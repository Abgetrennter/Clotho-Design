import 'package:clotho_v1_app/mnemosyne/persistence/sqlite_database.dart';
import 'package:clotho_v1_app/mnemosyne/persistence/sqlite_session_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SqliteSessionRepository', () {
    late SqliteDatabase database;
    late SqliteSessionRepository repository;

    setUp(() {
      database = SqliteDatabase.openInMemory();
      repository = SqliteSessionRepository(database);
    });

    tearDown(() {
      database.close();
    });

    test('creates and fetches a session', () async {
      final created = await repository.createSession(
        title: 'First Session',
        activeCharacterId: 'persona.seraphina',
        meta: const <String, Object?>{'origin': 'test'},
      );

      final loaded = await repository.getSessionById(created.id);

      expect(loaded, isNotNull);
      expect(loaded!.title, 'First Session');
      expect(loaded.activeCharacterId, 'persona.seraphina');
      expect(loaded.meta['origin'], 'test');
    });

    test('lists sessions by updated time descending', () async {
      final first = await repository.createSession(
        title: 'Older Session',
        activeCharacterId: 'persona.older',
      );
      final second = await repository.createSession(
        title: 'Newer Session',
        activeCharacterId: 'persona.newer',
      );

      await repository.updateSession(
        first.copyWith(
          updatedAt: second.updatedAt.add(const Duration(minutes: 1)),
        ),
      );

      final sessions = await repository.listRecentSessions();

      expect(sessions, hasLength(2));
      expect(sessions.first.id, first.id);
      expect(sessions.last.id, second.id);
    });

    test('deletes a session', () async {
      final created = await repository.createSession(
        title: 'Disposable Session',
        activeCharacterId: 'persona.temp',
      );

      await repository.deleteSession(created.id);

      final loaded = await repository.getSessionById(created.id);
      expect(loaded, isNull);
    });
  });
}
