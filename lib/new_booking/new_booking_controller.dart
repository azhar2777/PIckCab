import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pickcab_partner/dashboard/DashboardScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../const/custom_notification.dart';
import '../../my_bookings/my_booking_controller.dart';
import '../../my_bookings/my_booking_screen.dart';
import '../../const/const.dart';

class NewBookingController extends GetxController {
  // Form Controllers
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final remarksController = TextEditingController();

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
          "$appurl/get_cities",
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
    if (selectedDate.value == null) {
      Get.snackbar(
        'Select Date First',
        'Please select a date before selecting time',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final now = DateTime.now();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      final selectedDateTime = DateTime(
        selectedDate.value!.year,
        selectedDate.value!.month,
        selectedDate.value!.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      // ❌ Reject if same or before current time
      if (!selectedDateTime.isAfter(now)) {
        selectedTime.value = null; // 🔁 Reset time

        Get.snackbar(
          'Invalid Time',
          'Please select future time',
          snackPosition: SnackPosition.BOTTOM,
        );

        return;
      }

      // ✅ Valid future time
      selectedTime.value = pickedTime;
    }
  }

  Future<void> submitBooking() async {
    if (!validateInputs()) return;
    if (isSubmitting.value) return;
    isSubmitting.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "0";

      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$appurl/add_new_booking"),
      );
      request.fields.addAll({
        "user_id": userId,
        "car_type": selectedCar.value,
        "start_location": fromController.text.trim(),
        "end_location": toController.text.trim(),
        "trip_type": tripType.value,
        "trip_date": selectedDate.value!.toIso8601String().substring(0, 10),
        "trip_time": selectedTime.value !=null ? selectedTime.value!.format(Get.context!):'',
        "remarks": remarksController.text.trim(),
        "carrier": hasCarrier.value == 'yes' ? '1' : '0',
        "send_whatsapp": sendWhatsapp.value ? '1' : '0',
        "send_call": sendCall.value ? '1' : '0',
        "price_type": priceType.value, // fixed or negotiable
        "price": priceController.text.trim(),
      });

      final response = await request.send();
      final resp = await response.stream.bytesToString();
      final json = jsonDecode(resp);

      if (json["status"] == true || json["status"] == "true") {
        sendBookingNotification(json['booking_id'].toString());
        CustomNotification.show(
          title: "Success",
          message: "Booking created!",
          isSuccess: true,
        );
        clearForm();
        await Future.delayed(const Duration(milliseconds: 1000));

        Get.offAll(() => const DashboardScreen(selectedTab: 1));
      } else {
        CustomNotification.show(
          title: "Failed",
          message: json["message"] ?? "Try again",
          isSuccess: false,
        );
      }
    } catch (e) {
      print(e);
      CustomNotification.show(
        title: "Error",
        message: "Check internet",
        isSuccess: false,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> sendBookingNotification(String bookingId) async {

    try {
      print(bookingId);
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("$appurl/send_booking_notification"),
      );
      request.fields.addAll({
        "booking_id": bookingId
      });

      final response = await request.send();
      final resp = await response.stream.bytesToString();
      final json = jsonDecode(resp);
      debugPrint(json);

    } catch (e) {
      print("Error in sendBookingNotification");
      print(e);
      // CustomNotification.show(
      //   title: "Error",
      //   message: "Check internet",
      //   isSuccess: false,
      // );
    } finally {
      isSubmitting.value = false;
    }
  }

  bool validateInputs() {
    if (fromController.text.trim().isEmpty ||
        toController.text.trim().isEmpty) {
      CustomNotification.show(
        title: "Required",
        message: "Select Pickup and Drop cities",
        isSuccess: false,
      );
      return false;
    }
    if (selectedDate.value == null || selectedTime.value == null) {
      CustomNotification.show(
        title: "Required",
        message: "Select date and time",
        isSuccess: false,
      );
      return false;
    }


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
