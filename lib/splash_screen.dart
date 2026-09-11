import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Booking_details/booking_details_screen.dart';
import 'dashboard/DashboardScreen.dart';
import 'login/login_screen.dart';

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

class _SplashScreenState extends State<SplashScreen>
    with WidgetsBindingObserver {

  bool _started = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Use addPostFrameCallback to ensure widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_navigated) {
        handleNavigation();
      }
    });

    // WidgetsBinding.instance.addObserver(this);
    //
    // /// Wait until first frame is rendered
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (_started) return;
    //
    //   _started = true;
    //
    //   startFlow();
    // });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  Future<void> handleNavigation() async {
    try {
      if (!mounted) return;

      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      if (!mounted) return;

      final String? userId =
      prefs.getString("user_id");

      final String? appName =
      prefs.getString("app_name");

      final bool isLoggedIn =
          appName == "pickcab" &&
              userId != null &&
              userId.isNotEmpty &&
              userId != "null";

      if (!mounted) return;

      // -----------------------------------------------------
      // USER LOGGED IN
      // -----------------------------------------------------

      if (isLoggedIn) {

        final bool hasBooking =
            widget.bookingId != null &&
                widget.bookingId!.isNotEmpty &&
                widget.bookingId != "null";

        if (hasBooking) {

          Get.offAll(
                () => BookingDetailsScreen(
              bookingId: widget.bookingId!,
            ),
          );

        } else {

          Get.offAll(
                () => const DashboardScreen(
              selectedTab: 0,
            ),
          );
        }

      }

      // -----------------------------------------------------
      // LOGIN
      // -----------------------------------------------------

      else {

        Get.offAll(
              () => const LoginScreen(),
        );
      }

    } catch (e, stack) {
      debugPrint("Navigation error: $e");
      debugPrintStack(stackTrace: stack);

      if (mounted) {
        Get.offAll(() => const LoginScreen());
      }
    }
  }

  // =========================================================
  // APP LIFECYCLE
  // =========================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint("Lifecycle state: $state");

    super.didChangeAppLifecycleState(state);
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}