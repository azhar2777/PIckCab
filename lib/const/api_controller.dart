import 'dart:convert';
import 'package:http/http.dart' as http;
import 'const.dart';

class ApiController {
  // HTTP client instance
  final http.Client _client = http.Client();

  // Generic POST request method
  Future<Map<String, dynamic>> postRequest({
    required String endpoint,
    required Map<String, String> body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$appurl/$endpoint'),
        body: body,
        headers:
            headers ??
            {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
            },
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': 'Request failed with status: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error occurred: $e',
        'statusCode': null,
      };
    }
  }

  // Generic GET request method
  Future<Map<String, dynamic>> getRequest({
    required String endpoint,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$appurl/$endpoint'),
        headers:
            headers ??
            {
              'Content-Type': 'application/json',
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
            },
      );

      // Check if response is successful
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': 'Request failed with status: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error occurred: $e',
        'statusCode': null,
      };
    }
  }

  // Dispose method to close the HTTP client
  void dispose() {
    _client.close();
  }
}
