
import 'dart:convert';

import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../alerts/alerts_screen.dart';
import '../const/const.dart';
import '../const/custom_notification.dart';
import '../freebooking/freebooking_new.dart';
import '../home/home_controller.dart';
import '../login/login_screen.dart';
import '../my_bookings/my_booking_controller.dart';
import '../my_bookings/my_booking_screen.dart';
import '../new_booking/new_booking_screen.dart';
import '../profile/profile_screen.dart';
import '../smartbooking/SmartBookingScreen.dart';

class DashboardController  extends GetxController {
  static DashboardController get to => Get.find();

  var selectedIndex = 0.obs;
  // Show Smart booking
  final RxBool showSmartBooking = false.obs;
  final List<String> allowedMobiles = <String>[
    "8828451293", "9572511011", "9122220415", "7491010771", "9876543220", "9876543210"
  ];

  void changeTab(int index) {
    selectedIndex.value = index;

    if (index == 0) {
      Get.find<HomeController>().callAllFunctions();
    } else if (index == 1) {
      Get.find<MyBookingController>().fetchMyBookings();
    }
  }
  @override
  void onInit() {
    fetchUserProfile();
    super.onInit();
  }

  // ==================== NAVIGATION ====================

  void navigateToMyBooking() =>
      Get.to(() => const MyBookingScreen(), transition: Transition.fadeIn);

  void navigateToAlerts() =>
      Get.to(() => const AlertsScreen(), transition: Transition.fadeIn);

  void navigateToProfile() =>
      Get.to(() => const ProfileScreen(), transition: Transition.fadeIn);

  void onNewBooking() =>
      Get.to(() => const NewBookingScreen(), transition: Transition.downToUp)?.then((_) {
        Get.find<MyBookingController>().fetchMyBookings();
      });

  void onFreeVehicle() {
    Get.to(() => const FreebookingNew(), transition: Transition.downToUp);
  }

  // void navigateToSmartBooking() =>
  //     Get.to(() => const SmartBookingScreen(), transition: Transition.fadeIn);
  void navigateToSmartBooking() =>
    Get.to(() => SmartBookingScreen(), transition: Transition.fadeIn)?.then((_) {
      Get.find<MyBookingController>().fetchMyBookings();
    });


  // ==================== Fetch User Details ====================
  Future<void> fetchUserProfile() async {



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
          // print("UserData");
          // print(data);

          final prefs = await SharedPreferences.getInstance();

          await prefs.setString("mobile_number", data['user_mobile']);

          if(allowedMobiles.contains("${data['user_mobile']}")){
            showSmartBooking.value = true;
          }


          // print("Prefs${prefs.getString("mobile_number")}");




        } else {
          throw Exception(json["message"] ?? "Failed to load profile");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Profile fetch error: $e");
      CustomNotification.show(
        title: "Connection Error",
        message: "Failed to load profile. Pull to refresh.",
        isSuccess: false,
      );
    } finally {

    }
  }


}