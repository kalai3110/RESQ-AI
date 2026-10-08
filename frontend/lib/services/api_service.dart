import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl = prefs.getString('custom_base_url');
    if (savedBaseUrl != null && savedBaseUrl.isNotEmpty) {
      ApiConstants.baseUrl = savedBaseUrl;
    }
  }

  Future<void> updateBaseUrl(String newUrl) async {
    ApiConstants.baseUrl = newUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_base_url', ApiConstants.baseUrl);
  }

  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> get(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 12));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> post(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 12));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> patch(String url, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 12));

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> postMultipart(String url, Map<String, String> fields, {File? imageFile}) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      if (_authToken != null) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }

      request.fields.addAll(fields);

      if (imageFile != null && await imageFile.exists()) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Upload error: ${e.toString()}'};
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (!decoded.containsKey('success')) {
            decoded['success'] = true;
          }
          return decoded;
        } else {
          return {
            'success': false,
            'message': decoded['message'] ?? 'Server error (${response.statusCode})',
            'data': decoded
          };
        }
      }
      return {'success': response.statusCode < 300, 'data': decoded};
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse response: ${response.statusCode} - ${response.body}'
      };
    }
  }
}
