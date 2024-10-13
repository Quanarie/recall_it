import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:recall_it/db_operations.dart';
import 'package:recall_it/utils/my_tile_builder.dart';

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

  static double tapThresholdScreenDistance = 50.0;

  Offset? _startingPointDragPosition;

  LatLng? _userCoordinates;
  final StreamController<LocationMarkerPosition> _userPositionStreamController =
      StreamController<LocationMarkerPosition>();
  static double zoomInUserLocationValue = 15.0;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _startListeningToUserLocationChanges();
    _fetchAndUpdatePoints();
  }

  Future<void> _startListeningToUserLocationChanges() async {
    Geolocator.getPositionStream().listen((Position p) {
      setState(() {
        _userCoordinates = LatLng(p.latitude, p.longitude);
        _userPositionStreamController.add(LocationMarkerPosition(
            latitude: p.latitude,
            longitude: p.longitude,
            accuracy: p.accuracy));
      });
    });
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
        backgroundColor: Colors.black87,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          onTap: (tapPosition, point) {
            _onMapTap(point);
          },
          initialCenter: const LatLng(51.509364, -0.128928),
          initialZoom: 3.2,
          interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'recall.it',
            tileBuilder: myTileBuilder,
          ),
          MarkerLayer(
            markers: [
              ..._loadedPointsToDisplay.map(
                (pointToBeMarkedOnMap) {
                  return Marker(
                    width: 120.0,
                    height: 120.0,
                    point: pointToBeMarkedOnMap.toLatLng(),
                    child: Center(
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
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 24),
                                  tooltip: 'Delete point',
                                  onPressed: () {
                                    _indexOfPointWithVisibleDescription = null;
                                    _deletePoint(pointToBeMarkedOnMap);
                                    _fetchAndUpdatePoints();
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          CurrentLocationLayer(
            positionStream: _userPositionStreamController.stream,
            style: LocationMarkerStyle(
              marker: DefaultLocationMarker(
                child: Container(
                  width: 20.0,
                  height: 20.0,
                  decoration: const BoxDecoration(
                    color: Color(0x907900FF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              markerSize: const Size(20, 20),
              markerDirection: MarkerDirection.heading,
              headingSectorRadius: 100,
              headingSectorColor: const Color(0x907900FF),
              accuracyCircleColor: const Color(0x1AA327F5),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _zoomToUserLocation,
        tooltip: 'Zoom to My Location',
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location, color: Colors.black87),
      ),
    );
  }

  void _zoomToUserLocation() {
    if (_userCoordinates != null) {
      mapController.move(_userCoordinates!, zoomInUserLocationValue);
    }
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
      var indexOfClosestPointToTap = _findClosestPointIndex(tapCoordinates);
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

  int? _findClosestPointIndex(LatLng point) {
    double closestDistance = double.infinity;
    int? closestPoint;

    for (int i = 0; i < _loadedPointsToDisplay.length; i++) {
      MyPoint loadedPoint = _loadedPointsToDisplay[i];
      double distance = _calculateDistance(
        point,
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

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          dev.log("Location permissions are denied");
        });
      } else if (permission == LocationPermission.deniedForever) {
        setState(() {
          dev.log("Location permissions are permanently denied");
        });
      } else {
        dev.log("Location permissions granted");
      }
    } else if (permission == LocationPermission.deniedForever) {
      setState(() {
        dev.log("Location permissions are permanently denied");
      });
    } else {
      dev.log("Location permissions granted");
    }
  }

  void _savePointToDb(MyPoint point) {
    _dbOperations.insertPoint(point);
  }

  void _updatePointPositionInDb(MyPoint pointToBeMarkedOnMap) {
    _dbOperations.updatePointCoordinates(
        pointToBeMarkedOnMap.id!, pointToBeMarkedOnMap.toLatLng());
  }

  void _deletePoint(MyPoint pointToBeDeleted) {
    _dbOperations.deletePoint(pointToBeDeleted.id!);
  }
}
