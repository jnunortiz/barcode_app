// lib/widgets.dart
import 'package:flutter/material.dart';

/// A utility class for building table columns and cells from data.
class CustomWidgetBuilder {
  /// Returns a list of DataColumn widgets for the DataTable based on the search results.
  static List<DataColumn> getColumns(List<Map<String, dynamic>> results) {
    if (results.isNotEmpty) {
      var firstResult = results.first;
      return firstResult.keys.map((key) => DataColumn(label: Text(key))).toList();
    } else {
      return [];
    }
  }

  /// Returns a list of DataCell widgets for a given result map.
  static List<DataCell> getCells(Map<String, dynamic> result) {
    return result.keys.map((key) {
      var value = result[key];
      return DataCell(
        Text(
          value != null ? value.toString() : '',
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();
  }
}
