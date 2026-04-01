import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../const/const.dart';
import '../const/custom_notification.dart';
import '../freebooking/freebooking_new.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';
import '../new_booking/new_booking_screen.dart';
import '../profile/profile_screen.dart';
import '../alerts/alerts_screen.dart';
import 'edit_booking_screen.dart';
import 'my_booking_screen.dart';

class MyBookingController extends GetxController {
  static MyBookingController get to => Get.find();

  final RxList<Map<String, dynamic>> bookings = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> bookedByMe =
      <Map<String, dynamic>>[].obs; // NEW: Book By Me tab

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxBool isSubmitting = false.obs;

  // Form Controllers (Shared between New & Edit)
  final fromController = TextEditingController();
  final toController = TextEditingController();
  final remarksController = TextEditingController();

  final selectedCar = "Innova".obs;
  final tripType = "one_way".obs;
  final hasCarrier = "no".obs;
  final sendWhatsapp = false.obs;
  final sendCall = false.obs;
  final selectedDate = DateTime.now().obs;
  final selectedTime = Rxn<TimeOfDay>();

  final priceType = 'fixed'.obs; // 'fixed' or 'negotiable'
  final priceController = TextEditingController();
  final price = ''.obs;

  // City Search - Now from API
  final allCities = <String>[].obs;
  final filteredCities = <String>[].obs;

  final Map<String, String> carImages = {
    "Sedan": "$imageurlstatic/sedan.png",
    "Innova": "$imageurlstatic/innova.png",
    "Traveller": "$imageurlstatic/traveller.png",
    "SUV": "$imageurlstatic/suv.png",
    "Hatchback": "$imageurlstatic/hatchback.png",
    "Luxury": "$imageurlstatic/luxury.png",
    "Ertiga": "$imageurlstatic/innova.png", // Added Ertiga mapping
  };

  @override
  void onInit() {
    super.onInit();
    fetchMyBookings();
    fetchIndianCities();
    fetchBookedByMe();
  }

