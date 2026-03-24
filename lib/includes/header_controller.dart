// lib/controllers/header_controller.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../const/const.dart';
import '../const/custom_notification.dart';

class HeaderController extends GetxController {
  static HeaderController get to => Get.find();

  var alertEnabled = false.obs;
  var userImage = "".obs;
  var userId = "0".obs;
  var isLoading = true.obs;

  // Cache keys
  static const String _cachedUserImage = 'cached_user_image';
  static const String _cachedAlertStatus = 'cached_alert_status';
  static const String _lastFetchTime = 'last_header_fetch_time';
  static const Duration _cacheDuration = Duration(minutes: 5);

  @override
  void onInit() {
    super.onInit();
    initializeHeader();
  }

  Future<void> initializeHeader() async {
    final prefs = await SharedPreferences.getInstance();
    userId.value = prefs.getString("user_id") ?? "0";

    if (userId.value == "0" || userId.value.isEmpty) {
      isLoading.value = false;
      return;
    }

    // Load cached data immediately
    await loadCachedData();

    // Refresh in background if needed
    refreshIfNeeded();
  }

  Future<void> loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    userImage.value = prefs.getString(_cachedUserImage) ?? "";
    alertEnabled.value = prefs.getBool(_cachedAlertStatus) ?? false;
    isLoading.value = false;
  }

  Future<void> refreshIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getInt(_lastFetchTime) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastFetch > _cacheDuration.inMilliseconds) {
      await fetchUserDetails();
    }
  }

  Future<void> fetchUserDetails() async {
    final url = Uri.parse("$appurl/user_details?user_id=${userId.value}");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == true) {
          final userData = data["user_data"];

          final newAlertStatus = userData["alert_status"].toString() == "1";
          final newUserImage = userData["user_image"] != null &&
                  userData["user_image"].toString().isNotEmpty
              ? "$imageurl/${userData["user_image"]}"
              : "";

          // Save to cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cachedUserImage, newUserImage);
          await prefs.setBool(_cachedAlertStatus, newAlertStatus);
          await prefs.setInt(
              _lastFetchTime, DateTime.now().millisecondsSinceEpoch);

          // Update observables
          alertEnabled.value = newAlertStatus;
          userImage.value = newUserImage;
        }
      }
    } catch (e) {
      debugPrint("User detail error: $e");
    }
  }

  Future<void> updateAlertStatus(bool newValue) async {
    alertEnabled.value = newValue;

    final url = Uri.parse("$appurl/update_alert");

    try {
      var request = http.MultipartRequest('POST', url);
      request.fields.addAll({
        "user_id": userId.value,
        "alert_status": newValue ? "1" : "0",
      });

      await request.send();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cachedAlertStatus, newValue);

      CustomNotification.show(
        title: "Alert",
        message: newValue ? "Alerts Enabled" : "Alerts Disabled",
        isSuccess: true,
      );
    } catch (_) {
      alertEnabled.value = !newValue;
    }
  }
}
