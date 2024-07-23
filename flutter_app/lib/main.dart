import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(BarcodeApp());
}

class BarcodeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                return states.contains(WidgetState.disabled)
                    ? Colors.grey
                    : Colors.blue;
              },
            ),
            foregroundColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                return states.contains(WidgetState.disabled)
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black;
              },
            ),
          ),
        ),
      ),
      home: BarcodeHomePage(),
    );
  }
}

class BarcodeHomePage extends StatefulWidget {
  @override
  _BarcodeHomePageState createState() => _BarcodeHomePageState();
}

class _BarcodeHomePageState extends State<BarcodeHomePage> {
  TextEditingController _textController = TextEditingController();
  List<String> _piecePins = [];
  List<Map<String, dynamic>> _results = []; // Ensure _results is a List<Map<String, dynamic>>
  bool _isLoading = false;
  Set<String> _uniqueTerminals = Set();
  Set<String> _uniqueEvents = Set();
  String? _selectedTerminal;
  String? _selectedEvent;
  String _apiResponse = '';

  @override
  void initState() {
    super.initState();
    _updateFilters();
  }

  void _updateFilters() {
    List<String> terminalsList =
        _results.map((result) => result['Terminal Name'] as String).toList();
    List<String> eventsList =
        _results.map((result) => result['Event Code Desc[Eng]'] as String).toList();

    terminalsList.sort();
    eventsList.sort();

    setState(() {
      _uniqueTerminals = terminalsList.toSet();
      _uniqueEvents = eventsList.toSet();
    });
  }

  Future<void> _pickFile() async {
    // File picking logic here if needed
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

    // Prepare request body with filters
    Map<String, dynamic> requestBody = {'piece_pins': _piecePins};
    if (_selectedTerminal != null && _selectedTerminal!.isNotEmpty) {
      requestBody['terminal'] = _selectedTerminal!;
    }
    if (_selectedEvent != null && _selectedEvent!.isNotEmpty) {
      requestBody['event'] = _selectedEvent!;
    }

    var url = Uri.parse('http://localhost:5000/search');
    try {
      var response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        setState(() {
          _results = List<Map<String, dynamic>>.from(json.decode(response.body)); // Ensure the correct type
          _apiResponse = 'Search completed successfully.';
          _isLoading = false;
          _updateFilters();
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

  void _clearInput() {
    setState(() {
      _textController.clear();
      _clearResults();
    });
  }

  void _clearResults() {
    setState(() {
      _results.clear();
      _updateFilters();
      _selectedTerminal = null;
      _selectedEvent = null;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  List<DataColumn> _getColumns() {
    if (_results.isNotEmpty) {
      var firstResult = _results.first;
      return firstResult.keys.map((key) => DataColumn(label: Text(key))).toList();
    } else {
      return [
        DataColumn(label: Text('No Data')),
      ];
    }
  }

  List<DataCell> _getCells(Map<String, dynamic> result) {
    return result.keys.map((key) {
      var value = result[key];
      return DataCell(
        Text(
          value != null ? value.toString() : '',
          overflow: TextOverflow.ellipsis, // Handle overflow gracefully
        ),
      );
    }).toList();
  }

  void _applyFilters() {
    setState(() {
      // Apply filters here if needed
    });
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
                      onPressed: _pickFile,
                      child: Text('Upload File'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _searchPiecePins,
                      child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Search'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Paste piece pin numbers here',
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: _clearInput,
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedTerminal,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedTerminal = newValue!;
                        _applyFilters();
                      });
                    },
                    items: _uniqueTerminals
                        .map((String terminal) =>
                            DropdownMenuItem<String>(value: terminal, child: Text(terminal)))
                        .toList(),
                    hint: Text('Select Terminal'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedEvent,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedEvent = newValue!;
                        _applyFilters();
                      });
                    },
                    items: _uniqueEvents
                        .map((String event) =>
                            DropdownMenuItem<String>(value: event, child: Text(event)))
                        .toList(),
                    hint: Text('Select Event'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (_apiResponse.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _apiResponse,
                  style: TextStyle(
                    fontSize: 16,
                    color: _apiResponse.startsWith('Error') ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ],
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: _getColumns(),
                  rows: _results.map((result) {
                    return DataRow(cells: _getCells(result));
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
