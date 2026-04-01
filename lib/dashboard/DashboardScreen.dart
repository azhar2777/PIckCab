import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pickcab_partner/alerts/alerts_screen.dart';
import 'package:pickcab_partner/my_bookings/my_booking_screen.dart';
import 'package:pickcab_partner/profile/profile_screen.dart';

import '../home/home_screen.dart';
import 'DashboardController.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController controller = Get.put(DashboardController());

  final List<Widget> screens = [
    const HomeScreen(),
    const MyBookingScreen(),

    const AlertsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      body: IndexedStack(
        index: controller.selectedIndex.value,
        children: screens,
      ),

      bottomNavigationBar: SizedBox(
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 254, 237, 255),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
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
                  currentIndex: controller.selectedIndex.value,
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
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.bookmark_border),
                      label: 'My Bookings',
                    ),
                    BottomNavigationBarItem(
                      icon: SizedBox.shrink(),
                      label: '',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.notifications_outlined),
                      label: 'My Alerts',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      label: 'Profile',
                    ),
                  ],
                ),
                ),
              ),
            ),
            Positioned(
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
              const SizedBox(height: 20),
              _buildPostOption(
                icon: Icons.add_road,
                title: 'Smart Booking',
                onTap: () => {Get.back(), controller.navigateToSmartBooking()},
              ),
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
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
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
