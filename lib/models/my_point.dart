import 'package:latlong2/latlong.dart';

class MyPoint {
  int? id;
  double latitude;
  double longitude;
  String description;
  String hexColor;

  MyPoint({
    this.id,
    required this.latitude,
    required this.longitude,
    this.description = "No description",
    this.hexColor = "FFFFFFFF",
  });

  @override
  String toString() {
    return "LatLng($latitude:$longitude)";
  }

  LatLng toLatLng() {
    return LatLng(latitude, longitude);
  }

  factory MyPoint.fromLatLng(LatLng coordinates) {
    return MyPoint(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'hexColor': hexColor,
    };
  }

  factory MyPoint.fromMap(Map<String, dynamic> map) {
    return MyPoint(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      description: map['description'],
      hexColor: map['hexColor'],
    );
  }

  static String getCreateQuery() {
    return 'CREATE TABLE point('
        'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, '
        'latitude REAL,'
        'longitude REAL,'
        'description TEXT, '
        'hexColor TEXT)';
  }
}
