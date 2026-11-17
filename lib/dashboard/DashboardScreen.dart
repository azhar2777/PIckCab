import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pickcab_partner/alerts/alerts_screen.dart';
import 'package:pickcab_partner/chatlist/ChatListScreen.dart';
import 'package:pickcab_partner/my_bookings/my_booking_screen.dart';
import 'package:pickcab_partner/profile/profile_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:pickcab_partner/smartbooking/SmartBookingController.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../chats/ChatScreen.dart';
import '../home/home_screen.dart';
import 'DashboardController.dart';

class DashboardScreen extends StatefulWidget {
  final int selectedTab;

  const DashboardScreen({super.key, required this.selectedTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardController controller = Get.put(DashboardController());
  final List<Widget> screens = [
    const HomeScreen(),
    const MyBookingScreen(),

    const AlertsScreen(),
    const ProfileScreen(),
    // const ChatScreen(bookingId: "23507", userUniqueId: "898", userName:'John Cena'),
    // const ChatListScreen(),
  ];

  var bottomheight = 60.0;
  final WebViewController webController = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted);

  @override
  void initState() {
    super.initState();
    controller.selectedIndex.value =
        widget.selectedTab != null ? widget.selectedTab : 0;
    _checkAndroidVersion(); // 👈 call async method
  }

  void _checkAndroidVersion() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      if (androidInfo.version.sdkInt >= 35) {
        setState(() {
          bottomheight = 75.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: screens,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Transform.translate(
          offset: const Offset(0, 10), // Move 10px down
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7B2CAF),
                  Color(0xFF5A189A),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A1B9A).withOpacity(0.8),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton(
              elevation: 0,
              backgroundColor: Colors.transparent,
              shape: const CircleBorder(),
              onPressed: () {
                _showPostBottomSheet(context);
              },
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 45,
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 254, 237, 255),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  _buildNavItem(Icons.home, 'Home', 0),
                  _buildNavItem(Icons.bookmark_border, 'My Bookings', 1),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _showPostBottomSheet(context);
                    },
                    child: const SizedBox(
                      width: 60,
                      height: 60,
                    ),
                  ),
                  _buildNavItem(Icons.notifications_outlined, 'My Alerts', 2),
                  // _buildNavItem(Icons.chat, 'Chats', 3),
                  _buildNavItem(Icons.person_outline, 'Profile', 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = controller.selectedIndex.value == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          controller.changeTab(index);
        },
        child: SizedBox(
          height: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? const Color(0xFF6A1B9A) : Colors.grey,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? const Color(0xFF6A1B9A) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostBottomSheetNotice(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.9,
          width: MediaQuery.of(context).size.width * 0.98,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Expanded(
            child: ListView(
              children: [
                Obx(() {
                  if (controller.noticeHtml.value.isEmpty) {
                    return const Center(
                      child: Text('No HTML available'),
                    );
                  }

                  webController.loadHtmlString(
                    controller.noticeHtml.value,
                  );

                  return WebViewWidget(
                    controller: webController,
                  );
                })
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showPostBottomSheet(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Post',
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: controller.showSmartBooking.value ? 20 : 0),
              controller.showSmartBooking.value
                  ? _buildPostOption(
                      icon: Icons.auto_awesome,
                      title: 'Quick Booking with AI',
                      onTap: () {
                        Get.delete<SmartBookingController>();
                        Get.put(SmartBookingController());

                        Get.back();
                        controller.navigateToSmartBooking();
                      },
                    )
                  : Container(),
              const SizedBox(height: 20),
              _buildPostOption(
                icon: Icons.add_road,
                title: 'New Booking',
                onTap: () => {Get.back(), controller.onNewBooking()},
              ),
              const SizedBox(height: 12),
              _buildPostOption(
                icon: Icons.directions_car,
                title: 'Free Vehicle',
                onTap: () => {Get.back(), controller.onFreeVehicle()},
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildPostOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        // decoration: BoxDecoration(
        //   border: Border.all(color: Colors.grey.shade300),
        //   borderRadius: BorderRadius.circular(12),
        // ),
        decoration: BoxDecoration(
          color: Colors.white, // required for shadow visibility
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: title == 'Quick Booking with AI'
              ? [
                  BoxShadow(
                    color: Color(0xFF6A1B9A),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 3), // shadow position
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6A1B9A)),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
