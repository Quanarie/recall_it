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

  List<LatLng> _loadedPointsToDisplay = [];

  @override
  void initState() {
    super.initState();
    _fetchPointsFromDatabase();
  }

  Future<void> _fetchPointsFromDatabase() async {
    final points = await _dbOperations.getPoints();
    setState(() {
      _loadedPointsToDisplay = points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    });
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
                point: point,
                child:
                    const Icon(Icons.location_on, color: Colors.red, size: 40),
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

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//       title: Text(widget.title),
//     ),
//     body: Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: <Widget>[
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextFormField(
//               controller: _descriptionController,
//               decoration: const InputDecoration(
//                 labelText: 'Description',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextFormField(
//               controller: _colorController,
//               decoration: const InputDecoration(
//                 labelText: 'Hex Color Value',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _loadedPoints.length,
//               itemBuilder: (context, index) {
//                 final point = _loadedPoints[index];
//                 return ListTile(
//                   title: Text(point['description']),
//                   subtitle: Text('ID: ${point['id']}, '
//                       'Description: ${point['description']}, '
//                       'Color: ${point['color']}'),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.delete),
//                     color: Colors.red,
//                     onPressed: () async {
//                       await _dbOperations.deletePoint(point['id']);
//                       await _fetchPointsFromDatabase();
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     ),
//     floatingActionButton: FloatingActionButton(
//       onPressed: _addPoint,
//       tooltip: 'Add point',
//       child: const Icon(Icons.add),
//     ),
//   );
// }

// Future<void> _addPoint() async {
//   final description = _descriptionController.text;
//   final colorHex = _colorController.text;
//
//   if (description.isNotEmpty && colorHex.isNotEmpty) {
//     await _dbOperations.insertPoint(description, colorHex);
//     await _fetchPointsFromDatabase();
//     _descriptionController.clear();
//     _colorController.clear();
//   }
// }
}
