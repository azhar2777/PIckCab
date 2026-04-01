import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../const/const.dart';

class SmartBookingController extends GetxController {
  static SmartBookingController get to => Get.find();

  final pickupLocationController = TextEditingController();
  final dropLocationController = TextEditingController();
  final pickupDateController = TextEditingController();
  final pickupTimeController = TextEditingController();
  final mobileController = TextEditingController();
  final vehicleController = TextEditingController();
  final priceController = TextEditingController();
  final remarkController = TextEditingController();
  final messageController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showBookingForm = false.obs;
  final RxString tripType = "one_way".obs;

  final selectedDate = Rxn<DateTime>();
  final selectedTime = Rxn<TimeOfDay>();

  void getBookingData() async {
    // selectedDate.value = DateTime.parse("2026-04-03");
    // selectedTime.value = parseTime("11:50 AM");
    isSubmitting.value = true;
    String result = messageController.text.trim().toString().replaceAll('\n', ' ');
    print("message $result");
    try {
      print("$appurl/get_booking_data");
      final response = await http.post(
        Uri.parse("$appurl/get_booking_data"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "message": result,
        },
      );

      final json = jsonDecode(response.body);
      print(json);
      if (json["status"] == true || json["status"] == "true") {
        showBookingForm.value = true;
        var gemin_data = json['gemin_data'];

        pickupLocationController.text = gemin_data['pickup_location'];
        dropLocationController.text = gemin_data['drop_location'];
        mobileController.text = gemin_data['mobile_number'];
        priceController.text = gemin_data['amount'];
        remarkController.text = gemin_data['remark'];
        selectedDate.value = DateTime.parse(gemin_data['pickup_date']);
        selectedTime.value = parseTime(gemin_data['pickup_date']);

      }
      isSubmitting.value = false;
    } catch (e) {
      debugPrint("error while getting booking details : $e");
      isSubmitting.value = false;
    }
  }

  void submitBooking() async {
    // showBookingForm.value = true;
  }

  // Date Time
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

  TimeOfDay parseTime(String timeString) {
    if (timeString.contains('AM') || timeString.contains('PM')) {
      // Format: 10:30 AM
      final parts = timeString.split(' ');
      final time = parts[0].split(':');
      final period = parts[1];

      int hour = int.parse(time[0]);
      int minute = int.parse(time[1]);

      if (period == 'PM' && hour != 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } else {
      // Format: 05:30:00
      final parts = timeString.split(':');

      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
  }

  bool canPop() {
    if(showBookingForm.value){
      showBookingForm.value = false;
      return false;
    }
    else{
      return true;
    }

  }
}
