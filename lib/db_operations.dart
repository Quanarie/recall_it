import 'dart:ui';

import 'package:latlong2/latlong.dart';
import 'package:recall_it/utils/color.dart';
import 'package:sqflite/sqflite.dart';

import 'models/my_point.dart';

class SqfliteCrudOperations {
  Future<Database> openDb() async {
    var databasesPath = await getDatabasesPath();
    var path = '$databasesPath/myDb16.db';

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(MyPoint.getCreateQuery());
      },
    );
  }

  Future<void> insertPoint(MyPoint point) async {
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
