// import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:recall_it/db_operations.dart';

import 'models/my_point.dart';
import 'utils/color.dart';

class MyMap extends StatefulWidget {
  const MyMap({super.key, required this.title});

  final String title;

  @override
  State<MyMap> createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  final SqfliteCrudOperations _dbOperations = SqfliteCrudOperations();
  final mapController = MapController();

  List<MyPoint> _loadedPointsToDisplay = [];
  int? _indexOfPointWithVisibleDescription;

  static double tapThresholdScreenDistance = 20;

  Offset? _startingPointDragPosition;

  @override
  void initState() {
    super.initState();
    _fetchAndUpdatePoints();
  }

  Future<void> _fetchAndUpdatePoints() async {
    final points = await _dbOperations.getPoints();
    setState(() {
      _loadedPointsToDisplay = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          onTap: (tapPosition, point) {
            _onMapTap(point);
          },
          initialCenter: const LatLng(51.509364, -0.128928),
          initialZoom: 3.2,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: _loadedPointsToDisplay.map(
              (pointToBeMarkedOnMap) {
                return Marker(
                  width: 80.0,
                  height: 80.0,
                  point: pointToBeMarkedOnMap.toLatLng(),
                  child: GestureDetector(
                    onLongPressStart: (details) {
                      _rememberPointDragStartPosition(pointToBeMarkedOnMap);
                    },
                    onLongPressMoveUpdate: (details) {
                      _moveDraggedPointOnMap(details, pointToBeMarkedOnMap);
                    },
                    onLongPressEnd: (details) {
                      _updatePointPositionInDb(pointToBeMarkedOnMap);
                      _fetchAndUpdatePoints();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: hexToColor(pointToBeMarkedOnMap.hexColor),
                          size: 40,
                        ),
                        if (_indexOfPointWithVisibleDescription != null &&
                            _indexOfPointWithVisibleDescription ==
                                _loadedPointsToDisplay
                                    .indexOf(pointToBeMarkedOnMap))
                          Container(
                            margin: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                              pointToBeMarkedOnMap.description,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }

  void _rememberPointDragStartPosition(MyPoint pointToBeMarkedOnMap) {
    _startingPointDragPosition = mapController.camera
        .latLngToScreenPoint(pointToBeMarkedOnMap.toLatLng())
        .toOffset();
  }

  void _moveDraggedPointOnMap(
      LongPressMoveUpdateDetails details, MyPoint pointToBeMarkedOnMap) {
    setState(() {
      Offset offsetInPixels = details.offsetFromOrigin;

      Offset newPosition = _startingPointDragPosition! + offsetInPixels;
      LatLng newCoordinates = mapController.camera.offsetToCrs(newPosition);

      pointToBeMarkedOnMap.latitude = newCoordinates.latitude;
      pointToBeMarkedOnMap.longitude = newCoordinates.longitude;
    });
  }

  void _onMapTap(LatLng tapCoordinates) {
    LatLng? coordinatesToBeSavedAsPoint;

    if (_loadedPointsToDisplay.isEmpty) {
      coordinatesToBeSavedAsPoint = tapCoordinates;
    } else {
      var indexOfClosestPointToTap = _findClosestPoint(tapCoordinates)!.id;
      if (_arePointsCloseEnoughOnScreen(tapCoordinates,
          _loadedPointsToDisplay[indexOfClosestPointToTap!].toLatLng())) {
        if (_indexOfPointWithVisibleDescription == indexOfClosestPointToTap) {
          _closeVisiblePointDescription();
        } else {
          _openPointDescription(indexOfClosestPointToTap);
        }
      } else {
        coordinatesToBeSavedAsPoint = tapCoordinates;
      }
    }

    if (coordinatesToBeSavedAsPoint != null) {
      _savePointToDb(MyPoint.fromLatLng(coordinatesToBeSavedAsPoint));
      _fetchAndUpdatePoints();
    }
  }

  MyPoint? _findClosestPoint(LatLng point) {
    double closestDistance = double.infinity;
    MyPoint? closestPoint;

    for (int i = 0; i < _loadedPointsToDisplay.length; i++) {
      MyPoint loadedPoint = _loadedPointsToDisplay[i];
      double distance = _calculateDistance(
        point,
        loadedPoint.toLatLng(),
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        closestPoint = _loadedPointsToDisplay[i];
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

  bool _arePointsCloseEnoughOnScreen(LatLng point1, LatLng point2) {
    var camera = mapController.camera;
    var p1 = camera.latLngToScreenPoint(point1);
    var p2 = camera.latLngToScreenPoint(point2);
    return p1.distanceTo(p2) <= tapThresholdScreenDistance;
  }

  void _openPointDescription(int indexOfClosestPointToTap) {
    _indexOfPointWithVisibleDescription = indexOfClosestPointToTap;
    setState(() {});
  }

  void _closeVisiblePointDescription() {
    _indexOfPointWithVisibleDescription = null;
    setState(() {});
  }

  void _savePointToDb(MyPoint point) {
    _dbOperations.insertPoint(point);
  }

  void _updatePointPositionInDb(MyPoint pointToBeMarkedOnMap) {
    _dbOperations.updatePointCoordinates(
        pointToBeMarkedOnMap.id!, pointToBeMarkedOnMap.toLatLng());
  }
}
