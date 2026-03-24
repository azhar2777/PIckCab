// lib/services/notification_service.dart
import 'dart:async'; // ← Added for TimeoutException
import 'dart:convert';
import 'dart:io'; // ← Added for SocketException & HttpException
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../const/const.dart';

class NotificationService {
  // Use your real base URL here
  static const String _updateTokenUrl = "$appurl/update_device_token";
  // Example (uncomment for testing):
  // static const String _updateTokenUrl = "https://yourdomain.com/api/update_device_token";

  /// Call once in main()
  static Future<void> initialize() async {
    await FirebaseMessaging.instance.requestPermission();

    await _registerToken();

    // Listen for token refresh (FCM can refresh it anytime)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("FCM Token REFRESHED → $newToken");
      await _saveTokenToServer(newToken);
    });
  }

  static Future<void> _registerToken() async {
    if (!kIsWeb && Platform.isAndroid) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print("Failed to get FCM token");
        return;
      }

      print("FCM Token Retrieved: $token");

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("fcm_token", token);

      final userId = prefs.getString("user_id");
      if (userId == null ||
          userId.isEmpty ||
          userId == "null" ||
          userId == "0") {
        print("User not logged in → skipping token update");
        return;
      }

      await _saveTokenToServer(token);
    }
  }

  /// Call this after successful login or in HomeController.onInit()
  static Future<void> updateTokenAfterLogin() async {
    await _registerToken();
  }

  /// Send token to backend – FULLY FIXED & SAFE
  static Future<void> _saveTokenToServer(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");

    if (userId == null || userId.isEmpty || userId == "null" || userId == "0") {
      print("No valid user_id → skipping token update");
      return;
    }

    final String url = _updateTokenUrl;
    print("Sending FCM token to: $url");
    print("Payload → user_id: $userId | device_token: $token");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'user_id': userId, 'device_token': token},
      ).timeout(const Duration(seconds: 15)); // Prevents hanging forever

      print("Response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          print("Device token updated successfully on server");
        } else {
          print("Server rejected token: ${data['message'] ?? 'Unknown'}");
        }
      } else {
        print("Server returned error: ${response.statusCode}");
      }
    } on TimeoutException catch (_) {
      print("Request timed out – Check internet or server URL");
    } on SocketException catch (e) {
      print("No internet connection: $e");
    } on HttpException catch (e) {
      print("HTTP Exception: $e");
    } on FormatException catch (e) {
      print("Invalid JSON response: $e");
    } catch (e) {
      print("Unexpected error while updating FCM token: $e");
    }
  }
}
