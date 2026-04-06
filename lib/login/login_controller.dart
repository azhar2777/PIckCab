import 'dart:convert';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pickcab_partner/dashboard/DashboardScreen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../const/const.dart';
import '../home/home_screen.dart';
import '../register/resgister_screen.dart';

class LoginController extends GetxController {
  final phoneController = TextEditingController();
  var otpController = TextEditingController();
  // var  OTPTextEditController otpController;

  var phoneError = ''.obs;
  var isLoading = false.obs;
  var isVerifying = false.obs;
  var showOTP = false.obs;
  var resendTimer = 60.obs; // increased to 60s (common for OTP)
  var userId = ''.obs;
  final showAnimation = false.obs;

  // Device info
  String deviceId = '';
  String deviceName = '';
  String deviceModel = '';

  // App hash for SMS auto-read
  // String? appHash;

  // final String appHash = 'At+Fmhi/iEQ'; // Your app hash - FIXED

  String appHash = '';

  static const MethodChannel _channel = MethodChannel('otp_retriever');

  @override
  void onInit() async {
    super.onInit();
    await _getDeviceInfo();

    appHash = await getAppHash() ?? '';

    // getAppHash();

    _startSmsListener();

    Future.delayed(const Duration(milliseconds: 800), () {
      showAnimation.value = true;
    });

    debugPrint('📱 Using App Hash: $appHash');
  }

  Future<String?> getAppHash() async {
    final hash = await _channel.invokeMethod('getAppHash');
    print("🔥 APP HASH: $hash");
    return hash;
  }

  Future<void> _startSmsListener() async {
    try {
      await _channel.invokeMethod('startSmsListener');

      _channel.setMethodCallHandler((call) async {
        if (call.method == "onOtpReceived") {
          final otp = call.arguments as String;
          debugPrint("📱 OTP Received Silently: $otp");

          // Set OTP in field
          otpController.text = otp;

          // Auto verify if OTP screen is showing
          if (showOTP.value) {
            Future.delayed(const Duration(milliseconds: 200), () {
              verifyOTP();
            });
          }
        }
        return null;
      });

      debugPrint("✅ Silent SMS listener started");
    } catch (e) {
      debugPrint("❌ Failed to start SMS listener: $e");
    }
  }

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

      await _proceedWithOTP(phone, otp);
    } catch (e) {
      phoneError.value = "Something went wrong!";
      isLoading.value = false;
    }
  }

  void navigateToRegister() {
    Get.to(
      () => const RegisterScreen(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 300),
    );
  }

  // Future<void> startListeningForOtp() async {
  //   try {
  //     await otpController.startListenUserConsent(
  //       (code) {
  //         final exp = RegExp(r'(\d{6})');
  //         return exp.stringMatch(code ?? '') ?? '';
  //       },
  //       // timeout: const Duration(minutes: 5), // optional
  //     );
  //   } catch (e) {
  //     debugPrint("Error starting OTP listener: $e");
  //   }
  // }

  Future<void> _proceedWithOTP(String phone, String otp) async {
    try {
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
      print("phone $phone");

      final json = jsonDecode(response.body);
      var msg = json["message"];

      if (json["status"] == true) {
        // Format SMS with app hash for auto-read
        String message =
            "<#> $otp is your one-time Login/Signup verification code for PickCab Partner \n$appHash";

        final smsUrl =
            "http://sms.gitysoft.com/rest/services/sendSMS/sendGroupSms"
            "?AUTH_KEY=20e676ce315bed4a3955fb13e131631d"
            "&message=${Uri.encodeComponent(message)}"
            "&senderId=PPCAB8"
            "&routeId=1"
            "&mobileNos=$phone"
            "&smsContentType=english";

        final smsResponse = await http.get(Uri.parse(smsUrl));

        if (smsResponse.statusCode == 200) {
          userId.value = json["user_id"].toString();
          showOTP.value = true;
          startResendTimer();
        } else {
          Get.snackbar("SMS Error", "Failed to send OTP message");
        }
      } else {
        phoneError.value = msg;
      }
    } catch (e) {
      phoneError.value = "Failed to send OTP";
    }

    isLoading.value = false;
  }

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
        final phone = phoneController.text.trim();
        final checkResponse = await http.post(
          Uri.parse("$appurl/checkLoginStatus"),
          headers: {"Content-Type": "application/x-www-form-urlencoded"},
          body: {"user_mobile": phone},
        );

        final checkJson = jsonDecode(checkResponse.body);

        if (checkJson["status"] == false &&
            checkJson["message"] == "already_logged_in") {
          Get.dialog(
            _existingSessionDialog(
              otherDeviceInfo: checkJson["device_info"] ?? "another device",
              onContinue: () async {
                Get.back();
                // await _proceedWithOTP(phone, otp);

                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool("is_logged_in", true);
                await prefs.setString("user_id", userId.value);
                await prefs.setString("app_name", "pickcab");
                await prefs.setString("device_id", deviceId);
                await prefs.setString(
                    "login_time", DateTime.now().toIso8601String());

                await _sendLoginNotification();

                Get.offAll(() => DashboardScreen(selectedTab: 0,));
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
      // silent fail
    }
  }

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
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(
            "Logout & Continue",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      ],
    );
  }

  void startResendTimer() {
    resendTimer.value = 60;

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (resendTimer.value > 0) {
        resendTimer.value--;
        return true;
      }
      return false;
    });
  }

  void goBackToMobile() {
    showOTP.value = false;
    otpController.clear();
    resendTimer.value = 60;
  }

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
