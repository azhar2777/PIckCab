import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../const/custom_notification.dart';
import '../../my_bookings/my_booking_controller.dart';
import '../../my_bookings/my_booking_screen.dart';
import '../../const/const.dart';

class FreeNewBookingController extends GetxController {
  // Form Controllers
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final remarksController = TextEditingController();
  var vehicleType = 'Sedan'.obs;
  var startTime = DateTime.now().obs;
  var endTime = DateTime.now().obs;
  var anyLocation = false.obs;

  final locationController = TextEditingController();
  final detailsController = TextEditingController();
  // Form Values
  final selectedCar = 'Sedan'.obs;
  final tripType = 'one_way'.obs;
  final selectedDate = Rxn<DateTime>();
  final selectedTime = Rxn<TimeOfDay>();

  final hasCarrier = 'no'.obs;
  final sendWhatsapp = true.obs;
  final sendCall = true.obs;
  final priceType = 'fixed'.obs; // 'fixed' or 'negotiable'
  final priceController = TextEditingController();
  final price = ''.obs;

  final isSubmitting = false.obs;

  // City Search (Same as Register)
  var allCities = <String>[].obs;
  var filteredCities = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchIndianCities();
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

  void pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) selectedDate.value = date;
  }

  void pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) selectedTime.value = time;
  }

  Future<void> submitBooking() async {
    // if (!validateInputs()) return;

    if (isSubmitting.value) return;
    isSubmitting.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "0";

      // Format dates as expected by your backend (adjust format if needed)
      final DateFormat apiDateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");

      final request = http.MultipartRequest(
        "POST",
        Uri.parse(
            "$appurl/free-booking/add"), // make sure appurl is defined globally or imported
      );

      request.fields.addAll({
        "user_id": userId,
        "car_type": vehicleType.value, // ← matches UI dropdown
        "start_time": apiDateFormat.format(startTime.value), // ← start time
        "end_time": apiDateFormat.format(endTime.value), // ← end time
        "location": locationController.text.trim(), // ← vehicle location
        "remarks": detailsController.text.trim(), // ← details / remarks
        // Add any extra fields your API expects here (e.g. carrier, whatsapp, etc.)
        // Example:
        // "carrier": "0",
        // "send_whatsapp": "0",
        // "send_call": "0",
      });

      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      final json = jsonDecode(respStr);

      if (json["status"] == true || json["status"] == "true") {
        CustomNotification.show(
          title: "Success",
          message: json["message"] ?? "Free vehicle posted successfully!",
          isSuccess: true,
        );

        // Navigate to my bookings screen
        Get.off(() => MyBookingScreen());

        clearForm();

        // Refresh bookings list
        await Future.delayed(const Duration(milliseconds: 800));
        Get.find<MyBookingController>().fetchMyBookings();
      } else {
        CustomNotification.show(
          title: "Failed",
          message: json["message"] ?? "Something went wrong. Please try again.",
          isSuccess: false,
        );
      }
    } catch (e) {
      debugPrint("Submit error: $e");
      CustomNotification.show(
        title: "Error",
        message: "Please check your internet connection and try again.",
        isSuccess: false,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  bool validateInputs() {
    if (!sendWhatsapp.value && !sendCall.value) {
      CustomNotification.show(
        title: "Required",
        message: "Choose contact method",
        isSuccess: false,
      );
      return false;
    }
    return true;
  }

  void clearForm() {
    fromController.clear();
    toController.clear();
    remarksController.clear();
    selectedDate.value = null;
    selectedTime.value = null;
    tripType.value = "one_way";
    selectedCar.value = "Sedan";
    hasCarrier.value = "no";
    sendWhatsapp.value = true;
    sendCall.value = true;
  }

  @override
  void onClose() {
    fromController.dispose();
    toController.dispose();
    remarksController.dispose();
    priceController.dispose();
    super.onClose();
  }
}
