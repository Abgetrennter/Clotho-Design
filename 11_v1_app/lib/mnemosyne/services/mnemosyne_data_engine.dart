import '../persistence/sqlite_database.dart';

class MnemosyneDataEngine {
  const MnemosyneDataEngine({required this.database});

  final SqliteDatabase database;
}
