// lib/profile/profile_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pickcab_partner/profile/ProfileShareCard.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../dashboard/DashboardController.dart';
import '../includes/header.dart';
import '../support/support_screen.dart';
import 'addhardetail.dart';
import 'profile_controller.dart';

class OthereProfileScreen extends StatefulWidget {
  final String userId;
  const OthereProfileScreen({super.key, required this.userId});

  @override
  State<OthereProfileScreen> createState() => _OthereProfileScreenState();
}

final controller = Get.put(ProfileController(), permanent: true);
final controllerDashboard = Get.put(DashboardController(), permanent: true);

class _OthereProfileScreenState extends State<OthereProfileScreen> with RouteAware {
  final GlobalKey shareKey = GlobalKey();

  @override
  void initState() {
    print("ProfileScreen fetchUserProfile");
    controllerDashboard.fetchOthersProfile(widget.userId);

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }


  @override
  Widget build(BuildContext context) {
    // final controller = Get.put(ProfileController(), permanent: true);

    return Scaffold(
      appBar: const AppHeader(),
      backgroundColor: Colors.grey.shade50,
      body: Obx(() {
        final user = controller.user;
        final isLoading = controller.isLoading.value;

        final String aadharStatus = user['aadhar_verified']?.toString() ?? '0';
        final String dlStatus = user['dl_verified']?.toString() ?? '0';

        return RefreshIndicator(
          onRefresh: () => controller.fetchUserProfile(showLoading: false),
          color: const Color(0xFF6A1B9A),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                Text(
                  controllerDashboard.userProfile["user_name"]?.toString() ?? "",
                ),

                Text(
                  controllerDashboard.userProfile["user_mobile"]?.toString() ?? "",
                ),

                Text(
                  controllerDashboard.userProfile["user_email"]?.toString() ?? "",
                ),

                Text(
                  controllerDashboard.userProfile["user_city"]?.toString() ?? "",
                ),

              ],
            ],
          ),
        );
      }),

      // EXACT SAME BOTTOM NAVIGATION + FAB AS HOME SCREEN

      // bottomNavigationBar: SafeArea(
      //   child: SizedBox(
      //     height: 60,
      //     child: Stack(
      //       clipBehavior: Clip.none,
      //       alignment: Alignment.bottomCenter,
      //       children: [
      //         Container(
      //           decoration: const BoxDecoration(
      //             color: Color.fromARGB(255, 254, 237, 255),
      //             borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      //             boxShadow: [
      //               BoxShadow(
      //                 color: Colors.black12,
      //                 blurRadius: 10,
      //                 offset: Offset(0, -3),
      //               ),
      //             ],
      //           ),
      //           child: SafeArea(
      //             top: false,
      //             child: MediaQuery.removePadding(
      //               context: context,
      //               removeBottom: true,
      //               child: BottomNavigationBar(
      //                 type: BottomNavigationBarType.fixed,
      //                 backgroundColor: Colors.transparent,
      //                 elevation: 0,
      //                 selectedItemColor: Color(0xFF6A1B9A),
      //                 unselectedItemColor: Colors.grey,
      //                 selectedFontSize: 10, // 👈 small adjustment
      //                 unselectedFontSize: 10,
      //                 showUnselectedLabels: true,
      //                 currentIndex: 4, // Profile is active
      //                 onTap: (i) {
      //                   if (i == 0) ProfileController.to.navigateToHome();
      //                   if (i == 1) ProfileController.to.navigateToMyBooking();
      //                   if (i == 2) _showPostBottomSheet(context);
      //                   if (i == 3) ProfileController.to.navigateToAlerts();
      //                   // i == 4 → stay on Profile
      //                 },
      //                 items: const [
      //                   BottomNavigationBarItem(
      //                     icon: Icon(Icons.home),
      //                     label: 'Home',
      //                   ),
      //                   BottomNavigationBarItem(
      //                     icon: Icon(Icons.bookmark_border),
      //                     label: 'My Bookings',
      //                   ),
      //                   BottomNavigationBarItem(
      //                     icon: SizedBox.shrink(),
      //                     label: '',
      //                   ),
      //                   BottomNavigationBarItem(
      //                     icon: Icon(Icons.notifications_outlined),
      //                     label: 'My Alerts',
      //                   ),
      //                   BottomNavigationBarItem(
      //                     icon: Icon(Icons.person_outline),
      //                     label: 'Profile',
      //                   ),
      //                 ],
      //               ),
      //             ),
      //           ),
      //         ),
      //
      //         /// Floating center button
      //         Positioned(
      //           // bottom: 28,
      //           child: GestureDetector(
      //             onTap: () => _showPostBottomSheet(context),
      //             child: Container(
      //               width: 68,
      //               height: 68,
      //               decoration: BoxDecoration(
      //                 shape: BoxShape.circle,
      //                 gradient: LinearGradient(
      //                   colors: [Color(0xFF7B2CAF), Color(0xFF5A189A)],
      //                 ),
      //                 boxShadow: [
      //                   BoxShadow(
      //                     color: Color(0xFF6A1B9A).withOpacity(0.6),
      //                     blurRadius: 20,
      //                     offset: Offset(0, 8),
      //                   ),
      //                 ],
      //               ),
      //               child: const Icon(Icons.add, color: Colors.white, size: 38),
      //             ),
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }
}

class AadhaarInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if ((i == 3 || i == 7) && i != digits.length - 1) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
