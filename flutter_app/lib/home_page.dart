import 'dart:convert';
import 'package:flutter/material.dart';
import 'file_service.dart';
import 'package:http/http.dart' as http;

class BarcodeHomePage extends StatefulWidget {
  @override
  _BarcodeHomePageState createState() => _BarcodeHomePageState();
}

class _BarcodeHomePageState extends State<BarcodeHomePage> {
  TextEditingController _textController = TextEditingController();
  List<String> _piecePins = [];
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;
  bool _isExporting = false;
  bool _isLoadingNext = false;
  bool _isLoadingPrevious = false;
  String _apiResponse = '';

  int _currentPage = 1;
  int _pageSize = 20;
  int _totalResults = 0;

  int _linesRead = 0;
  bool _hasSearched = false;
  String _lastSearchQuery = '';

  List<String> _allColumns = [];
  List<String> _selectedColumns = [];
  bool _showColumnFilter = false;

  ScrollController _scrollController = ScrollController();
  int _maxLines = 22;

  // Cache for paginated results
  Map<int, List<Map<String, dynamic>>> _resultsCache = {};

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _searchPiecePins({String? query, int page = 1}) async {
    final searchQuery = query ?? _textController.text;

    if (searchQuery.trim().isEmpty) return;

    setState(() {
      if (page == 1) {
        _isSearching = true;
      } else if (page > _currentPage) {
        _isLoadingNext = true;
      } else {
        _isLoadingPrevious = true;
      }
      _piecePins = searchQuery
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      _lastSearchQuery = searchQuery;
      _hasSearched = true;
    });

    Map<String, dynamic> requestBody = {'piece_pins': _piecePins};
    var url = Uri.parse(
        'http://fastapi-app-load-balancer-2141658843.eu-central-1.elb.amazonaws.com/search?page=$page&size=$_pageSize');

    try {
      var response = await postRequest(url, requestBody).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          _resultsCache[page] = List<Map<String, dynamic>>.from(data['results']);
          _results = _resultsCache[page]!;
          _totalResults = data['total'];
          _apiResponse = 'Search completed successfully.';
          _allColumns = _results.isNotEmpty ? _results.first.keys.toList() : [];
          _selectedColumns = _selectedColumns.isEmpty ? List.from(_allColumns) : _selectedColumns;
        });
        _scrollToTop();
      } else {
        setState(() {
          _apiResponse = 'Error: ${response.reasonPhrase}';
        });
        _showSnackBar(_apiResponse);
      }
    } catch (e) {
      setState(() {
        _apiResponse = 'Error: $e';
      });
      _showSnackBar(_apiResponse);
    } finally {
      setState(() {
        _isSearching = false;
        _isLoadingNext = false;
        _isLoadingPrevious = false;
      });
    }
  }

  void _clearInput() {
    setState(() {
      _textController.clear();
      _piecePins.clear(); // Clear the input pin codes
      _lastSearchQuery = ''; // Reset last search query
      // Do not clear _results or reset _currentPage; preserve the results and pagination
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
      _isExporting = true;
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
        _isExporting = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _results.clear();
      _piecePins.clear();
      _textController.clear();
      _lastSearchQuery = '';
      _hasSearched = false;
      _currentPage = 1; // Reset to the first page
      _totalResults = 0;
      _resultsCache.clear(); // Clear the cache
      _allColumns.clear(); // Clear the column list
      _selectedColumns.clear(); // Clear selected columns
      _showColumnFilter = false; // Hide column filter
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: 3),
    ));
  }

  void _nextPage() {
    if (_currentPage * _pageSize < _totalResults && !_isLoadingNext) {
      setState(() {
        _currentPage++;
      });
      if (_resultsCache.containsKey(_currentPage)) {
        setState(() {
          _results = _resultsCache[_currentPage]!;
        });
      } else {
        _searchPiecePins(query: _lastSearchQuery, page: _currentPage);
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 1 && !_isLoadingPrevious) {
      setState(() {
        _currentPage--;
      });
      if (_resultsCache.containsKey(_currentPage)) {
        setState(() {
          _results = _resultsCache[_currentPage]!;
        });
      } else {
        _searchPiecePins(query: _lastSearchQuery, page: _currentPage);
      }
    }
  }

  void _scrollToTop() {
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
    if (_selectedColumns.isEmpty) {
      _showSnackBar('No columns selected.');
      return;
    }

    if (_resultsCache.containsKey(_currentPage)) {
      setState(() {
        _results = _resultsCache[_currentPage]!.map((row) {
          return Map.fromEntries(
            _selectedColumns.map((column) => MapEntry(column, row[column])),
          );
        }).toList();
      });
    } else {
      _showSnackBar('No data available for the current page.');
    }

    _showColumnFilter = false;
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
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasCachedResults = _resultsCache.isNotEmpty;
    bool showNoColumnsMessage = hasCachedResults && _selectedColumns.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 40),
            SizedBox(width: 16),
          ],
        ),
        backgroundColor: Color(0xFF969DD6),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _clearResults,
            color: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 250,
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF00A9CE), width: 2.0),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: _maxLines,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Enter Piece Pins',
                        labelStyle: TextStyle(color: Color(0xFF001996)),
                        hintText: 'Enter or paste piece pins here...',
                        hintStyle: TextStyle(color: Color(0xFF000000)),
                        suffixIcon: _textController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: _clearInput,
                                color: Color(0xFF001996),
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: [
                                _buildButton(
                                  text: 'Search',
                                  isLoading: _isSearching,
                                  onPressed: () => _searchPiecePins(),
                                  color: Color(0xFF003366),
                                ),
                                _buildButton(
                                  text: 'Clear Results',
                                  onPressed: _clearResults,
                                  color: Color(0xFF003366),
                                ),
                                _buildButton(
                                  text: 'Export to CSV',
                                  isLoading: _isExporting,
                                  onPressed: _exportToCSV,
                                  color: Color(0xFF003366),
                                ),
                                _buildButton(
                                  text: 'Upload File',
                                  onPressed: _pickAndLoadFile,
                                  color: Color(0xFF003366),
                                ),
                                _buildButton(
                                  text: _showColumnFilter ? 'Close Filter' : 'Column Filter',
                                  onPressed: () {
                                    setState(() {
                                      _showColumnFilter = !_showColumnFilter;
                                    });
                                  },
                                  color: Color(0xFF003366),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        if (_showColumnFilter) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildButton(
                                text: 'Select All',
                                onPressed: _selectAllColumns,
                                color: Color(0xFFF00000),
                              ),
                              _buildButton(
                                text: 'Deselect All',
                                onPressed: _deselectAllColumns,
                                color: Color(0xFFF00000),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          _buildColumnFilter(),
                          SizedBox(height: 20),
                          _buildButton(
                            text: 'Apply Filter',
                            onPressed: _applyColumnFilter,
                            color: Color(0xFF003366),
                          ),
                        ],
                        SizedBox(height: 20),
                        if (_selectedColumns.isNotEmpty) ...[
                          Container(
                            height: 400,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 16,
                                  headingRowHeight: 40,
                                  dataRowMinHeight: 36,
                                  headingRowColor: WidgetStateProperty.all(Color(0xFF003366)),
                                  columns: _selectedColumns
                                      .map((column) => DataColumn(
                                            label: Text(
                                              column,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  rows: _results
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                        int index = entry.key;
                                        Map<String, dynamic> result = entry.value;
                                        return DataRow(
                                          color: WidgetStateProperty.resolveWith<Color?>(
                                            (states) => index.isEven
                                                ? Colors.white
                                                : Color(0xFFE3F2FD),
                                          ),
                                          cells: _selectedColumns
                                              .map((column) => DataCell(
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                                                      child: Text(result[column]?.toString() ?? ''),
                                                    ),
                                                  ))
                                              .toList(),
                                        );
                                      })
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                        ] else if (showNoColumnsMessage) ...[
                          Center(child: Text('No columns selected to display.'))
                        ],
                        if (_hasSearched && _results.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildButton(
                                  text: 'Previous',
                                  isLoading: _isLoadingPrevious,
                                  onPressed: _previousPage,
                                  color: Color(0xFF003366),
                                ),
                                Text('Page $_currentPage', style: TextStyle(fontSize: 16, color: Color(0xFF000000))),
                                _buildButton(
                                  text: 'Next',
                                  isLoading: _isLoadingNext,
                                  onPressed: _nextPage,
                                  color: Color(0xFF003366),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Show a placeholder message if there are no results and no search has been made yet
                        if (!_hasSearched && _results.isEmpty) ...[
                          Center(child: Text('Enter piece pins and click "Search" to get started.')),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    bool isLoading = false,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: 120,
      height: 36,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          elevation: 4.0,
        ),
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
                style: TextStyle(fontSize: 12),
              ),
      ),
    );
  }

  Widget _buildColumnFilter() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _allColumns.map((column) {
        bool isSelected = _selectedColumns.contains(column);
        Color buttonColor = isSelected ? Color(0xFF969DD6) : Color(0xFFA2AAAD);

        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            elevation: 4.0,
          ),
          onPressed: () {
            setState(() {
              if (isSelected) {
                _selectedColumns.remove(column);
              } else {
                _selectedColumns.add(column);
              }
            });
          },
          child: Text(
            column,
            style: TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }
}
