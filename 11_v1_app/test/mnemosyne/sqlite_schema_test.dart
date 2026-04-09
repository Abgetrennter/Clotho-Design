import 'package:clotho_v1_app/mnemosyne/persistence/sqlite_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SqliteSchema', () {
    test('creates the V1 tables and omits deferred tables', () {
      final database = SqliteDatabase.openInMemory();
      addTearDown(database.close);

      final result = database.rawDatabase.select('''
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        ORDER BY name
        ''');

      final tableNames = result
          .map((row) => row['name'] as String)
          .where((name) => !name.startsWith('sqlite_'))
          .toSet();

      expect(
        tableNames,
        containsAll(<String>{
          'sessions',
          'turns',
          'messages',
          'active_states',
          'state_oplogs',
        }),
      );
      expect(tableNames, isNot(contains('state_snapshots')));
      expect(tableNames, isNot(contains('events')));
    });
  });
}
