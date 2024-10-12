// import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:recall_it/sqflite_crud_operations.dart';

import 'models/point.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recallit',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Recallit'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SqfliteCrudOperations _dbOperations = SqfliteCrudOperations();
  final mapController = MapController();

  List<Point> _loadedPointsToDisplay = [];
  int? _indexOfPointWithVisibleDescription;

  static double tapThresholdScreenDistance = 20;

  Offset? _startingOffsetForDraggedPoint;

  @override
  void initState() {
    super.initState();
    _fetchPointsFromDatabase();
  }

  Future<void> _fetchPointsFromDatabase() async {
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
                      _startingOffsetForDraggedPoint = mapController.camera
                          .latLngToScreenPoint(pointToBeMarkedOnMap.toLatLng())
                          .toOffset();
                    },
                    onLongPressMoveUpdate: (details) {
                      setState(() {
                        Offset offsetInPixels = details.offsetFromOrigin;

                        Offset newScreenPosition =
                            _startingOffsetForDraggedPoint! + offsetInPixels;
                        LatLng newWorldPosition =
                            mapController.camera.offsetToCrs(newScreenPosition);

                        pointToBeMarkedOnMap.latitude =
                            newWorldPosition.latitude;
                        pointToBeMarkedOnMap.longitude =
                            newWorldPosition.longitude;
                      });
                    },
                    onLongPressEnd: (details) {
                      _dbOperations.updatePointCoordinates(
                          pointToBeMarkedOnMap.id!,
                          pointToBeMarkedOnMap.toLatLng());
                      _fetchPointsFromDatabase();
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _hexToColor(pointToBeMarkedOnMap.hexColor),
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

  void _onMapTap(LatLng tapCoordinates) {
    LatLng? coordinatesToBeSavedAsPoint;

    var noPointsOnMap = _loadedPointsToDisplay.isEmpty;

    if (noPointsOnMap) {
      coordinatesToBeSavedAsPoint = tapCoordinates;
    } else {
      var indexOfClosestPointToTap = _findClosestPointIndex(tapCoordinates);
      if (_arePointsCloseEnoughOnScreen(tapCoordinates,
          _loadedPointsToDisplay[indexOfClosestPointToTap!].toLatLng())) {
        if (_indexOfPointWithVisibleDescription == indexOfClosestPointToTap) {
          _closeVisiblePointDescription();
        } else {
          _openDescriptionOfPoint(indexOfClosestPointToTap);
        }
      } else {
        coordinatesToBeSavedAsPoint = tapCoordinates;
      }
    }

    if (coordinatesToBeSavedAsPoint != null) {
      _savePoint(Point.fromLatLng(coordinatesToBeSavedAsPoint));
      _fetchPointsFromDatabase();
    }
  }

  int? _findClosestPointIndex(LatLng point) {
    double closestDistance = double.infinity;
    int? closestIndex;
    double distance = closestDistance;

    for (int i = 0; i < _loadedPointsToDisplay.length; i++) {
      Point loadedPoint = _loadedPointsToDisplay[i];
      distance = _calculateDistance(
        point,
        loadedPoint.toLatLng(),
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((p2.latitude - p1.latitude) * p) / 2 +
        c(p1.latitude * p) *
            c(p2.latitude * p) *
            (1 - c((p2.longitude - p1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a));
  }

  bool _arePointsCloseEnoughOnScreen(LatLng point1, LatLng point2) {
    var camera = mapController.camera;
    var p1 = camera.latLngToScreenPoint(point1);
    var p2 = camera.latLngToScreenPoint(point2);
    return p1.distanceTo(p2) <= tapThresholdScreenDistance;
  }

  void _openDescriptionOfPoint(int indexOfClosestPointToTap) {
    _indexOfPointWithVisibleDescription = indexOfClosestPointToTap;
    setState(() {});
  }

  void _closeVisiblePointDescription() {
    _indexOfPointWithVisibleDescription = null;
    setState(() {});
  }

  void _savePoint(Point point) {
    _dbOperations.insertPoint(point);
  }

  Color _hexToColor(String hexColor) {
    return Color(int.parse(hexColor, radix: 16));
  }
}
