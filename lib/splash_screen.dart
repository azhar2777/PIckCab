import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/home_screen.dart';
import '../login/login_screen.dart';
import '../Booking_details/booking_details_screen.dart';
import '../free_booking_details/booking_details_screen.dart';

class SplashScreen extends StatefulWidget {
  final String? bookingId;
  final String? bookingType;

  const SplashScreen({
    super.key,
    this.bookingId,
    this.bookingType,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigated = false; // 🔥 Prevent double navigation

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_navigated) {
        handleNavigation();
      }
    });
  }

  Future<void> handleNavigation() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    final appname = prefs.getString("app_name");

    print(widget.bookingId);

    if (appname == "pickcab" &&
        userId != null &&
        userId.isNotEmpty &&
        userId != "null") {
      if (widget.bookingId != "null" &&
          widget.bookingId != "" &&
          widget.bookingId != null) {
        Get.off(() => BookingDetailsScreen(bookingId: widget.bookingId!));
      } else {
        Get.offAll(() => const HomeScreen());
      }
    } else {
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
