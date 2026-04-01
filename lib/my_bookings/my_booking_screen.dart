import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../includes/header.dart';
import 'items/booked_card.dart';
import 'items/booking_card.dart';
import 'my_booking_controller.dart';

class MyBookingScreen extends StatefulWidget {
  const MyBookingScreen({super.key});

  @override
  State<MyBookingScreen> createState() => _MyBookingScreenState();
}

class _MyBookingScreenState extends State<MyBookingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await MyBookingController.to.fetchMyBookings();
      await MyBookingController.to.fetchBookedByMe();
    });
  }

  void _showPostBottomSheet(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Post',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(height: 24),
              _buildOption(Icons.add_road, 'New Booking', () {
                Get.back();
                MyBookingController.to.onNewBooking();
              }),
              const SizedBox(height: 16),
              _buildOption(Icons.directions_car, 'Free Vehicle', () {
                Get.back();
                MyBookingController.to.onFreeVehicle();
              }),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildOption(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6A1B9A), size: 28),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String bookingId) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
            const SizedBox(width: 12),
            const Text("Delete Booking?",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () async {
              Get.back();
              await MyBookingController.to.deleteBooking(bookingId);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Get.put(MyBookingController(), permanent: true);

    return Scaffold(
      appBar: AppHeader(),
      backgroundColor: Colors.grey.shade50,
      body: Obx(() {
        final c = MyBookingController.to;

        if (c.isLoading.value) {
          return Center(
              child: CircularProgressIndicator(color: const Color(0xFF6A1B9A)));
        }

        final myBookings = c.bookings;
        final bookedByMe = c.bookedByMe;

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              // Tab Bar with Counts
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: const Color(0xFF6A1B9A),
                  unselectedLabelColor: Colors.grey.shade600,
                  indicatorColor: const Color(0xFF6A1B9A),
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  tabs: [
                    Tab(text: "My Booking (${myBookings.length})"),
                    Tab(text: "Book By Me (${bookedByMe.length})"),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(bottom: 10),
                  child: TabBarView(
                    children: [
                      _buildMyBookingsList(context, myBookings, c),
                      _buildBookedByMeList(context, bookedByMe, c),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
      // bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // List for My Bookings tab (with edit/delete functionality and expired overlay)
  Widget _buildMyBookingsList(BuildContext context,
      List<Map<String, dynamic>> bookings, MyBookingController c) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await c.fetchMyBookings();
          await c.fetchBookedByMe();
        },
        child: _buildEmptyState("No active trips yet"),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await c.fetchMyBookings();
        await c.fetchBookedByMe();
      },
      color: const Color(0xFF6A1B9A),
      child: ListView.builder(
        padding: const EdgeInsets.all(5),
        itemCount: bookings.length,
        itemBuilder: (_, i) => BookingCard(
          booking: bookings[i],
          isMyBookingTab: true, // This is the My Bookings tab
          onEdit: () => c.onEditBooking(bookings[i]['id'].toString()),
          onDelete: () =>
              _showDeleteConfirmation(context, bookings[i]['id'].toString()),
          onMarkAsBooked: (bookingId, unqId) async {
            await c.markAsBooked(bookingId, unqId);
          },
        ),
      ),
    );
  }

  // List for Book By Me tab (view only, no expired overlay)
  Widget _buildBookedByMeList(BuildContext context,
      List<Map<String, dynamic>> bookings, MyBookingController c) {
    if (bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await c.fetchMyBookings();
          await c.fetchBookedByMe();
        },
        child: _buildEmptyState("No bookings booked by you yet"),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await c.fetchMyBookings();
        await c.fetchBookedByMe();
      },
      color: const Color(0xFF6A1B9A),
      child: ListView.builder(
        padding: const EdgeInsets.all(5),
        itemCount: bookings.length,
        itemBuilder: (_, i) => BookedCard(
          booking: bookings[i],

          isMyBookingTab: false, // This is the Book By Me tab
          onEdit: null, // No edit in this tab
          onDelete: null, // No delete in this tab
          onMarkAsBooked: (bookingId, unqId) async {
            await c.markAsBooked(bookingId, unqId);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return LayoutBuilder(
      builder: (_, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car,
                    size: 90, color: Colors.grey.shade400),
                const SizedBox(height: 24),
                Text(
                  'My Bookings',
                  style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 254, 237, 255),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -3))
                ],
              ),
              child: SafeArea(
                top: false,
                child: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: const Color(0xFF6A1B9A),
                  unselectedItemColor: Colors.grey.shade600,
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  showUnselectedLabels: true,
                  currentIndex: 1,
                  onTap: (i) {
                    if (i == 0) MyBookingController.to.navigateToHome();
                    if (i == 2) _showPostBottomSheet(context);
                    if (i == 3) MyBookingController.to.navigateToAlerts();
                    if (i == 4) MyBookingController.to.navigateToProfile();
                  },
                  items: const [
                    BottomNavigationBarItem(
                        icon: Icon(Icons.home), label: 'Home'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.bookmark_border),
                        label: 'My Bookings'),
                    BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.notifications_outlined),
                        label: 'My Alerts'),
                    BottomNavigationBarItem(
                        icon: Icon(Icons.person_outline), label: 'Profile'),
                  ],
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
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7B2CAF), Color(0xFF5A189A)]),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0xFF6A1B9A).withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A1B9A),
            ),
          ),
        ],
      ),
    );
  }
}

