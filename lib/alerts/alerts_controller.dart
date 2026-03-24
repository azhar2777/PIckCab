import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../const/const.dart';
import '../const/custom_notification.dart';
import '../freebooking/freebooking_new.dart';
import '../home/home_controller.dart';
import '../home/home_screen.dart';
import '../my_bookings/my_booking_screen.dart';
import '../new_booking/new_booking_screen.dart';
import '../profile/profile_screen.dart';

class AlertCity {
  final String id;
  final String city;
  AlertCity({required this.id, required this.city});
}

class AlertsController extends GetxController {
  static AlertsController get to => Get.find();

  final RxList<AlertCity> cities = <AlertCity>[].obs;
  final RxBool isLoading = false.obs;

  // City search logic - SAME AS Registration & New Booking
  var allCities = <String>[].obs;
  var filteredCities = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchIndianCities(); // Load once
  }

  void searchCities(String query) {
    if (query.trim().isEmpty) {
      filteredCities.assignAll(allCities);
    } else {
      filteredCities.assignAll(
        allCities
            .where((city) => city.toLowerCase().contains(query.toLowerCase()))
            .toList(),
      );
    }
  }

  Future<void> fetchIndianCities() async {
    if (allCities.isNotEmpty) return;
    try {
      final response = await http.get(
        Uri.parse(
          "https://countriesnow.space/api/v0.1/countries/cities/q?country=India",
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["error"] == false && data["data"] is List) {
          final cities = (data["data"] as List).cast<String>()..sort();
          allCities.assignAll(cities);
          filteredCities.assignAll(cities);
        }
      }
    } catch (e) {
      debugPrint("City load error: $e");
    }
  }

  Future<void> fetchCities() async {
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "0";

      final response = await http.get(
        Uri.parse("$appurl/get_alert_cities?user_id=$userId"),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["status"] == true) {
          final List<dynamic> data = json["cities"];
          final cityList = data
              .map(
                (item) => AlertCity(
                  id: item["id"].toString(),
                  city: item["city"].toString().trim(),
                ),
              )
              .toList();
          cities.assignAll(cityList);
        } else {
          cities.clear();
        }
      }
    } catch (e) {
      cities.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCity(String cityName) async {
    final trimmed = cityName.trim();
    if (trimmed.isEmpty) return;

    if (cities.length >= 15) {
      CustomNotification.show(
        title: "Limit Reached",
        message: "Maximum 15 cities allowed",
        isSuccess: false,
      );
      return;
    }

    if (cities.any((c) => c.city.toLowerCase() == trimmed.toLowerCase())) {
      CustomNotification.show(
        title: "Already Added",
        message: "This city is already in your list",
        isSuccess: false,
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "0";

      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$appurl/add_alert_city"),
      );
      request.fields.addAll({'user_id': userId, 'city': trimmed});

      final response = await request.send();
      final resp = await response.stream.bytesToString();
      final json = jsonDecode(resp);

      if (json["status"] == true) {
        await fetchCities();
        CustomNotification.show(
          title: "Success",
          message: "City added!",
          isSuccess: true,
        );
      } else {
        CustomNotification.show(
          title: "Failed",
          message: json["message"] ?? "Try again",
          isSuccess: false,
        );
      }
    } catch (e) {
      CustomNotification.show(
        title: "Error",
        message: "Network error",
        isSuccess: false,
      );
    }
  }

  Future<void> deleteCityById(String id) async {
    if (id.isEmpty) return;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$appurl/delete_alert_city"),
      );
      request.fields.addAll({'id': id}); // Corrected line

      final response = await request.send();
      final resp = await response.stream.bytesToString();
      final json = jsonDecode(resp);

      if (json["status"] == true) {
        cities.removeWhere((c) => c.id == id);
        CustomNotification.show(
          title: "Success",
          message: "City removed",
          isSuccess: true,
        );
      } else {
        CustomNotification.show(
          title: "Failed",
          message: json["message"] ?? "Unable to delete",
          isSuccess: false,
        );
      }
    } catch (e) {
      debugPrint("Delete error: $e");
      CustomNotification.show(
        title: "Error",
        message: "Check your connection",
        isSuccess: false,
      );
    }
  }

  void deleteCity(String cityName) {
    final city = cities.firstWhereOrNull((c) => c.city == cityName);
    if (city != null) deleteCityById(city.id);
  }

  // Navigation
  void navigateToHome() =>
      Get.offAll(() => const HomeScreen(), transition: Transition.fadeIn);
  void navigateToMyBooking() =>
      Get.offAll(() => const MyBookingScreen(), transition: Transition.fadeIn);
  void navigateToProfile() =>
      Get.offAll(() => const ProfileScreen(), transition: Transition.fadeIn);
  void onNewBooking() =>
      Get.to(() => const NewBookingScreen(), transition: Transition.fadeIn);
  void onFreeVehicle() {
    Get.to(() => const FreebookingNew(), transition: Transition.downToUp);
  }

  // Add this method in AlertsController
  void openHomeAndSearchCity(String cityName) async {
    // 1. Go to Home WITHOUT destroying everything
    Get.offAll(() => const HomeScreen(), transition: Transition.fadeIn);

    // 2. Wait until HomeScreen is fully inserted and its controller exists
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 50));
      return !Get.isRegistered<HomeController>();
    });

    // 3. Now it's safe – HomeController definitely exists
    final homeController = Get.find<HomeController>();
    homeController.updateSearch(cityName);

    // Optional nice toast
    CustomNotification.show(
      title: "Filtering Trips",
      message: "Showing bookings from $cityName",
      isSuccess: true,
    );
  }
}
