class Point {
  final int? id;
  final double latitude;
  final double longitude;
  final String description;
  final String hexColor;

  Point({
    this.id,
    required this.latitude,
    required this.longitude,
    this.description = "",
    this.hexColor = "FF000000",
  });

  @override
  String toString() {
    return "LatLng($latitude:$longitude)";
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

  factory Point.fromMap(Map<String, dynamic> map) {
    return Point(
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
