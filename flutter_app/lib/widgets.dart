import 'package:flutter/material.dart';

/// A utility class for building table columns and cells from data.
class CustomWidgetBuilder {
  /// The desired order of columns.
  static final List<String> _columnOrder = [
    'Piece Pin', 'Shipment Pin', 'Scan Date', 'Scan Time', 'System Update Date',
    'Terminal Name', 'Terminal Id', 'Route', 'Scan Code', 'Event Reason Code',
    'Event Code Desc[Eng]', 'Event Code Desc[Fr]', 'Comment', 'Delivery Signature',
    'Expected Delivery Date', 'Service Date', 'Origin Terminal Name', 'Origin Terminal Id',
    'Origin City', 'Origin Province', 'Origin FSA', 'Origin PC', 'Origin Country Code',
    'Destination Terminal Id', 'Destination Terminal Name', 'Destination City',
    'Destination Province', 'Destination FSA', 'Destination PC', 'Destination Country Code',
    'Account Number', 'Exp Mode of Trans', 'Product Code', 'Revised Initial Transit Days',
    'Delivery Company Name', 'Event Address Line 1', 'Event Address Line 2', 'Event City',
    'Event Province', 'Event Country', 'Event Postal Code', 'Delivery SNR Pin',
    'Delivery OSNR Flag', 'Cross Reference Pin', 'Container Id', 'Container Type',
    'Pickup Delivery Location', 'Scan Srouce System Code', 'Scan Source Reference Code', 'Source Code'
  ];

  /// Returns a list of DataColumn widgets for the DataTable based on the search results.
  static List<DataColumn> getColumns() {
    return _columnOrder.map((key) => DataColumn(label: Text(key))).toList();
  }

  /// Returns a list of DataCell widgets for a given result map.
  static List<DataCell> getCells(Map<String, dynamic> result) {
    return _columnOrder.map((key) {
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
