class Point {
  final int? id;
  final double latitude;
  final double longitude;
  final String? description;
  final String? color;

  Point({
    this.id,
    required this.latitude,
    required this.longitude,
    this.description,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'color': color,
    };
  }

  factory Point.fromMap(Map<String, dynamic> map) {
    return Point(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      description: map['description'],
      color: map['color'],
    );
  }

  static String getCreateQuery() {
    return 'CREATE TABLE point('
        'id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, '
        'latitude REAL,'
        'longitude REAL,'
        'description TEXT, '
        'color TEXT)';
  }
}
