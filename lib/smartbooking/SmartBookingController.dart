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
import '../const/custom_notification.dart';

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
  final tripTypeController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool showBookingForm = false.obs;
  final RxString tripType = "one_way".obs;

  final selectedDate = Rxn<DateTime>();
  final selectedTime = Rxn<TimeOfDay>();

  final focusNode = FocusNode();


  @override
  void onInit() {

    super.onInit();
  }

  @override
  void onReady() {
    focusNode.requestFocus();
    super.onReady();
  }

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
      if (json["status"] == true) {
        showBookingForm.value = true;
        var gemin_data = json['gemin_data'];

        pickupLocationController.text = gemin_data['vehicle'];
        pickupLocationController.text = gemin_data['pickup_location'];
        dropLocationController.text = gemin_data['drop_location'];
        mobileController.text = gemin_data['mobile_number'];
        priceController.text = gemin_data['amount'];
        remarkController.text = gemin_data['remark'];
        selectedDate.value = DateTime.parse(gemin_data['pickup_date']);
        selectedTime.value = parseTime(gemin_data['pickup_time']);

        print("selectedTime.value ${selectedTime.value}");
        tripTypeController.text = gemin_data['trip_type'];
        if(!gemin_data['trip_type']){
          tripType.value = "one_way";
        }
        else{
          tripType.value = gemin_data['trip_type'];
        }

      }
      isSubmitting.value = false;
    } catch (e) {
      debugPrint("error while getting booking details : $e");
      isSubmitting.value = false;
    }
  }

  bool validateInputs() {
    if(mobileController.text.trim().isEmpty){
      CustomNotification.show(
        title: "Required",
        message: "Enter a valid mobile number",
        isSuccess: false,
      );
      return false;
    }
    if (pickupLocationController.text.trim().isEmpty ||
        dropLocationController.text.trim().isEmpty) {
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


    validateDateTime(selectedDate.value, selectedTime.value);

    return true;
  }

  bool validateDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) {
      CustomNotification.show(
        title: "Required",
        message: "Select date and time",
        isSuccess: false,
      );
      return false;
    }

    // Combine date + time
    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final now = DateTime.now();

    if (selected.isBefore(now)) {
      CustomNotification.show(
        title: "Required",
        message: "Past date/time not allowed",
        isSuccess: false,
      );
      return false;
    }
    return true;
  }

  void clearForm() {
    pickupLocationController.clear();
    priceController.clear();
    dropLocationController.clear();
    mobileController.clear();
    priceController.clear();
    vehicleController.clear();
    remarkController.clear();
    selectedTime.value = null;
    selectedDate.value = null;
    tripType.value = "one_way";
    messageController.clear();


  }

  void submitBooking() async {
    // showBookingForm.value = true;
    if (!validateInputs()) return;
    isSubmitting.value = true;

    // try {
    //   var postData = {
    //     'mobile_number' : mobileController.text.trim().isEmpty ? '' : mobileController.text.trim(),
    //     'vehicle' : vehicleController.text.trim().isEmpty ? 'Car' : vehicleController.text.trim(),
    //     'pickup_location' : pickupLocationController.text.trim().isEmpty ? '' : pickupLocationController.text.trim(),
    //     'drop_location' : dropLocationController.text.trim().isEmpty ? '' : dropLocationController.text.trim(),
    //     'trip_type' : tripType.value,
    //     "pickup_date": selectedDate.value!.toIso8601String().substring(0, 10),
    //     "pickup_time": selectedTime.value !=null ? selectedTime.value!.format(Get.context!):'',
    //     'remark' : remarkController.text.trim().isEmpty ? '' : remarkController.text.trim(),
    //     'price' : priceController.text.trim().isEmpty ? '' : priceController.text.trim(),
    //
    //   };
    //   print("$appurl/addNewBookingFromMessage");
    //   print("postData $postData ");
    //   final response = await http.post(
    //     Uri.parse("$appurl/addNewBookingFromMessage"),
    //     headers: {"Content-Type": "application/x-www-form-urlencoded"},
    //     body: postData,
    //   );
    //
    //   final json = jsonDecode(response.body);
    //   print(json);
    //   if (json["status"] == true || json["status"] == "true") {
    //     sendBookingNotification(json['booking_id'].toString());
    //     showBookingForm.value = false;
    //     clearForm();
    //     CustomNotification.show(
    //       title: "Success",
    //       message: json['message'],
    //       isSuccess: true,
    //     );
    //   }
    //   else{
    //     CustomNotification.show(
    //       title: "Failed",
    //       message: json['message'],
    //       isSuccess: false,
    //     );
    //   }
    //   isSubmitting.value = false;
    // } catch (e) {
    //   debugPrint("error while getting booking details : $e");
    //   isSubmitting.value = false;
    // }


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
      // debugPrint(json);

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


}
