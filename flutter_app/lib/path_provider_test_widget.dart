import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() => runApp(PathProviderTestApp());

class PathProviderTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PathProviderTestScreen(),
    );
  }
}

class PathProviderTestScreen extends StatefulWidget {
  @override
  _PathProviderTestScreenState createState() => _PathProviderTestScreenState();
}

class _PathProviderTestScreenState extends State<PathProviderTestScreen> {
  String _message = 'Press the button to test path provider';

  Future<void> _testPathProvider() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;
      final file = File('$path/test_file.txt');
      await file.writeAsString('This is a test file.');
      setState(() {
        _message = 'File written to $path/test_file.txt';
      });
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Path Provider Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _testPathProvider,
              child: Text('Test Path Provider'),
            ),
            SizedBox(height: 20),
            Text(_message),
          ],
        ),
      ),
    );
  }
}
