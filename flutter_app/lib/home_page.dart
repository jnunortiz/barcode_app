// lib/home_page.dart
import 'package:flutter/material.dart';
import 'services.dart';
import 'widgets.dart'; // Import the widgets.dart file
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';

/// The home page widget where users can interact with the app.
class BarcodeHomePage extends StatefulWidget {
  @override
  _BarcodeHomePageState createState() => _BarcodeHomePageState();
}

class _BarcodeHomePageState extends State<BarcodeHomePage> {
  TextEditingController _textController = TextEditingController();
  List<String> _piecePins = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String _apiResponse = '';

  @override
  void initState() {
    super.initState();

    // Listen to text changes to update the state
    _textController.addListener(() {
      setState(() {}); // Rebuild the widget when text changes
    });
  }

  Future<void> _searchPiecePins() async {
    setState(() {
      _isLoading = true;
      _piecePins = _textController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    });

    Map<String, dynamic> requestBody = {'piece_pins': _piecePins};
    var url = Uri.parse('http://localhost:5000/search');
    
    try {
      var response = await postRequest(url, requestBody).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        setState(() {
          _results = List<Map<String, dynamic>>.from(json.decode(response.body));
          _apiResponse = 'Search completed successfully.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _apiResponse = 'Error: ${response.reasonPhrase}';
        });
        _showSnackBar(_apiResponse);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _apiResponse = 'Error: $e';
      });
      _showSnackBar(_apiResponse);
    }
  }

  void _clearResults() {
    setState(() {
      _results.clear();
    });
  }

  Future<void> _pickAndLoadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final bytes = result.files.single.bytes;
      if (bytes != null) {
        String content = utf8.decode(bytes);
        List<String> lines = content.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
        setState(() {
          _textController.text = lines.join('\n');
        });
      } else {
        _showSnackBar('Error reading the file.');
      }
    } else {
      _showSnackBar('No file selected.');
    }
  }

  void _clearInput() {
    setState(() {
      _textController.clear();
      _clearResults();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Barcode App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Search Piece Pins',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _searchPiecePins,
                      child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Search'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _clearResults,
                      child: Text('Clear Results'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _exportToCSV,
                      child: Text('Export to CSV'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _pickAndLoadFile,
                      child: Text('Upload File'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _textController,
              maxLines: 10,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Piece Pins',
                hintText: 'Enter or paste piece pins here...',
                suffixIcon: _textController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: _clearInput,
                      )
                    : null,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _results.isNotEmpty
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: CustomWidgetBuilder.getColumns(_results),
                        rows: _results
                            .map((result) => DataRow(cells: CustomWidgetBuilder.getCells(result)))
                            .toList(),
                      ),
                    )
                  : Center(child: Text('No results found.')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToCSV() async {
    List<List<dynamic>> rows = [];
    if (_results.isNotEmpty) {
      rows.add(_results.first.keys.toList());
      for (var result in _results) {
        rows.add(result.values.toList());
      }

      String csv = const ListToCsvConverter().convert(rows);

      final directory = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      final path = '${directory.path}\\results.csv';
      final file = File(path);
      await file.writeAsString(csv);

      _showSnackBar('CSV exported to $path');
    } else {
      _showSnackBar('No data available to export.');
    }
  }
}
