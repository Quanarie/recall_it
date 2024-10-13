import 'dart:math';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/my_point.dart';

bool arePointsCloseEnoughOnScreen(
    LatLng point1, LatLng point2, MapCamera cam, double threshold) {
  var p1 = cam.latLngToScreenPoint(point1);
  var p2 = cam.latLngToScreenPoint(point2);
  return p1.distanceTo(p2) <= threshold;
}

int? findIndexOfClosestPointToGivenCoordinates(
    LatLng coordinates, List<MyPoint> points) {
  double closestDistance = double.infinity;
  int? closestPoint;

  for (int i = 0; i < points.length; i++) {
    MyPoint loadedPoint = points[i];
    double distance = _calculateDistance(
      coordinates,
      loadedPoint.toLatLng(),
    );

    if (distance < closestDistance) {
      closestDistance = distance;
      closestPoint = i;
    }
  }

  return closestPoint;
}

double _calculateDistance(LatLng p1, LatLng p2) {
  var p = 0.017453292519943295;
  var a = 0.5 -
      cos((p2.latitude - p1.latitude) * p) / 2 +
      cos(p1.latitude * p) *
          cos(p2.latitude * p) *
          (1 - cos((p2.longitude - p1.longitude) * p)) /
          2;
  return 12742 * asin(sqrt(a));
}
