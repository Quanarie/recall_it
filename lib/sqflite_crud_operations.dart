import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteCrudOperations {
  Future<Database> openDb() async {
    return await openDatabase(join(await getDatabasesPath(), 'myDb.db'),
        version: 1, onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE point('
        'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, '
        'description TEXT, '
        'color TEXT)',
      );
    });
  }

  Future<void> insertPoint(String description, String color) async {
    final db = await openDb();
    db.insert(
        'point',
        {
          'description': description,
          'color': color,
        },
        conflictAlgorithm: ConflictAlgorithm.rollback);
  }

  Future<void> deletePoint(int id) async {
    final db = await openDb();
    db.delete('point', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePoint(int id, String description, String color) async {
    final db = await openDb();
    db.update(
        'point',
        {
          'description': description,
          'color': color,
        },
        where: 'id = ?',
        whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPoints() async {
    final db = await openDb();
    return await db.query('point');
  }
}
