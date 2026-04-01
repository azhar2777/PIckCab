// lib/profile/profile_controller.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pickcab_partner/edit_profile/EditProfileScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../alerts/alerts_screen.dart';
import '../const/const.dart';
import '../const/custom_notification.dart';
import '../freebooking/freebooking_new.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';
import '../my_bookings/my_booking_screen.dart';
import '../new_booking/new_booking_screen.dart';
import 'addhardetail.dart';
import 'profile_screen.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  // ── Controllers for Aadhaar verification dialog ──
  final aadhaarController = TextEditingController();
  final otpController = TextEditingController();

  final RxString refId = ''.obs;

  final RxMap<String, dynamic> user = <String, dynamic>{
    'name': 'Loading...',
    'phone': '',
    'email': '',
    'user_unq_id': '',
    'aadhar_verified': '0',
    'aadhar_verified_on': null,
    'dl_verified': '0',
    'rating': 0.0,
    'avatarUrl': 'https://i.pravatar.cc/300',
    'verified': false,
  }.obs;

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxBool isOtpSending = false.obs;
  final RxBool isOtpVerifying = false.obs;

  final ImagePicker _picker = ImagePicker();

  Rx<AadhaarDetails?> aadhaarDetails = Rx<AadhaarDetails?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
    checkAadhaarStatus();
  }

  @override
  void onClose() {
    aadhaarController.dispose();
    otpController.dispose();
    super.onClose();
  }

  void clearAadhaarFields() {
    aadhaarController.clear();
    otpController.clear();
  }

  // ────────────────────────────── Fetch Profile ──────────────────────────────
  Future<void> fetchUserProfile({bool showLoading = true}) async {
    if (showLoading) isLoading.value = true;
    hasError.value = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id");

      print(userId);

      if (userId == null || userId == "0") {
        Get.offAll(() => LoginScreen());
        return;
      }

      final url = Uri.parse("$appurl/user_details?user_id=$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["status"] == true) {
          final data = json["user_data"];

          user.assignAll({
            'name': data["user_name"] ?? "Unknown User",
            'phone': data["user_mobile"] ?? "Not provided",
            'email': data["user_email"] ?? "Not provided",
            'user_unq_id': data["user_unq_id"] ?? "N/A",
            'aadhar_verified': data["aadhar_verified"]?.toString() ?? "0",
            'aadhar_verified_on': data["aadhar_verified_on"],
            'dl_verified': data["dl_verified"]?.toString() ?? "0",
            'rating':
                double.tryParse(data["rating"]?.toString() ?? "4.8") ?? 4.8,
            'avatarUrl': (data["user_image"] != null &&
                    data["user_image"].toString().isNotEmpty)
                ? "$imageurl/${data["user_image"]}"
                : "https://i.pravatar.cc/300?u=$userId",
            'verified': data["verified"] == true || data["verified"] == "1",
          });
        } else {
          throw Exception(json["message"] ?? "Failed to load profile");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Profile fetch error: $e");
      hasError.value = true;
      CustomNotification.show(
        title: "Connection Error",
        message: "Failed to load profile. Pull to refresh.",
        isSuccess: false,
      );
    } finally {
      isLoading.value = false;
    }
    checkAadhaarStatus();
  }

  // ────────────────────────────── Aadhaar OTP Request ──────────────────────────────
  Future<bool> requestAadhaarOtp({required String aadhaarNumber}) async {
    isOtpSending.value = true;
    refId.value = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";

      if (userId.isEmpty) {
        CustomNotification.show(
          title: "Authentication Required",
          message: "Please login again to continue.",
          isSuccess: false,
        );
        return false;
      }

      final uri = Uri.parse("$appurl/aadhaar/send_otp");
      final request = http.MultipartRequest('POST', uri);

      request.fields.addAll({
        "user_id": userId,
        "MethodName": "sendotp",
        "refid": refId.value,
        "aadhar_number": aadhaarNumber,
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final bool status = json["status"] ?? false;
        final String message = json["message"] ?? "";

        if (status) {
          CustomNotification.show(
            title: "Success",
            message: message.isNotEmpty ? message : "OTP sent successfully",
            isSuccess: true,
          );
          return true;
        } else {
          CustomNotification.show(
            title: "Request Failed",
            message: message.isNotEmpty ? message : "Could not send OTP.",
            isSuccess: false,
          );
          return false;
        }
      } else {
        CustomNotification.show(
          title: "Server Error",
          message: "Error ${response.statusCode}",
          isSuccess: false,
        );
        return false;
      }
    } catch (e) {
      CustomNotification.show(
        title: "Error",
        message: "Failed to send OTP: ${e.toString()}",
        isSuccess: false,
      );
      return false;
    } finally {
      isOtpSending.value = false;
    }
  }

  // ────────────────────────────── Verify Aadhaar OTP ──────────────────────────────
  Future<bool> verifyAadhaarWithOtp({required String aadhaarOtp}) async {
    isOtpVerifying.value = true;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id") ?? "";

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$appurl/aadhaar/verify_otp"),
      );

      request.fields.addAll({
        'user_id': userId,
        'Token': token ?? '',
        'MethodName': 'verifyOTP',
        'refid': refId.value ?? '',
        'otp': aadhaarOtp,
        'aad': '',
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        CustomNotification.show(
          title: "Server Error",
          message:
              "${response.statusCode} - ${response.reasonPhrase ?? 'Unknown'}",
          isSuccess: false,
        );
        return false;
      }

      final json = jsonDecode(response.body);
      final bool isSuccess = json["status"] == true;

      // ── Focus & close dialog safely ──
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 120));

      Get.back(); // Close dialog

      await Future.delayed(const Duration(milliseconds: 80));

      if (isSuccess) {
        aadhaarDetails.value = AadhaarDetails.fromJson(
          json["data"] as Map<String, dynamic>,
        );

        CustomNotification.show(
          title: "Verified",
          message:
              json["message"]?.toString() ?? "Aadhaar verified successfully",
          isSuccess: true,
        );

        Get.offAll(() => const ProfileScreen());
        return true;
      } else {
        CustomNotification.show(
          title: "Verification Failed",
          message: json["message"]?.toString() ??
              "Invalid OTP or verification failed",
          isSuccess: false,
        );

        Get.offAll(() => const ProfileScreen());
        return false;
      }
    } catch (e) {
      FocusManager.instance.primaryFocus?.unfocus();
      await Future.delayed(const Duration(milliseconds: 120));
      Get.back();

      CustomNotification.show(
        title: "Error",
        message: "Verification failed: ${e.toString().split('\n').first}",
        isSuccess: false,
      );

      Get.offAll(() => const ProfileScreen());
      return false;
    } finally {
      isOtpVerifying.value = false;
    }
  }

  // ────────────────────────────── Check Aadhaar Status ──────────────────────────────
  Future<bool> checkAadhaarStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";

      if (userId.isEmpty) return false;

      final uri = Uri.parse('$appurl/check_aadhar_status?user_id=$userId');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["status"] == true) {
          final verified =
              json["aadhar_verified"] == 1 || json["aadhar_verified"] == "1";
          if (verified) {
            user['aadhar_verified'] = '1';
            user['aadhar_verified_on'] = json["aadhar_verified_on"]?.toString();
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      print("checkAadhaarStatus error: $e");
      return false;
    }
  }

  // ────────────────────────────── Update Aadhaar in DB ──────────────────────────────
  Future<bool> updateAadhaarVerification(
      {required AadhaarDetails aadhaar}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "";

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$appurl/update_aadhar_verification'),
      );

      request.fields.addAll({
        'aadhar_no': aadhaar.aadhaarNumber ?? '',
        'aadhar_verified': '1',
        'aadhar_verified_on': DateTime.now().toString().substring(0, 19),
        'aadhar_details_json': jsonEncode({
          "name": aadhaar.name,
          "dob": aadhaar.dob,
          "gender": aadhaar.gender,
          "address": {
            "house": aadhaar.address.house,
            "street": aadhaar.address.street,
            "vtc": aadhaar.address.vtc,
            "district": aadhaar.address.district,
            "state": aadhaar.address.state,
            "pincode": aadhaar.address.pincode,
          }
        }),
        'user_id': userId,
      });

      final response = await request.send();

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      CustomNotification.show(
        title: "Error",
        message: "Failed to save Aadhaar details",
        isSuccess: false,
      );
      return false;
    }
  }

  // Navigation methods (unchanged)
  void navigateToHome() =>
      Get.to(() => const HomeScreen(), transition: Transition.fadeIn);
  void navigateToMyBooking() =>
      Get.to(() => const MyBookingScreen(), transition: Transition.fadeIn);
  void navigateToAlerts() =>
      Get.to(() => const AlertsScreen(), transition: Transition.fadeIn);
  void onNewBooking() =>
      Get.to(() => const NewBookingScreen(), transition: Transition.fadeIn);
  void onFreeVehicle() =>
      Get.to(() => const FreebookingNew(), transition: Transition.downToUp);


  Future<void> navigateToEditProfile() async {
    await Get.to(
          () => const Editprofilescreen(),
      transition: Transition.fadeIn,
    );

    // 🔥 This runs when user comes back
    fetchUserProfile(); // or controller.fetchData()
  }
  Future<void> navigateToLogout() async {
    final prefs = await SharedPreferences.getInstance();
// final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id") ?? "0";
    // OPTIONAL: Store OTP in backend for verification
    final response = await http.post(
      Uri.parse("$appurl/logout"),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: {
        "user_id": userId,
      },
    );
    final json = jsonDecode(response.body);
    var msg = json["message"];
    if (json["status"] == true) {
      await prefs.setBool("is_logged_in", true);

      await prefs.remove('is_logged_in');
      await prefs.remove('user_id');
      await prefs.remove('device_id');
      await prefs.remove('login_time');
      await prefs.remove('app_name');

      await prefs.clear();
      Get.offAll(() => LoginScreen());
      CustomNotification.show(
        title: "Logged Out",
        message: "See you soon!",
        isSuccess: true,
      );
    }
  }
}
