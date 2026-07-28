import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pickcab_partner/alerts/alerts_screen.dart';
import 'package:pickcab_partner/my_bookings/my_booking_screen.dart';
import 'package:pickcab_partner/profile/profile_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:pickcab_partner/smartbooking/SmartBookingController.dart';

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
  ];

  var bottomheight = 60.0;

  @override
  void initState() {

    super.initState();
    controller.selectedIndex.value =  widget.selectedTab !=null ? widget.selectedTab : 0 ;
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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Obx(() => Scaffold(
      body: IndexedStack(
        index: controller.selectedIndex.value,
        children: screens,
      ),

      bottomNavigationBar: SizedBox(
        height: bottomheight + bottomInset,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 254, 237, 255),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.black12,
                //     blurRadius: 10,
                //     offset: Offset(0, -3),
                //   ),
                // ],
              ),
              child: SafeArea(
                top: false,
                child:
                BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: Color(0xFF6A1B9A),
                  unselectedItemColor: Colors.grey,
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  showUnselectedLabels: true,

                  currentIndex: controller.selectedIndex.value > 2 ? controller.selectedIndex.value+1 : controller.selectedIndex.value,
                  onTap: (index) {
                    if (index == 2) return; // 👈 ignore center item

                    if (index > 2) {
                      controller.changeTab(index - 1); // shift index
                    } else {
                      controller.changeTab(index);
                    }
                  },
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home, size: 22,),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.bookmark_border, size: 22,),
                      label: 'My Bookings',
                    ),
                    BottomNavigationBarItem(
                      icon: SizedBox.shrink(),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.notifications_outlined, size: 22,),
                      label: 'My Alerts',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline, size: 22,),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              // bottom: bottomheight == 60 ? 0 : 10,
              top: -6,
              child: GestureDetector(
                onTap: () => _showPostBottomSheet(context),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF7B2CAF), Color(0xFF5A189A)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6A1B9A).withOpacity(0.6),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 38),
                ),
              ),
            ),
          ],
        ),
      ),

    ),

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
              SizedBox(height: controller.showSmartBooking.value ? 20: 0),
              controller.showSmartBooking.value ?
              _buildPostOption(
                icon: Icons.auto_awesome,
                title: 'Quick Booking with AI',
                onTap: () {
                  Get.delete<SmartBookingController>();
                  Get.put(SmartBookingController());

                  Get.back();
                  controller.navigateToSmartBooking();
                },
              ):Container(),
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
          boxShadow: title == 'Quick Booking with AI' ? [
            BoxShadow(
              color: Color(0xFF6A1B9A),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3), // shadow position
            ),
          ]:[],
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

