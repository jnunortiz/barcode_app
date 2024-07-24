import 'dart:convert'; // For JSON decoding
import 'package:flutter/material.dart';
import 'file_service.dart'; // Import file service for file handling
import 'package:http/http.dart' as http; // Import HTTP package

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

  // Pagination state
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalResults = 0;

  @override
  void initState() {
    super.initState();
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
    var url = Uri.parse('http://localhost:5000/search?page=$_currentPage&size=$_pageSize');

    try {
      var response = await postRequest(url, requestBody).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _results = List<Map<String, dynamic>>.from(data['results']);
          _totalResults = data['total'];
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
    var lines = await FileService.pickAndReadFile();
    if (lines != null) {
      setState(() {
        _textController.text = lines.join('\n');
      });
    }
  }

  Future<void> _exportToCSV() async {
    await FileService.downloadCSV();
  }

  void _clearInput() {
    setState(() {
      _textController.clear(); // Only clear the input field
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  void _nextPage() {
    if (_currentPage * _pageSize < _totalResults) {
      setState(() {
        _currentPage++;
      });
      _searchPiecePins();
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _searchPiecePins();
    }
  }

  Future<http.Response> postRequest(Uri url, Map<String, dynamic> body) async {
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
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
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Search'),
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
            Flexible(
              child: TextField(
                controller: _textController,
                maxLines: 6,
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
            ),
            SizedBox(height: 20),
            Expanded(
              child: _results.isNotEmpty
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columns: _results.isNotEmpty
                              ? _results.first.keys
                                  .map((key) => DataColumn(label: Text(key)))
                                  .toList()
                              : [],
                          rows: _results
                              .map((result) => DataRow(
                                  cells: result.keys
                                      .map((key) =>
                                          DataCell(Text(result[key].toString())))
                                      .toList()))
                              .toList(),
                        ),
                      ),
                    )
                  : Center(child: Text('No results found.')),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _previousPage,
                  child: Text('Previous'),
                ),
                Text('Page $_currentPage'),
                ElevatedButton(
                  onPressed: _nextPage,
                  child: Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
