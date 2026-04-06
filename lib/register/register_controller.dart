import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:pickcab_partner/dashboard/DashboardScreen.dart';
// import 'package:otp_autofill/otp_autofill.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../const/const.dart';
import '../const/custom_notification.dart';
import '../home/home_controller.dart';
import '../home/home_screen.dart';
import '../services/notification_service.dart';

class RegisterController extends GetxController {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final cityController = TextEditingController();
  final otpController = TextEditingController();

  // late OTPTextEditController otpController;

  var allCities = <String>[].obs;
  var filteredCities = <String>[].obs;
  var selectedCity = "".obs;

  var nameError = "".obs;
  var phoneError = "".obs;
  var emailError = "".obs;
  var cityError = "".obs;
  var imageError = "".obs;
  var otpError = "".obs;

  var isLoading = false.obs;
  var showOtpScreen = false.obs;
  var isVerifying = false.obs;

  var userId = "".obs;
  var capturedImage = Rxn<File>();

  RxBool isTermsAccepted = false.obs;
  RxString termsError = ''.obs;

  final picker = ImagePicker();

  // Device info
  String deviceId = '';
  String deviceName = '';
  String deviceModel = '';

  // App hash for SMS auto-read
  // final String appHash = 'At+Fmhi/iEQ'; // Your app hash - FIXED

  String appHash = '';

  static const MethodChannel _channel = MethodChannel('otp_retriever');

  @override
  Future<void> onInit() async {
    super.onInit();

    appHash = await getAppHash() ?? '';

    fetchIndianCities();
    getDeviceInfo();
    _startSmsListener();
    // getAppSignature(); // Fetch app hash for OTP SMS

    _channel.setMethodCallHandler((call) async {
      if (call.method == "onOtpReceived") {
        final otp = call.arguments as String;
        otpController.text = otp;
        verifyOtp(); // 🔥 auto submit
      }
    });

    _channel.invokeMethod('startOtpListener');
  }

  Future<String?> getAppHash() async {
    final hash = await _channel.invokeMethod('getAppHash');
    print("🔥 APP HASH: $hash");
    return hash;
  }

  // Future<void> getAppSignature() async {
  //   try {
  //     appHash = await OTPInteractor().getAppSignature();
  //     debugPrint("App Signature (hash): $appHash");
  //   } catch (e) {
  //     debugPrint("Failed to get app hash: $e");
  //   }
  // }

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
          if (showOtpScreen.value) {
            Future.delayed(const Duration(milliseconds: 200), () {
              verifyOtp();
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

  Future<void> getDeviceInfo() async {
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

  void toggleTerms(bool? value) {
    isTermsAccepted.value = value ?? false;
    if (isTermsAccepted.value) {
      termsError.value = '';
    }
  }

  Future<void> fetchIndianCities() async {
    if (allCities.isNotEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(
            "https://countriesnow.space/api/v0.1/countries/cities/q?country=India"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["error"] == false && data["data"] is List) {
          final List<String> cities = (data["data"] as List).cast<String>();
          cities.sort();
          allCities.assignAll(cities);
          filteredCities.assignAll(cities);
        }
      }
    } catch (e) {
      debugPrint("Failed to load cities: $e");
    }
  }

  Future<void> captureImage() async {
    try {
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );
      if (photo != null) {
        capturedImage.value = File(photo.path);
        imageError.value = "";
      }
    } catch (e) {
      CustomNotification.show(
        title: "Camera Error",
        message: "Unable to access camera",
        isSuccess: false,
      );
    }
  }

  Future<void> register() async {

    nameError.value =
        phoneError.value = cityError.value = imageError.value = "";

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    // final email = emailController.text.trim();
    final city = selectedCity.value.isNotEmpty
        ? selectedCity.value
        : cityController.text.trim();

    if (!isTermsAccepted.value) {
      termsError.value = "Please accept Terms & Conditions";
      return;
    }

    if (name.isEmpty) nameError.value = "Full name required";
    if (!RegExp(r'^\d{10}$').hasMatch(phone))
      phoneError.value = "Enter valid 10-digit number";
    if (city.isEmpty) cityError.value = "Please select your city";
    if (capturedImage.value == null)
      imageError.value = "Profile photo required";

    if (nameError.value.isNotEmpty ||
        phoneError.value.isNotEmpty ||
        cityError.value.isNotEmpty ||
        imageError.value.isNotEmpty) {

      return;
    }

    isLoading.value = true;

    try {

      final bytes = await capturedImage.value!.readAsBytes();
      final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";

      final otp = (100000 + Random().nextInt(900000)).toString();
      print("$appurl/register");

      final registerResponse = await http.post(
        Uri.parse("$appurl/register"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "user_name": name,
          "user_mobile": phone,
          // "user_email": email,
          "city": city,
          "user_image": base64Image,
          "user_type": "Agent",
          "otp": otp,
          "device_id": deviceId,
          "device_name": deviceName,
          "device_model": deviceModel,
        },
      );
      print(otp);

      final data = jsonDecode(registerResponse.body);

      if (data["status"] == true) {
        userId.value = data["user_id"].toString();

        // Prepare SMS with app hash for auto-read
        String message =
            "<#> $otp is your one-time Login/Signup verification code for PickCab Partner $appHash";

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
          showOtpScreen.value = true;
          CustomNotification.show(
            title: "Success",
            message: "OTP sent successfully!",
            isSuccess: true,
          );
        } else {
          CustomNotification.show(
            title: "SMS Failed",
            message: "Registration done, but OTP sending failed. Try resend.",
            isSuccess: false,
          );
        }
      } else {
        CustomNotification.show(
          title: "Registration Failed",
          message: data["message"] ?? "Please try again",
          isSuccess: false,
        );
      }
    } catch (e) {
      CustomNotification.show(
        title: "Error",
        message: "Something went wrong. Check your connection.",
        isSuccess: false,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    otpError.value = "";
    final otp = otpController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      otpError.value = "Enter valid 6-digit OTP";
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

      final data = jsonDecode(response.body);
      if (data["status"] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("user_id", userId.value);
        await prefs.setString("app_name", "pickcab");
        await prefs.setBool("is_logged_in", true);
        Get.put(HomeController(), permanent: true);
        NotificationService.updateTokenAfterLogin(); // Token updated
        Get.offAll(() => DashboardScreen(selectedTab: 0,));
      } else {
        otpError.value = data["message"] ?? "Invalid OTP";
      }
    } catch (e) {
      CustomNotification.show(
        title: "Error",
        message: "Network error",
        isSuccess: false,
      );
    } finally {
      isVerifying.value = false;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cityController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
