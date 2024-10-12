import 'package:latlong2/latlong.dart';
import 'package:sqflite/sqflite.dart';

import 'models/point.dart';

class SqfliteCrudOperations {
  Future<Database> openDb() async {
    var databasesPath = await getDatabasesPath();
    var path = '$databasesPath/myDb14.db';

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
