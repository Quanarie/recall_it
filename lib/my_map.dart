// import 'dart:developer' as dev;
import 'dart:developer' as dev;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

import 'db_operations.dart';
import 'models/my_point.dart';
import 'utils/color.dart';
import 'utils/my_point.dart';
import 'utils/my_tile_builder.dart';

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
  int? _indexOfPointWithOpenedDescription;

  static double tapThresholdScreenDistance = 50.0;

  Offset? _startingPointDragPosition;

  late final Stream<LocationMarkerPosition?> _userPositionStream;
  LocationMarkerPosition? _mostRecentUserPosition;
  late final Stream<LocationMarkerHeading?> _userHeadingStream;
  static double zoomInUserLocationValue = 15.0;

  @override
  void initState() {
    super.initState();
    _setupLocationStreams();
    _listenToUserPositionChanges();
    _fetchAndUpdatePoints();
  }

  Future<void> _setupLocationStreams() async {
    const factory = LocationMarkerDataStreamFactory();
    _userPositionStream =
        factory.fromGeolocatorPositionStream().asBroadcastStream();
    _userHeadingStream = factory.fromCompassHeadingStream().asBroadcastStream();
  }

  void _listenToUserPositionChanges() {
    _userPositionStream.listen((position) {
      _mostRecentUserPosition = position;
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
          _getUserLocationMarkerLayer(),
          _getMarkerLayer(),
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

  MarkerLayer _getMarkerLayer() {
    return MarkerLayer(
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
                      if (_isPointWithOpenedDescription(pointToBeMarkedOnMap))
                        _getPointDescription(pointToBeMarkedOnMap),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isPointWithOpenedDescription(MyPoint pointToBeMarkedOnMap) {
    return _indexOfPointWithOpenedDescription != null &&
        _indexOfPointWithOpenedDescription ==
            _loadedPointsToDisplay.indexOf(pointToBeMarkedOnMap);
  }

  Container _getPointDescription(MyPoint pointToBeMarkedOnMap) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.delete, color: Colors.black87, size: 24),
        tooltip: 'Delete point',
        onPressed: () {
          _indexOfPointWithOpenedDescription = null;
          _deletePoint(pointToBeMarkedOnMap);
          _fetchAndUpdatePoints();
        },
      ),
    );
  }

  CurrentLocationLayer _getUserLocationMarkerLayer() {
    return CurrentLocationLayer(
      positionStream: _userPositionStream,
      headingStream: _userHeadingStream,
    );
  }

  void _zoomToUserLocation() async {
    if (_mostRecentUserPosition != null) {
      mapController.move(
          LatLng(_mostRecentUserPosition!.latitude,
              _mostRecentUserPosition!.longitude),
          zoomInUserLocationValue);
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
      var indexOfClosestPointToTap = findIndexOfClosestPointToGivenCoordinates(
          tapCoordinates, _loadedPointsToDisplay);
      if (arePointsCloseEnoughOnScreen(
        tapCoordinates,
        _loadedPointsToDisplay[indexOfClosestPointToTap!].toLatLng(),
        mapController.camera,
        tapThresholdScreenDistance,
      )) {
        if (_indexOfPointWithOpenedDescription == indexOfClosestPointToTap) {
          _closeOpenedPointDescription();
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

  void _openPointDescription(int indexOfClosestPointToTap) {
    _indexOfPointWithOpenedDescription = indexOfClosestPointToTap;
    setState(() {});
  }

  void _closeOpenedPointDescription() {
    _indexOfPointWithOpenedDescription = null;
    setState(() {});
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
