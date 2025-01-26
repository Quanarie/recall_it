import 'package:flutter_test/flutter_test.dart';
import 'package:recall_it/models/my_point.dart';
import 'package:recall_it/db_operations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late SqfliteCrudOperations db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = SqfliteCrudOperations();
    await db.clearDb();
  });

  tearDown(() async {
    await db.clearDb();
  });

  test('Point is created and written to the database', () async {
    final point = MyPoint(latitude: 10.0, longitude: 20.0);
    await db.insertPoint(point);

    final points = await db.getPoints();
    expect(points.length, 1);
    expect(points.first.latitude, 10.0);
    expect(points.first.longitude, 20.0);
  });

  test('Description and color of a point can be updated in the database', () async {
    final point = MyPoint(latitude: 10.0, longitude: 20.0);
    final id = await db.insertPoint(point);

    await db.updatePointColor(id, 'FF0000');
    await db.updatePointDescription(id, 'New Description');

    final points = await db.getPoints();
    expect(points.first.description, 'New Description');
    expect(points.first.hexColor, 'FF0000');
  });
}
