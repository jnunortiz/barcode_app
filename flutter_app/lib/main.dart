import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data'; // Required for reading bytes
import 'package:file_picker/file_picker.dart';
import 'dart:io' as io;

void main() {
  runApp(BarcodeApp());
}

class BarcodeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode App',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Setting primarySwatch to define primaryColor
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
                    ? Colors.black.withOpacity(0.5) // Adjust opacity for disabled state
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
  List<String> _barcodes = [];
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
        _results.map((result) => result['terminal']).cast<String>().toList();
    List<String> eventsList =
        _results.map((result) => result['event']).cast<String>().toList();

    terminalsList.sort();
    eventsList.sort();

    setState(() {
      _uniqueTerminals = terminalsList.toSet();
      _uniqueEvents = eventsList.toSet();
    });
  }

  // Function to handle picking a file
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null) {
        // Access file content
        PlatformFile file = result.files.first;
        Uint8List bytes = file.bytes!;

        // Decode bytes to String
        String fileContent = utf8.decode(bytes);

        setState(() {
          _textController.text = fileContent;
          _clearResults(); // Clear results when new file is picked
        });
      }
    } catch (e) {
      print("Error picking file: $e");
      _showSnackBar('Error picking file: $e');
    }
  }

  // Function to handle barcode search
  Future<void> _searchBarcodes() async {
    setState(() {
      _isLoading = true;
      _barcodes = _textController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    });

    // Prepare request body with filters
    Map<String, dynamic> requestBody = {'barcodes': _barcodes};
    if (_selectedTerminal != null && _selectedTerminal!.isNotEmpty) {
      requestBody['terminal'] = _selectedTerminal!;
    }
    if (_selectedEvent != null && _selectedEvent!.isNotEmpty) {
      requestBody['event'] = _selectedEvent!;
    }

    // Send request to backend
    var url =
        Uri.parse('http://ec2-3-76-250-99.eu-central-1.compute.amazonaws.com:5000/search');
    try {
      var response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: 30)); // Timeout after 30 seconds

      if (response.statusCode == 200) {
        setState(() {
          _results = json.decode(response.body);
          _apiResponse = 'Search completed successfully.';
          _isLoading = false;
          _updateFilters(); // Update filters with new results
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        // Handle server error
        _showSnackBar('Error: ${response.reasonPhrase}');
        print('Error: ${response.reasonPhrase}');
      }
    } on io.SocketException catch (e) {
      print('Error: No internet connection');
      _showSnackBar('Error: No internet connection');
    } catch (e) {
      print('Error: $e');
      _showSnackBar('Error: $e');
    }
  }

  // Function to clear the input textbox
  void _clearInput() {
    setState(() {
      _textController.clear();
      _clearResults(); // Clear results when input is cleared
    });
  }

  // Function to clear the search results
  void _clearResults() {
    setState(() {
      _results.clear();
      _apiResponse = '';
      _updateFilters(); // Clear filters when results are cleared
      _selectedTerminal = null; // Reset selected terminal filter
      _selectedEvent = null; // Reset selected event filter
    });
  }

  // Function to show a SnackBar with a message
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
                  'Search Barcodes',
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
                      child: Text('Upload File'),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _searchBarcodes,
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
                labelText: 'Paste barcode numbers here',
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
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            var result = _results[index];
                            return ListTile(
                              title: Text('Barcode: ${result['barcode_number']}'),
                              subtitle: Text('Terminal: ${result['terminal']}, Event: ${result['event']}, Timestamp: ${result['timestamp']}'),
                            );
                          },
                        )),
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: _clearResults,
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
                child: Text('Clear Results'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Function to apply selected filters to search results
  void _applyFilters() {
    // Filter results based on selected terminal and event
    List<dynamic> filteredResults = _results;

    if (_selectedTerminal != null && _selectedTerminal!.isNotEmpty) {
      filteredResults = filteredResults
          .where((result) => result['terminal'] == _selectedTerminal)
          .toList();
    }

    if (_selectedEvent != null && _selectedEvent!.isNotEmpty) {
      filteredResults = filteredResults
          .where((result) => result['event'] == _selectedEvent)
          .toList();
    }

    setState(() {
      _results = filteredResults;
    });
  }
}
