// lib/file_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';

/// A service class for handling file operations.
class FileService {
  /// Prompts the user to select a file and reads its contents.
  static Future<List<String>?> pickAndReadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final bytes = result.files.single.bytes;
      if (bytes != null) {
        String content = utf8.decode(bytes);
        return content.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
      } else {
        throw Exception('Error reading the file.');
      }
    } else {
      throw Exception('No file selected.');
    }
  }

  /// Exports the provided results to a CSV file.
  static Future<String> exportToCSV(List<Map<String, dynamic>> results) async {
    List<List<dynamic>> rows = [];
    // Header
    rows.add(results.first.keys.toList());
    // Data
    for (var result in results) {
      rows.add(result.values.toList());
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
    final path = '${directory.path}\\results.csv';
    final file = File(path);
    await file.writeAsString(csv);
    return path;
  }
}
