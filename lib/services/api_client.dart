import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiClient {
  static const String _baseUrl = 'http://localhost:5000';
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal();

  /// Makes an HTTP request to the API
  /// 
  /// [method] - HTTP method (GET, POST, PUT, DELETE, etc.)
  /// [route] - API endpoint route (e.g., '/api/users')
  /// [data] - Optional request body data
  /// 
  /// Returns: Response body as dynamic
  Future<dynamic> apiRequest(
    String method,
    String route, {
    dynamic data,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$route');
      // ensure headers are correctly typed
      Map<String, String> headers = {};
      if (data != null) {
        headers = {'Content-Type': 'application/json'};
      }

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: data != null ? jsonEncode(data) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      await _throwIfResponseNotOk(response);
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Throws an exception if the response status is not OK
  Future<void> _throwIfResponseNotOk(http.Response response) async {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final text = response.body.isNotEmpty ? response.body : response.reasonPhrase;
      throw Exception('${response.statusCode}: $text');
    }
  }

  /// Getter function for React Query-like behavior
  /// 
  /// [route] - API endpoint (without base URL)
  /// [onUnauthorized] - Behavior on 401: 'returnNull' or 'throw'
  /// 
  /// Returns: Query data
  Future<dynamic> getQueryFn(
    String route, {
    String onUnauthorized = 'throw',
  }) async {
    try {
      final url = Uri.parse('$_baseUrl$route');
      final response = await http.get(url);

      if (onUnauthorized == 'returnNull' && response.statusCode == 401) {
        return null;
      }

      await _throwIfResponseNotOk(response);
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (e) {
      if (onUnauthorized == 'returnNull') {
        return null;
      }
      rethrow;
    }
  }
}
