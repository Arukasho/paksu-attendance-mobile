import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_storage.dart';

class ApiClient {
  static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/v1',
);

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final headers = {'Content-Type': 'application/json'};

    if (auth) {
      final token = await SecureStorage.getAccessToken();
      headers['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.body.isEmpty) return {'data': {}};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetch(String path, {bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await SecureStorage.getAccessToken();
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.get(Uri.parse('$baseUrl$path'), headers: headers);
    
    if (response.body.isEmpty) return {'data': {}};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body, {bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await SecureStorage.getAccessToken();
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.patch(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body));
    
    if (response.body.isEmpty) return {'data': {}};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> uploadFile(String path, String filePath, {bool auth = false}) async {
  final headers = <String, String>{};
  if (auth) {
    final token = await SecureStorage.getAccessToken();
    headers['Authorization'] = 'Bearer $token';
  }

  final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll(headers)
      ..files.add(await http.MultipartFile.fromPath('photo', filePath));

    final streamedResponse = await request.send();
    final responseBody = await streamedResponse.stream.bytesToString();
    return jsonDecode(responseBody) as Map<String, dynamic>;
  }
}