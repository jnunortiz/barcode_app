import 'dart:async'; // For Completer
import 'dart:html' as html; // For web file operations
import 'package:csv/csv.dart';

/// A service class for handling file operations in a web environment.
class FileService {
  /// Prompts the user to select a file and reads its contents.
  static Future<List<String>?> pickAndReadFile() async {
    final completer = Completer<List<String>?>();

    final uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'text/csv'; // Accept only CSV files

    uploadInput.onChange.listen((e) {
      if (uploadInput.files!.isEmpty) {
        completer.complete(null); // No file selected
        return;
      }
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        final content = reader.result as String;
        final lines = content.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
        completer.complete(lines);
      });
      reader.readAsText(uploadInput.files![0]);
    });

    uploadInput.click();
    return completer.future;
  }

  /// Exports the provided results to a CSV file.
  static Future<void> exportToCSV(List<Map<String, dynamic>> results) async {
    if (results.isEmpty) {
      print('No data to export.');
      return;
    }

    List<List<dynamic>> rows = [];
    // Header
    rows.add(results.first.keys.toList());
    // Data
    for (var result in results) {
      rows.add(result.values.toList());
    }

    String csv = const ListToCsvConverter().convert(rows);

    final blob = html.Blob([csv]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'results.csv')
      ..click(); // Initiate download

    // Cleanup
    html.Url.revokeObjectUrl(url); // Revoke the object URL
  }
}
