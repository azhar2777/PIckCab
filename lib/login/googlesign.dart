import 'dart:convert';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../const/const.dart';
import '../home/home_screen.dart';
import '../register/resgister_screen.dart';

class LoginController_backup extends GetxController {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  var phoneError = ''.obs;
  var isLoading = false.obs;
  var isVerifying = false.obs;
  var showOTP = false.obs;
  var resendTimer = 30.obs;
  var userId = ''.obs;
  final showAnimation = false.obs;

  // Device info
  String deviceId = '';
  String deviceName = '';
  String deviceModel = '';

  @override
  void onInit() async {
    super.onInit();
    // Get device information
    await _getDeviceInfo();

    // Start animation after a small delay when screen loads
    Future.delayed(const Duration(milliseconds: 800), () {
      showAnimation.value = true;
    });
  }

  // -------------------- GET DEVICE INFORMATION -----------------------
  Future<void> _getDeviceInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (GetPlatform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceName = androidInfo.device;
        deviceModel = androidInfo.model;
      } else if (GetPlatform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceName = iosInfo.name;
        deviceModel = iosInfo.model;
      }
    } catch (e) {
      deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      deviceName = 'Unknown Device';
      deviceModel = 'Unknown Model';
    }
  }

  // -------------------- SEND OTP (LOGIN API) -----------------------
  Future<void> sendOTP() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty || phone.length != 10) {
      phoneError.value = "Enter valid 10-digit number";
      return;
    }

    isLoading.value = true;
    phoneError.value = "";

    try {
      final otp = (100000 + Random().nextInt(900000)).toString();

      // Check if user is already logged in on another device
      final checkResponse = await http.post(
        Uri.parse("$appurl/check_existing_session"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "user_mobile": phone,
          "device_id": deviceId,
          "device_name": deviceName,
          "device_model": deviceModel,
        },
      );

      final checkJson = jsonDecode(checkResponse.body);

      if (checkJson["status"] == false &&
          checkJson["message"] == "already_logged_in") {
        // Show dialog for existing session
        Get.dialog(
          _existingSessionDialog(
            otherDeviceInfo: checkJson["device_info"] ?? "another device",
            onContinue: () async {
              Get.back();
              await _proceedWithOTP(phone, otp);
            },
            onCancel: () {
              Get.back();
              isLoading.value = false;
            },
          ),
          barrierDismissible: false,
        );
        return;
      }

      // Proceed with normal OTP flow
      await _proceedWithOTP(phone, otp);
    } catch (e) {
      phoneError.value = "Something went wrong!";
      isLoading.value = false;
    }
  }

  // -------------------- PROCEED WITH OTP SENDING -----------------------
  Future<void> _proceedWithOTP(String phone, String otp) async {
    try {
      // Step 1: Send OTP to backend
      final response = await http.post(
        Uri.parse("$appurl/login"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "user_mobile": phone,
          "otp": otp,
          "device_id": deviceId,
          "device_name": deviceName,
          "device_model": deviceModel,
        },
      );

      final json = jsonDecode(response.body);
      var msg = json["message"];

      if (json["status"] == true) {
        // Step 2: Send SMS via SMS gateway
        final smsUrl =
            "http://sms.gitysoft.com/rest/services/sendSMS/sendGroupSms"
            "?AUTH_KEY=20e676ce315bed4a3955fb13e131631d"
            "&message=${Uri.encodeComponent('$otp is Your One Time Verification Code - PickCab Partner')}"
            "&senderId=PPCAB8"
            "&routeId=1"
            "&mobileNos=$phone"
            "&smsContentType=english";

        final smsResponse = await http.get(Uri.parse(smsUrl));

        if (smsResponse.statusCode == 200) {
          userId.value = json["user_id"].toString();
          showOTP.value = true;
          startResendTimer();
        }
      } else {
        phoneError.value = msg;
      }
    } catch (e) {
      phoneError.value = "Failed to send OTP";
    }

    isLoading.value = false;
  }

  // -------------------- VERIFY OTP API -----------------------
  Future<void> verifyOTP() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      Get.snackbar("Error", "Enter valid 6-digit OTP");
      return;
    }

    isVerifying.value = true;

    try {
      final response = await http.post(
        Uri.parse("$appurl/verify_otp"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "user_id": userId.value,
          "otp": otp,
          "device_id": deviceId,
          "device_name": deviceName,
          "device_model": deviceModel,
        },
      );

      final json = jsonDecode(response.body);

      if (json["status"] == true) {
        // Save login state with device info
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("is_logged_in", true);
        await prefs.setString("user_id", userId.value);
        await prefs.setString("device_id", deviceId);
        await prefs.setString("login_time", DateTime.now().toIso8601String());

        // Send login notification to server
        await _sendLoginNotification();

        Get.offAll(() => HomeScreen());
      } else {
        Get.snackbar(
          "Invalid OTP",
          json["message"] ?? "Wrong OTP, please try again",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar("Error", "Something went wrong!");
    }

    isVerifying.value = false;
  }

  // -------------------- SEND LOGIN NOTIFICATION TO SERVER -----------------------
  Future<void> _sendLoginNotification() async {
    try {
      await http.post(
        Uri.parse("$appurl/user_login_status"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "user_id": userId.value,
          "device_id": deviceId,
          "device_name": deviceName,
          "device_model": deviceModel,
          "status": "login",
          "login_time": DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Silent fail - not critical
    }
  }

  // -------------------- EXISTING SESSION DIALOG -----------------------
  Widget _existingSessionDialog({
    required String otherDeviceInfo,
    required VoidCallback onContinue,
    required VoidCallback onCancel,
  }) {
    return AlertDialog(
      title: Text(
        "Already Logged In",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "You're already logged in on:",
            style: GoogleFonts.poppins(),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              otherDeviceInfo,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Do you want to log out from that device and continue here?",
            style: GoogleFonts.poppins(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            "Cancel",
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text(
            "Logout & Continue",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      ],
    );
  }

  // -------------------- TIMER -----------------------
  void startResendTimer() {
    resendTimer.value = 30;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (resendTimer.value > 0) {
        resendTimer.value--;
        return true;
      }
      return false;
    });
  }

  // -------------------- CHANGE NUMBER -----------------------
  void goBackToMobile() {
    showOTP.value = false;
    otpController.clear();
  }

  // -------------------- NAVIGATE TO REGISTER -----------------------
  void NavigateToRegister() {
    Get.to(() => const RegisterScreen());
  }

  @override
  void onClose() {
    phoneController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
