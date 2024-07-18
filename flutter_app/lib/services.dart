// lib/services.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sends an HTTP POST request with the given URL and request body.
Future<http.Response> postRequest(Uri url, Map<String, dynamic> requestBody) async {
  return await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(requestBody),
  );
}
