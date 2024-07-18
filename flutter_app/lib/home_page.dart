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
  bool _isSearching = false; // Track if a search is in progress
  bool _isExporting = false; // Track if export is in progress
  String _apiResponse = '';

  // Pagination state
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalResults = 0;

  // File processing state
  int _linesRead = 0;
  bool _hasSearched = false;
  String _lastSearchQuery = ''; // Store the last search query

  // Column filter state
  List<String> _allColumns = []; // List of all column names
  List<String> _selectedColumns = []; // List of selected column names
  bool _showColumnFilter = false; // Show/hide column filter menu

  // Scroll controller
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _searchPiecePins({String? query}) async {
    final searchQuery = query ?? _lastSearchQuery;

    if (searchQuery.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _piecePins = searchQuery
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _lastSearchQuery = searchQuery;
      _hasSearched = true;
    });

    Map<String, dynamic> requestBody = {'piece_pins': _piecePins};
    var url = Uri.parse('http://fastapi-app-load-balancer-2141658843.eu-central-1.elb.amazonaws.com/search?page=$_currentPage&size=$_pageSize');

    try {
      var response = await postRequest(url, requestBody).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _results = List<Map<String, dynamic>>.from(data['results']);
          _totalResults = data['total'];
          _apiResponse = 'Search completed successfully.';
          _isSearching = false;
          _allColumns = _results.isNotEmpty ? _results.first.keys.toList() : [];
          // Ensure that previously selected columns remain selected
          _selectedColumns = _selectedColumns.isEmpty ? List.from(_allColumns) : _selectedColumns;
        });
        _scrollToTop(); // Scroll to the top after results are updated
      } else {
        setState(() {
          _isSearching = false;
          _apiResponse = 'Error: ${response.reasonPhrase}';
        });
        _showSnackBar(_apiResponse);
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _apiResponse = 'Error: $e';
      });
      _showSnackBar(_apiResponse);
    }
  }

  void _clearInput() {
    setState(() {
      _textController.clear();
      // Do not clear results or pagination state
    });
  }

  Future<void> _pickAndLoadFile() async {
    var lines = await FileService.pickAndReadFile();
    if (lines != null) {
      setState(() {
        _textController.text = lines.join('\n');
        _linesRead = lines.length;
        _hasSearched = false;
      });
    }
  }

  Future<void> _exportToCSV() async {
    setState(() {
      _isExporting = true; // Show progress indicator
    });

    try {
      if (_piecePins.isEmpty || _selectedColumns.isEmpty) {
        _showSnackBar('No data to export or no columns selected.');
        return;
      }
      await FileService.downloadCSV(_piecePins, _selectedColumns);
      _showSnackBar('Export completed successfully.');
    } catch (e) {
      _showSnackBar('Error during export: $e');
    } finally {
      setState(() {
        _isExporting = false; // Hide progress indicator
      });
    }
  }

  void _clearResults() {
    setState(() {
      _results.clear();
      _hasSearched = false;
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
      _searchPiecePins(query: _lastSearchQuery);
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
      _searchPiecePins(query: _lastSearchQuery);
    }
  }

  void _scrollToTop() {
    // Scroll to the top of the results view
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<http.Response> postRequest(Uri url, Map<String, dynamic> body) async {
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
  }

  void _applyColumnFilter() {
    setState(() {
      // Update results based on selected columns
      _results = _results.map((row) {
        return Map.fromEntries(
          _selectedColumns.map((column) => MapEntry(column, row[column])),
        );
      }).toList();
      _showColumnFilter = false; // Close the filter menu after applying filter
    });
  }

  void _selectAllColumns() {
    setState(() {
      _selectedColumns = List.from(_allColumns);
    });
  }

  void _deselectAllColumns() {
    setState(() {
      _selectedColumns.clear();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Dispose of the controller when done
    super.dispose();
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
            if (_linesRead > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Text('Lines read from file: $_linesRead',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
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
                Wrap(
                  spacing: 8, // Spacing between buttons
                  children: [
                    _buildButton(
                      text: 'Search',
                      isLoading: _isSearching,
                      onPressed: () => _searchPiecePins(query: _textController.text),
                    ),
                    _buildButton(
                      text: 'Clear Results',
                      onPressed: _clearResults,
                    ),
                    _buildButton(
                      text: 'Export to CSV',
                      isLoading: _isExporting,
                      onPressed: _exportToCSV,
                    ),
                    _buildButton(
                      text: 'Upload File',
                      onPressed: _pickAndLoadFile,
                    ),
                    _buildButton(
                      text: _showColumnFilter ? 'Close Filter' : 'Column Filter',
                      onPressed: () {
                        setState(() {
                          _showColumnFilter = !_showColumnFilter;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            if (_showColumnFilter) ...[
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildButton(
                    text: 'Select All',
                    onPressed: _selectAllColumns,
                  ),
                  _buildButton(
                    text: 'Deselect All',
                    onPressed: _deselectAllColumns,
                  ),
                ],
              ),
              SizedBox(height: 20),
              _buildColumnFilter(),
              SizedBox(height: 20),
              _buildButton(
                text: 'Apply Filter',
                onPressed: _applyColumnFilter,
              ),
            ],
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
              child: _selectedColumns.isNotEmpty
                  ? SingleChildScrollView(
                      controller: _scrollController,
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: _selectedColumns
                              .map((column) => DataColumn(label: Text(column)))
                              .toList(),
                          rows: _results
                              .map((result) => DataRow(
                                  cells: _selectedColumns
                                      .map((column) => DataCell(Text(result[column]?.toString() ?? '')))
                                      .toList()))
                              .toList(),
                        ),
                      ),
                    )
                  : Center(child: Text('No columns selected.')),
            ),
            if (_hasSearched)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildButton(
                      text: 'Previous',
                      onPressed: _previousPage,
                    ),
                    Text('Page $_currentPage'),
                    _buildButton(
                      text: 'Next',
                      onPressed: _nextPage,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Columns to Display:'),
        Wrap(
          spacing: 8.0,
          children: _allColumns.map((column) {
            return FilterChip(
              label: Text(column),
              selected: _selectedColumns.contains(column),
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    _selectedColumns.add(column);
                  } else {
                    _selectedColumns.remove(column);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildButton({required String text, bool isLoading = false, required VoidCallback onPressed}) {
    return SizedBox(
      width: 120, // Adjusted width for a smaller button
      height: 36, // Adjusted height for a smaller button
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12), // Adjusted font size
              ),
      ),
    );
  }
}
