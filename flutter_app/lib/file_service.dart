import 'dart:async'; // For Completer
import 'dart:html' as html; // For web file operations
import 'dart:convert';
import 'dart:typed_data';
import 'package:csv/csv.dart';

/// A service class for handling file operations.
class FileService {
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
  static Future<void> exportToCSV(List<Map<String, dynamic>> results) async {
    List<List<dynamic>> rows = [];
    // Header
    if (results.isNotEmpty) {
      rows.add(results.first.keys.toList());
    }
    // Data
    for (var result in results) {
      rows.add(result.values.toList());
    }

    String csv = const ListToCsvConverter().convert(rows);
    
    _exportFile(csv, 'results.csv', 'text/csv');
  }

  /// Exports data to a file with the given name and MIME type.
  static void _exportFile(String content, String fileName, String mimeType) {
    final blob = html.Blob([content], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
