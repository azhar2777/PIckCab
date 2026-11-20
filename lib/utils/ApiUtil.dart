import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pickcab_partner/const/const.dart';

class ApiUtil {
  static Future<String> getApi(
    String endpoint, {
    Map<String, String>? params,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: 'GET',
      endpoint: endpoint,
      params: params,
      headers: headers,
    );
  }

  static Future<String> postApi(
    String endpoint, {
    Object? data,
    Map<String, String>? headers,
  }) async {
    return _request(
      method: 'POST',
      endpoint: endpoint,
      data: data,
      headers: headers,
    );
  }

  static Future<String> _request({
    required String method,
    required String endpoint,
    Object? data,
    Map<String, String>? params,
    Map<String, String>? headers,
  }) async {
    try {
      Uri uri = Uri.parse('$appurl/$endpoint');

      if (params != null && params.isNotEmpty) {
        uri = uri.replace(queryParameters: params);
      }

      final requestHeaders = {
        'Content-Type': 'application/x-www-form-urlencoded',
        ...?headers,
      };

      late http.Response response;

      if (method == 'GET') {
        response = await http.get(
          uri,
          headers: requestHeaders,
        );
      } else if (method == 'POST') {
        response = await http.post(
          uri,
          headers: requestHeaders,
          body: data,
        );
      } else {
        throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else {
        throw Exception(
          'API Error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> postMultipartApi(
    String endpoint, {
    required Map<String, String> data,
    Map<String, String>? headers,
    Map<String, String>? files,
  }) async {
    try {
      final uri = Uri.parse('$appurl/$endpoint');

      var request = http.MultipartRequest('POST', uri);

      request.fields.addAll(data);

      if (headers != null) {
        request.headers.addAll(headers);
      }

      if (files != null) {
        for (final entry in files.entries) {
          request.files.add(
            await http.MultipartFile.fromPath(
              entry.key,
              entry.value,
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else {
        throw Exception(
          'API Error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
