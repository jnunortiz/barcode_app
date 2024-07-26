import 'dart:async'; // Import async for Completer
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

class FileService {
  /// Downloads the CSV file from the FastAPI endpoint.
  static Future<void> downloadCSV(List<String> piecePins, List<String> columns) async {
    final url = Uri.parse('http://localhost:5000/export_csv');  // Update with your FastAPI URL

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'piece_pins': piecePins,
          'columns': columns,
        }),
      );

      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'data_store.csv')
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        print('Failed to download CSV file: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Exception while downloading CSV: $e');
    }
  }

  /// Prompts the user to select a file and reads its contents.
  static Future<List<String>?> pickAndReadFile() async {
    final completer = Completer<List<String>?>();
    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = '*/*'; // Allow any file type

    uploadInput.onChange.listen((e) {
      if (uploadInput.files!.isEmpty) {
        completer.complete(null);
        return;
      }
      final file = uploadInput.files![0];
      final reader = html.FileReader();
      final chunks = <Uint8List>[];

      // Function to read the next chunk of the file
      void readNextChunk([int start = 0]) {
        final chunkSize = 1024 * 1024; // 1MB chunks
        final end = (start + chunkSize > file.size) ? file.size : start + chunkSize;
        final blob = file.slice(start, end);
        reader.readAsArrayBuffer(blob);
      }

      reader.onLoadEnd.listen((e) {
        if (file.size > chunks.fold<int>(0, (sum, chunk) => sum + chunk.length)) {
          readNextChunk();
        } else {
          final fullContent = chunks.fold<Uint8List>(Uint8List(0), (a, b) {
            final newLength = a.length + b.length;
            final combined = Uint8List(newLength);
            combined.setRange(0, a.length, a);
            combined.setRange(a.length, newLength, b);
            return combined;
          });
          final content = utf8.decode(fullContent);
          final lines = content.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
          completer.complete(lines);
        }
      });

      reader.onLoad.listen((e) {
        final arrayBuffer = reader.result as Uint8List;
        chunks.add(arrayBuffer);
      });

      readNextChunk(); // Start reading the file
    });

    uploadInput.click();
    return completer.future;
  }

  /// Exports the provided results to a CSV file.
  static Future<void> exportResultsToCSV(List<Map<String, dynamic>> results, List<String> selectedColumns) async {
    if (results.isEmpty || selectedColumns.isEmpty) {
      print('No data to export or no columns selected.');
      return;
    }

    final csv = StringBuffer();

    // Write the header row
    csv.writeln(selectedColumns.join(','));

    // Write data rows
    for (var row in results) {
      csv.writeln(selectedColumns.map((col) => row[col] ?? '').join(','));
    }

    final blob = html.Blob([csv.toString()], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'results.csv')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