  // =============================================
  // FETCH BOOKINGS BOOKED BY CURRENT USER
  // =============================================
  Future<void> fetchBookedByMe({bool showLoading = false}) async {
    if (showLoading) isLoading.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "0";

      if (userId == "0") return;
      // var url = "$appurl/my_bookings_byid?user_id=1";
      var url = "$appurl/my_bookings_byid?user_id=$userId";
      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["status"] == true && json["bookings"] != null) {
          final List items = json["bookings"];
          final now = DateTime.now();

          final parsed = items.map<Map<String, dynamic>>((item) {
            final tripDate = item["trip_date"]?.toString() ?? "";
            final tripTime = item["trip_time"]?.toString() ?? "";

            DateTime? tripDateTime;

            try {
              if (tripDate.isNotEmpty && tripTime.isNotEmpty) {
                if (tripTime.toUpperCase().contains("AM") ||
                    tripTime.toUpperCase().contains("PM")) {
                  // convert manually for 12-hour format
                  final formatTime = tripTime.toUpperCase();
                  final isPM = formatTime.contains("PM");
                  final clean = formatTime
                      .replaceAll("AM", "")
                      .replaceAll("PM", "")
                      .trim();
                  final parts = clean.split(":");

                  int hour = int.parse(parts[0]);
                  int minute = int.tryParse(parts[1]) ?? 0;

                  if (isPM && hour != 12) hour += 12;
                  if (!isPM && hour == 12) hour = 0;

                  tripDateTime = DateTime.parse(
                      "$tripDate ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
                } else {
                  tripDateTime = DateTime.parse("$tripDate $tripTime");
                }
              }
            } catch (e) {
              tripDateTime = null;
            }

            final isPast = tripDateTime != null && tripDateTime.isBefore(now);
            final isBooked = item["status"]?.toString() == '0';

            return {
              'id': item["id"].toString(),
              'trip_id': item["trip_id"]?.toString(),
              'from': item["start_location"] ?? "Not set",
              'to': item["end_location"] ?? "Not set",
              'carType': item["car_type"] ?? "Sedan",
              'remarks': item["remarks"] ?? "",
              'date': tripDate,
              'time': tripTime,
              'isTwoWay': item["trip_type"] == "two_way",
              'isPast': isPast,
              'isBooked': isBooked,
              'avatarUrl': carImages[item["car_type"]] ??
                  "$imageurlstatic/hatchback.png",
              'carrier': item["carrier"]?.toString() ?? "0",
              'send_whatsapp': item["send_whatsapp"]?.toString() ?? "0",
              'send_call': item["send_call"]?.toString() ?? "0",
              'trip_type': item["trip_type"] ?? "one_way",
              'start_location': item["start_location"],
              'end_location': item["end_location"],
              'status': item["status"],
              'booked_by_id': item["book_by_id"]?.toString(),
              'added_by_name': item["added_by_name"]?.toString(),
              'added_by_id': item["userppid"]?.toString(),
              'price': item["price"] !=null ? item["price"] : '',
              'price_type': item["price_type"],
              'user_image': item["booking_user_image"],
              'user_city': item["booking_user_city"],
            };
          }).toList();

          // Sort: newest first (by id descending)
          parsed
              .sort((a, b) => b['id'].toString().compareTo(a['id'].toString()));

          bookedByMe.assignAll(parsed);
        }
      } else {
        debugPrint("Booked by me failed - status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Booked by me error: $e");
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  // =============================================
  // FETCH INDIAN CITIES
  // =============================================
  Future<void> fetchIndianCities() async {
    if (allCities.isNotEmpty) return; // Load once

    try {
      final response = await http
          .get(
            Uri.parse(
              "$appurl/api/get_cities",
            ),
          )
          .timeout(const Duration(seconds: 10));

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
      // Fallback to minimal list so app doesn't break
      allCities.assignAll([
        "Ranchi",
        "Patna",
        "Kolkata",
        "Delhi",
        "Mumbai",
        "Bangalore",
      ]);
      filteredCities.assignAll(allCities);
    }
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

  void pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF6A1B9A)),
        ),
        child: child!,
      ),
    );
    if (picked != null) selectedDate.value = picked;
  }

  void pickTime(BuildContext context) async {
    final now = DateTime.now();
    final nowTime = TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime.value ?? nowTime,
    );

    if (picked != null) {
      // ✅ If no date selected, just allow
      if (selectedDate.value == null) {
        selectedTime.value = picked;
        return;
      }

      final selectedDateTime = selectedDate.value!;

      final isToday =
          selectedDateTime.year == now.year &&
              selectedDateTime.month == now.month &&
              selectedDateTime.day == now.day;

      if (isToday) {
        final nowMinutes = nowTime.hour * 60 + nowTime.minute;
        final pickedMinutes = picked.hour * 60 + picked.minute;

        if (pickedMinutes < nowMinutes) {
          CustomNotification.show(
            title: "Invalid Time",
            message: "Please select current or future time!",
            isSuccess: false,
          );
          return;
        }
      }

      // ✅ Always allow for future dates
      selectedTime.value = picked;
    }
  }

  void pickTime_OLD(BuildContext context) async {
    print("selectedDate.value${selectedDate.value}");
    final now = TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime.value ?? now,
    );

    if (picked != null) {
      final nowMinutes = now.hour * 60 + now.minute;
      final pickedMinutes = picked.hour * 60 + picked.minute;

      if (pickedMinutes < nowMinutes) {
        CustomNotification.show(
          title: "Invalid Time",
          message: "Please select current or future time!",
          isSuccess: false,
        );
        return;
      }

      selectedTime.value = picked;
    }
  }

  // =============================================
  // DELETE BOOKING
  // =============================================
  Future<void> deleteBooking(String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id") ?? "0";
    try {
      final response = await http.post(
        Uri.parse("$appurl/booking/delete"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "user_id": userId,
          "booking_id": bookingId,
        },
      );

      final json = jsonDecode(response.body);

      if (json["status"] == true) {
        await fetchMyBookings(); // Refresh list

        CustomNotification.show(
          title: "Success",
          message: "Booking deleted!",
          isSuccess: true,
        );
      }
    } catch (e) {
      CustomNotification.show(
        title: "Error",
        message: "Something went wrong!",
        isSuccess: false,
      );
    }
  }

  // =============================================
  // FETCH MY BOOKINGS LIST
  // =============================================
  Future<void> fetchMyBookings({bool showLoading = true}) async {
    // Also fetch booked by me data
    fetchBookedByMe();

    if (showLoading) isLoading.value = true;
    hasError.value = false;
    bookings.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "0";

      if (userId == "0") {
        Get.offAll(() => LoginScreen());
        return;
      }

      // var url = "$appurl/my_bookings_new?user_id=1";
      var url = "$appurl/my_bookings_new?user_id=$userId";

      final response = await http
          // .get(Uri.parse("$appurl/my_bookings?user_id=$userId"))
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print("response_my_bookings");
        print(""+response.body);
        final json = jsonDecode(response.body);

        if (json["status"] == true && json["bookings"] != null) {
          final List items = json["bookings"];

          final now = DateTime.now();

          final parsed = items.map<Map<String, dynamic>>((item) {
            final tripDate = item["trip_date"]?.toString() ?? "";
            final tripTime = item["trip_time"]?.toString() ?? "";

            DateTime? tripDateTime;

            try {
              if (tripDate.isNotEmpty && tripTime.isNotEmpty) {
                if (tripTime.toUpperCase().contains("AM") ||
                    tripTime.toUpperCase().contains("PM")) {
                  // convert manually for 12-hour format
                  final formatTime = tripTime.toUpperCase();
                  final isPM = formatTime.contains("PM");
                  final clean = formatTime
                      .replaceAll("AM", "")
                      .replaceAll("PM", "")
                      .trim();
                  final parts = clean.split(":");

                  int hour = int.parse(parts[0]);
                  int minute = int.tryParse(parts[1]) ?? 0;

                  if (isPM && hour != 12) hour += 12;
                  if (!isPM && hour == 12) hour = 0;

                  tripDateTime = DateTime.parse(
                      "$tripDate ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}");
                } else {
                  tripDateTime = DateTime.parse("$tripDate $tripTime");
                }
              }
            } catch (e) {
              tripDateTime = null;
            }

            final isPast = tripDateTime != null && tripDateTime.isBefore(now);
            final isBooked = item["status"]?.toString() == '0';

            final carType = item["car_type"]?.toString() ?? "Sedan";

            return {
              'id': item["id"].toString(),
              'from': item["start_location"] ?? "Not set",
              'to': item["end_location"] ?? "Not set",
              'carType': carType,
              'remarks': item["remarks"] ?? "",
              'date': tripDate,
              'time': tripTime,
              'isTwoWay': item["trip_type"] == "two_way",
              'isPast': isPast,
              'isBooked': isBooked,
              'avatarUrl':
                  carImages[carType] ?? "$imageurlstatic/hatchback.png",
              'carrier': item["carrier"]?.toString() ?? "0",
              'send_whatsapp': item["send_whatsapp"]?.toString() ?? "0",
              'send_call': item["send_call"]?.toString() ?? "0",
              'trip_type': item["trip_type"] ?? "one_way",
              'start_location': item["start_location"],
              'end_location': item["end_location"],
              'status': item["status"],
              'price': item["price"] !=null ? item["price"] : '',
              'price_type': item["price_type"],
              'booked_by_unq_id': item["book_by_id"]?.toString(),
              'car_type': carType,
              'trip_date': tripDate,
              'trip_time': tripTime,
              'user_name': item["user_name"],
              'pp_id': item["user_unq_id"],
              'user_image': item["user_image"],
              'user_city': item["city"],
            };
          }).toList();

          // Sort: newest first, then future bookings before past ones
          parsed.sort((a, b) {
            // 1️⃣ Sort by ID as INT (descending)
            final int aId = int.tryParse(a['id'].toString()) ?? 0;
            final int bId = int.tryParse(b['id'].toString()) ?? 0;

            final idCompare = bId.compareTo(aId);
            if (idCompare != 0) return idCompare;

            // 2️⃣ Future first, past last
            final aPast = a['isPast'] as bool;
            final bPast = b['isPast'] as bool;

            if (aPast && !bPast) return 1;
            if (!aPast && bPast) return -1;

            return 0;
          });

          bookings.assignAll(parsed);
        }
      } else {
        hasError.value = true;
        CustomNotification.show(
          title: "Error",
          message: "Failed to load bookings (status: ${response.statusCode})",
          isSuccess: false,
        );
      }
    } catch (e) {
      hasError.value = true;
      CustomNotification.show(
        title: "Error",
        message: "Failed to load bookings: ${e.toString()}",
        isSuccess: false,
      );
    } finally {
      isLoading.value = false;
      fetchBookedByMe(); // Also fetch booked by me
    }
  }

  // =============================================
  // LOAD SINGLE TRIP FOR EDITING
  // =============================================
  Future<bool> loadTripForEdit(String tripId) async {
    try {
      isSubmitting.value = true;
      final url = Uri.parse("$appurl/get_trip_details?trip_id=$tripId");
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["status"] == true) {
          final trip = json["trip_details"]["booking"];

          fromController.text = trip["start_location"] ?? '';
          toController.text = trip["end_location"] ?? '';
          remarksController.text = trip["remarks"] ?? '';
          selectedCar.value = trip["car_type"] ?? 'Innova';
          tripType.value =
              trip["trip_type"] == "two_way" ? "two_way" : "one_way";
          hasCarrier.value =
              (trip["carrier"]?.toString() ?? "0") == "1" ? "yes" : "no";
          sendWhatsapp.value =
              (trip["send_whatsapp"]?.toString() ?? "0") == "1";
          sendCall.value = (trip["send_call"]?.toString() ?? "0") == "1";

          // Date
          final dateStr = trip["trip_date"];
          if (dateStr != null) selectedDate.value = DateTime.parse(dateStr);

          // Time
          final timeStr = trip["trip_time"]?.toString();
          if (timeStr != null && timeStr.contains(":")) {
            final parts = timeStr.split(":");
            final hour = int.tryParse(parts[0]) ?? 12;
            final minute = int.tryParse(
                  parts.length > 1 ? parts[1].substring(0, 2) : "0",
                ) ??
                0;
            selectedTime.value = TimeOfDay(hour: hour, minute: minute);
          }

          return true;
        } else {
          CustomNotification.show(
            title: "Not Found",
            message: json["message"] ?? "Trip not found",
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      CustomNotification.show(
        title: "Error",
        message: "Failed to load trip details",
        isSuccess: false,
      );
      debugPrint("Load trip error: $e");
    } finally {
      isSubmitting.value = false;
    }
    return false;
  }

  // =============================================
  // UPDATE TRIP
  // =============================================
  Future<bool> updateTrip(String tripId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("$appurl/update_trip"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {"trip_id": tripId, ...data},
      ).timeout(const Duration(seconds: 20));

      final json = jsonDecode(response.body);
      if (json["status"] == true) {
        CustomNotification.show(
          title: "Success",
          message: "Booking updated successfully!",
          isSuccess: true,
        );
        fetchMyBookings();
        return true;
      } else {
        CustomNotification.show(
          title: "Failed",
          message: json["message"] ?? "Update failed",
          isSuccess: false,
        );
      }
    } catch (e) {
      CustomNotification.show(
        title: "Network Error",
        message: "Please check your connection",
        isSuccess: false,
      );
    }
    return false;
  }

  void updateExistingBooking(String tripId) async {
    var tTime =  selectedTime.value !=null ? selectedTime.value!.format(Get.context!):'';
    print("tTime "+tTime);
    if (fromController.text.trim().isEmpty ||
        toController.text.trim().isEmpty) {
      CustomNotification.show(
        title: "Required",
        message: "From & To cities are required",
        isSuccess: false,
      );
      return;
    }
    if (selectedTime.value == null) {
      CustomNotification.show(
        title: "Required",
        message: "Please select time",
        isSuccess: false,
      );
      return;
    }

    isSubmitting.value = true;

    final success = await updateTrip(tripId, {
      "car_type": selectedCar.value,
      "start_location": fromController.text.trim(),
      "end_location": toController.text.trim(),
      "trip_type": tripType.value,
      "trip_date": DateFormat('yyyy-MM-dd').format(selectedDate.value),
      // "trip_time": "${selectedTime.value!.hour.toString().padLeft(2, '0')}:${selectedTime.value!.minute.toString().padLeft(2, '0')}",
      "trip_time": tTime,
      "remarks": remarksController.text.trim(),
      "carrier": hasCarrier.value == 'yes' ? "1" : "0",
      "send_whatsapp": sendWhatsapp.value ? "1" : "0",
      "send_call": sendCall.value ? "1" : "0",
      "price_type": priceType.value, // fixed or negotiable
      "price": priceController.text.trim(),
    });

    isSubmitting.value = false;
    if (success) {
      clearForm();
      await Future.delayed(const Duration(milliseconds: 1000));
      Get.find<MyBookingController>().fetchMyBookings();
      Get.offAll(() => const MyBookingScreen());
    }
  }

  // Navigation
  void onEditBooking(String tripId) async {
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF6A1B9A))),
      barrierDismissible: false,
    );
    final success = await loadTripForEdit(tripId);
    Get.back();
    if (success) {
      Get.to(() => EditBookingScreen(tripId: tripId));
    }
  }

  void navigateToHome() =>
      Get.to(() => const HomeScreen(), transition: Transition.fadeIn);
  void navigateToProfile() =>
      Get.to(() => const ProfileScreen(), transition: Transition.fadeIn);
  void navigateToAlerts() =>
      Get.to(() => const AlertsScreen(), transition: Transition.fadeIn);
  void onNewBooking() => Get.to(() => const NewBookingScreen());
  void onFreeVehicle() {
    Get.to(() => const FreebookingNew(), transition: Transition.downToUp);
  }

  Future<bool> markAsBooked(String bookingId, String customerUnqId) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;

    try {
      final response = await http.post(
        Uri.parse("$appurl/update_booking_status"),
        body: {
          "booking_id": bookingId,
          "user_unq_id": customerUnqId.trim(),
        },
      ).timeout(const Duration(seconds: 15));

      final json = jsonDecode(response.body);

      if (json["status"] == true) {
        CustomNotification.show(
          title: "Success",
          message: "Booking updated successfully!",
          isSuccess: true,
        );
        fetchMyBookings(); // refresh list
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void clearForm() {
    fromController.clear();
    toController.clear();
    remarksController.clear();

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
    super.onClose();
  }
}
