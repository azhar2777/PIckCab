import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/Get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../const/const.dart';
import '../const/custom_notification.dart';
import '../login/login_screen.dart';

class Editprofilecontroller extends GetxController {
  static Editprofilecontroller get to => Get.find();
  var isRed = true.obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isOtpVerifying = false.obs;

  final RxMap<String, dynamic> user = <String, dynamic>{
    'name': '',
    'phone': '',
    'email': '',
    'user_unq_id': '',
    'city': '',
    'aadhar_verified': '0',
    'aadhar_verified_on': null,
    'dl_verified': '0',
    'rating': 0.0,
    'avatarUrl': 'https://i.pravatar.cc/300',
    'verified': false,
  }.obs;

  final nameController = TextEditingController();
  final cityController = TextEditingController();

  var nameError = "".obs;
  var cityError = "".obs;
  var imageError = "".obs;

  var allCities = <String>[].obs;
  var filteredCities = <String>[].obs;
  var selectedCity = "".obs;

  final picker = ImagePicker();
  var capturedImage = Rxn<File>();

  @override
  void onInit() {
    fetchUserProfile();
    super.onInit();
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
          print(data);

          user.assignAll({
            'name': data["user_name"] ?? "Unknown User",
            'phone': data["user_mobile"] ?? "Not provided",
            'email': data["user_email"] ?? "Not provided",
            'city': data["city"] ?? "",
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

          print("user_____ " + user.value.toString());

          nameController.text = user.value['name'];
          cityController.text = user.value['city'];
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
  }

  void updateProfile() async {
    isSubmitting.value = true;
    nameError.value = "";
    cityError.value = "";
    print("updateProfile pressed");
    var name = nameController.text.trim();
    final city = selectedCity.value.isNotEmpty
        ? selectedCity.value
        : cityController.text.trim();
    if (name.isEmpty) {
      nameError.value = "Full name is required";

    }
    if (city.isEmpty) {
      cityError.value = "City is required";
    }

    if(name.isEmpty || city.isEmpty){
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id");

      print(userId);




      var postData = {};

      postData['user_id'] = userId;
      postData['user_name'] = name;
      postData['city'] = city;
      if(capturedImage.value != null){
        final bytes = await capturedImage.value!.readAsBytes();
        final base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
        postData['user_image'] = base64Image;
      }
      print(appurl+"updateProfile");
      print(postData);

      final response = await http.post(
        Uri.parse(appurl+"updateProfile"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: postData,
      );

      isSubmitting.value = false;
      final data = jsonDecode(response.body);
      print(data);

      if (data["status"] == true) {
        CustomNotification.show(
          title: "Success",
          message: data["message"] ?? "Profile Updated",
          isSuccess: true ,
        );
      } else {
        CustomNotification.show(
          title: "Failed",
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
}
