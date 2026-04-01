
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

import '../alerts/alerts_screen.dart';
import '../freebooking/freebooking_new.dart';
import '../my_bookings/my_booking_screen.dart';
import '../new_booking/new_booking_screen.dart';
import '../profile/profile_screen.dart';
import '../smartbooking/SmartBookingScreen.dart';

class DashboardController  extends GetxController {
  static DashboardController get to => Get.find();

  var selectedIndex = 0.obs;

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  // ==================== NAVIGATION ====================

  void navigateToMyBooking() =>
      Get.to(() => const MyBookingScreen(), transition: Transition.fadeIn);

  void navigateToAlerts() =>
      Get.to(() => const AlertsScreen(), transition: Transition.fadeIn);

  void navigateToProfile() =>
      Get.to(() => const ProfileScreen(), transition: Transition.fadeIn);

  void onNewBooking() =>
      Get.to(() => const NewBookingScreen(), transition: Transition.downToUp);

  void onFreeVehicle() {
    Get.to(() => const FreebookingNew(), transition: Transition.downToUp);
  }

  void navigateToSmartBooking() =>
      Get.to(() => const SmartBookingScreen(), transition: Transition.fadeIn);


}