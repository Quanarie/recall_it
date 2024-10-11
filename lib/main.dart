import 'dart:developer';

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

  List<Point> _loadedPointsToDisplay = [];

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
    // log("Loaded: ${_loadedPointsToDisplay.map((e) => e.toString()).join(", ")}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FlutterMap(
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
            markers: _loadedPointsToDisplay.map((point) {
              return Marker(
                width: 80.0,
                height: 80.0,
                point: _pointToLatLng(point),
                child: Icon(Icons.location_on,
                    color: _hexToColor(point.hexColor), size: 40),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _onMapTap(LatLng point) {
    _savePoint(
      Point(
        latitude: point.latitude,
        longitude: point.longitude,
      ),
    );
    _fetchPointsFromDatabase();
  }

  void _savePoint(Point point) {
    _dbOperations.insertPoint(point);
  }

  LatLng _pointToLatLng(Point point) {
    return LatLng(point.latitude, point.longitude);
  }

  Color _hexToColor(String hexColor) {
    // log("Parsing $hexColor to ${int.parse(hexColor, radix: 16)}");
    return Color(int.parse(hexColor, radix: 16));
  }
}
