import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:recall_it/sqflite_crud_operations.dart';

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
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final SqfliteCrudOperations _dbOperations = SqfliteCrudOperations();

  List<Map<String, dynamic>> _loadedPoints = [];

  @override
  void initState() {
    super.initState();
    _fetchPointsFromDatabase();
  }

  Future<void> _fetchPointsFromDatabase() async {
    final points = await _dbOperations.getPoints();
    setState(() {
      _loadedPoints = points;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Hex Color Value',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _loadedPoints.length,
                itemBuilder: (context, index) {
                  final point = _loadedPoints[index];
                  return ListTile(
                    title: Text(point['description']),
                    subtitle: Text('ID: ${point['id']}, '
                        'Description: ${point['description']}, '
                        'Color: ${point['color']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      onPressed: () async {
                        await _dbOperations.deletePoint(point['id']);
                        await _fetchPointsFromDatabase();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPoint,
        tooltip: 'Add point',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addPoint() async {
    final description = _descriptionController.text;
    final colorHex = _colorController.text;

    if (description.isNotEmpty && colorHex.isNotEmpty) {
      await _dbOperations.insertPoint(description, colorHex);
      await _fetchPointsFromDatabase();
      _descriptionController.clear();
      _colorController.clear();
    }
  }
}
