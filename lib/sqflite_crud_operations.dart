import 'package:sqflite/sqflite.dart';

import 'models/point.dart';

class SqfliteCrudOperations {
  Future<Database> openDb() async {
    var databasesPath = await getDatabasesPath();
    var path = '$databasesPath/myDb5.db';

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(Point.getCreateQuery());
      },
    );
  }

  Future<void> insertPoint(Point point) async {
    final db = await openDb();
    db.insert('point', point.toMap(),
        conflictAlgorithm: ConflictAlgorithm.rollback);
  }

  Future<void> deletePoint(int id) async {
    final db = await openDb();
    db.delete('point', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Point>> getPoints() async {
    final db = await openDb();
    final List<Map<String, dynamic>> map = await db.query('point');

    return List.generate(
      map.length,
      (index) {
        return Point.fromMap(map[index]);
      },
    );
  }
}
