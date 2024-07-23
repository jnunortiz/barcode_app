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
  List<dynamic> _results = [];
  bool _isLoading = false;
  String _apiResponse = '';
  Set<String> _uniqueTerminals = Set();
  Set<String> _uniqueEvents = Set();
  String? _selectedTerminal;
  String? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _updateFilters();
  }

  void _updateFilters() {
    List<String> terminalsList =
        _results.map((result) => result['Terminal Name']).cast<String>().toList();
    List<String> eventsList =
        _results.map((result) => result['Event Code Desc[Eng]']).cast<String>().toList();

    terminalsList.sort();
    eventsList.sort();

    setState(() {
      _uniqueTerminals = terminalsList.toSet();
      _uniqueEvents = eventsList.toSet();
    });
  }

  Future<void> _pickFile() async {
    // File picking logic here if needed
    // You may not need this if you're using text input directly
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
          _results = json.decode(response.body);
          _apiResponse = 'Search completed successfully.';
          _isLoading = false;
          _updateFilters();
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error: ${response.reasonPhrase}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error: $e');
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
      _apiResponse = '';
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
                DropdownButton<String>(
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
                SizedBox(width: 10),
                DropdownButton<String>(
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
              ],
            ),
            SizedBox(height: 20),
            Text(
              _apiResponse,
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : (_results.isEmpty
                      ? Center(child: Text('No results found.'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('Piece Pin')),
                              DataColumn(label: Text('Scan Date')),
                              DataColumn(label: Text('Scan Time')),
                              DataColumn(label: Text('Terminal Name')),
                              DataColumn(label: Text('Event Code Desc[Eng]')),
                              DataColumn(label: Text('Expected Delivery Date')),
                              DataColumn(label: Text('Service Date')),
                              DataColumn(label: Text('Origin City')),
                              DataColumn(label: Text('Destination City')),
                              // Add more columns if needed
                            ],
                            rows: _results.map((result) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(result['Piece Pin'])),
                                  DataCell(Text(result['Scan Date'])),
                                  DataCell(Text(result['Scan Time'])),
                                  DataCell(Text(result['Terminal Name'])),
                                  DataCell(Text(result['Event Code Desc[Eng]'])),
                                  DataCell(Text(result['Expected Delivery Date'])),
                                  DataCell(Text(result['Service Date'])),
                                  DataCell(Text(result['Origin City'])),
                                  DataCell(Text(result['Destination City'])),
                                  // Add more cells if needed
                                ],
                              );
                            }).toList(),
                          ),
                        )),
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: _clearResults,
                child: Text('Clear Results'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFilters() {
    List<dynamic> filteredResults = _results;

    if (_selectedTerminal != null && _selectedTerminal!.isNotEmpty) {
      filteredResults = filteredResults
          .where((result) => result['Terminal Name'] == _selectedTerminal)
          .toList();
    }

    if (_selectedEvent != null && _selectedEvent!.isNotEmpty) {
      filteredResults = filteredResults
          .where((result) => result['Event Code Desc[Eng]'] == _selectedEvent)
          .toList();
    }

    setState(() {
      _results = filteredResults;
    });
  }
}
