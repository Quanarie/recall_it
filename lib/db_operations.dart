import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';

import 'models/my_point.dart';

class SqfliteCrudOperations {
  Database? _db;
  String _dbName = 'myDb16.db';

  void setDbName(String dbName) {
    _dbName = dbName;
  }

  Future<Database> openDb() async {
    if (_db != null) return _db!;

    var databasesPath = await getDatabasesPath();
    var path = '$databasesPath/$_dbName';

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(MyPoint.getCreateQuery());
      },
    );

    return _db!;
  }

  Future<void> clearDb() async {
    final db = await openDb();
    await db.delete('point');
  }

  Future<int> insertPoint(MyPoint point) async {
    final db = await openDb();
    return db.insert('point', point.toMap(),
        conflictAlgorithm: ConflictAlgorithm.rollback);
  }

  Future<void> updatePointCoordinates(int id, LatLng newCoordinates) async {
    final db = await openDb();
    await db.update(
      'point',
      {
        "latitude": newCoordinates.latitude,
        "longitude": newCoordinates.longitude,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updatePointColor(int id, String hexColor) async {
    final db = await openDb();
    await db.update(
      'point',
      {
        "hexColor": hexColor,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updatePointDescription(int id, String description) async {
    final db = await openDb();
    await db.update(
      'point',
      {
        "description": description,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  Future<void> deletePoint(int id) async {
    final db = await openDb();
    db.delete('point', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MyPoint>> getPoints() async {
    final db = await openDb();
    final List<Map<String, dynamic>> map = await db.query('point');

    return List.generate(
      map.length,
      (index) {
        return MyPoint.fromMap(map[index]);
      },
    );
  }
}
