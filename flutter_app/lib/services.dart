// lib/services.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Sends a POST request with a given URL and body.
///
/// Returns the response from the request.
Future<http.Response> postRequest(Uri url, Map<String, dynamic> body) async {
  return await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode(body),
  );
}
