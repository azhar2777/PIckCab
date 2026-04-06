import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../../includes/header.dart';
import '../Booking_details/booking_details_screen.dart';
import 'home_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = Get.put(HomeController(), permanent: true);

  @override
  void initState() {
    super.initState();
    controller.fetchAvailableBookings();
    controller.fetchAvailablefreeBookings();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Scaffold(
      appBar: const AppHeader(),
      backgroundColor: Colors.white,
      body: Obx(() {
        final isBookingsTab = controller.selectedTab.value == 0;
        final displayList = isBookingsTab
            ? controller.filteredBookings
            : controller.filteredfreeBookings;

        return Column(
          children: [
            // Main Tabs (Bookings/Free Vehicles)
            Container(
              margin: const EdgeInsets.fromLTRB(10, 2, 16, 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _tabButton(
                    title: "Bookings",
                    isActive: isBookingsTab,
                    onTap: () => controller.switchTab(0),
                  ),
                  _tabButton(
                    title: "Free Vehicles",
                    isActive: !isBookingsTab,
                    onTap: () => controller.switchTab(1),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () => _showCitySearchDialog(context, controller),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: controller.searchQuery.value.isEmpty
                          ? Colors.grey.shade200
                          : const Color(0xFF6A1B9A),
                      width: controller.searchQuery.value.isEmpty ? 1.0 : 1.8,
                    ),
                    boxShadow: controller.searchQuery.value.isNotEmpty
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6A1B9A).withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 20,
                        color: controller.searchQuery.value.isEmpty
                            ? Colors.grey.shade500
                            : const Color(0xFF6A1B9A),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          controller.searchQuery.value.isEmpty
                              ? "Search by From city..."
                              : controller.searchQuery.value,
                          style: TextStyle(
                            fontSize: 15.5,
                            color: controller.searchQuery.value.isEmpty
                                ? Colors.grey.shade600
                                : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (controller.searchQuery.value.isNotEmpty)
                        GestureDetector(
                          onTap: controller.clearSearch,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            Expanded(
              child: controller.isApiCalled.value
                  ? RefreshIndicator(
                      onRefresh: () async {
                        await controller.refreshBookings();
                      },
                      color: const Color(0xFF6A1B9A),
                      child: controller.isLoading.value
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF6A1B9A),
                              ),
                            )
                          : displayList.isEmpty
                              ? _buildEmptyState(
                                  controller.searchQuery.value.isNotEmpty
                                      ? "No trips from '${controller.searchQuery.value}'"
                                      : "No available bookings yet",
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(5),
                                  itemCount: displayList.length,
                                  itemBuilder: (context, index) =>
                                      _buildBookingCard(
                                    displayList[index],
                                    controller,
                                    isBookingsTab ? "booking" : "free",
                                  ),
                                ),
                    )
                  : Container(
                      child: Center(
                        child: Stack(
                          children: [
                            Center(
                              child: Image.asset(
                                "assets/images/ic_logo.jpeg",
                                fit: BoxFit.contain,
                                // width: MediaQuery.of(context).size.width*0.95,
                                height: 100,
                              ),
                            ),
                            Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                  child: CircularProgressIndicator(
                                color: Color(0xFF6A1B9A),
                              ),

                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        );
      }),

      // // Bottom Navigation + FAB
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
      //                 selectedFontSize: 10,
      //                 unselectedFontSize: 10,
      //                 showUnselectedLabels: true,
      //                 currentIndex: 0,
      //                 onTap: (i) {
      //                   if (i == 1) controller.navigateToMyBooking();
      //                   if (i == 2) _showPostBottomSheet(context);
      //                   if (i == 3) controller.navigateToAlerts();
      //                   if (i == 4) controller.navigateToProfile();
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
      //         // Floating center button
      //         Positioned(
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

  // ==================== WIDGET BUILDERS ====================

  Widget _tabButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6A1B9A) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'No Bookings',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDottedRoute(String from, String to, bool isTwoWay) {
    const dotColor = Color(0xFF6A1B9A);
    const double triangleSize = 9.0;
    const double lineHeight = 1.8;

    return Row(
      children: [
        Text(
          from,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -22,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isTwoWay ? Icons.sync_alt : Icons.arrow_forward,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final available = constraints.maxWidth - (triangleSize * 1.2);
                  final dotCount = (available / 6).floor().clamp(8, 100);
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: triangleSize),
                    child: Row(
                      children: List.generate(
                        dotCount,
                        (_) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.2),
                            height: lineHeight,
                            color: dotColor.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                color: Colors.white,
                child: Text(
                  isTwoWay ? "Round Trip" : "One Way",
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (isTwoWay)
                Positioned(
                  left: -1,
                  child: Triangle(
                    color: dotColor.withOpacity(0.9),
                    size: triangleSize,
                    left: true,
                  ),
                ),
              Positioned(
                right: -1,
                child: Triangle(
                  color: dotColor.withOpacity(0.9),
                  size: triangleSize,
                  left: false,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          to,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  String maskMobileNumbers(String text) {
    final RegExp mobileRegex = RegExp(
      r'\b(?:\+91|91|0)?[6-9]\d{9}\b',
    );

    return text.replaceAllMapped(mobileRegex, (Match match) {
      String number = match.group(0)!;
      if (number.startsWith('+91')) {
        number = number.substring(3);
      } else if (number.startsWith('91')) {
        number = number.substring(2);
      } else if (number.startsWith('0')) {
        number = number.substring(1);
      }
      if (number.length == 10) {
        return 'XXXXXXXXXX';
      }
      return match.group(0)!;
    });
  }

  Widget _buildBookingCard(
    Map<String, dynamic> booking,
    HomeController controller,
    String itemType,
  ) {
    final bool isTwoWay = (booking['isTwoWay'] as bool?) ?? false;
    bool isBooked = (booking['status']?.toString() ?? "") == "0";
    if (booking['mark_booked'].toString() == "1") {
      isBooked = true;
    }

    print(
        "${booking['id']} isBooked $isBooked mark_booked ${booking['mark_booked'].toString()}");

    final bool isVerified = (booking['verified'] as bool?) ?? false;

    // Check if booking is expired
    final bool isExpired = itemType == "booking"
        ? controller.isBookingExpired(booking)
        : controller.isFreeBookingExpired(booking);

    final int carrier =
        int.tryParse(booking['carrier']?.toString() ?? "0") ?? 0;
    final String tripId = booking['trip_id']?.toString() ?? "N/A";
    String rate = booking['price'] != null ? "₹${booking['price']}" : "";
    final String from = booking['from'] ?? "Unknown";
    final String to = booking['to'] ?? "Unknown";
    final String remarks = (booking['remarks'] ?? '').toString().trim();
    final String pricetype = (booking['price_type'] ?? '').toString().trim();
    final String bookingid = (booking['id'] ?? '').toString().trim();

    if (pricetype == "negotiable") {
      rate = "$rate @";
    }

    final bool canSendWhatsApp =
        (booking['send_whatsapp']?.toString() == "1") ||
            (booking['send_whatsapp'] == true) ||
            (booking['send_whatsapp'] == 1);

    final bool canSendCall = (booking['send_call']?.toString() == "1") ||
        (booking['send_call'] == true) ||
        (booking['send_call'] == 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpired
              ? Colors.orange.shade200 // Changed from red to orange
              : const Color.fromARGB(255, 174, 174, 174),
          width: isExpired ? 1.8 : 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpired
                ? Colors.orange.withOpacity(0.05) // Changed from red to orange
                : Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row with ID and Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              itemType == "booking"
                  ? GestureDetector(
                      onTap: () {
                        Get.to(BookingDetailsScreen(
                          bookingId: bookingid,
                        ));
                      },
                      child: Text(
                        "ID: $tripId",
                        style: TextStyle(
                          fontSize: 13,
                          color: isExpired ? Colors.grey : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          // decoration: isExpired ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    )
                  : Container(),
              Row(
                children: [
                  // Booked Badge - Changed from "Expired" to "Booked"
                  // if (isExpired)
                  //   Container(
                  //     margin: const EdgeInsets.only(right: 8),
                  //     padding: const EdgeInsets.symmetric(
                  //         horizontal: 10, vertical: 5),
                  //     decoration: BoxDecoration(
                  //       color: Colors
                  //           .orange.shade100, // Changed from red to orange
                  //       borderRadius: BorderRadius.circular(20),
                  //       border: Border.all(
                  //           color: Colors
                  //               .orange.shade400), // Changed from red to orange
                  //     ),
                  //     child: Row(
                  //       mainAxisSize: MainAxisSize.min,
                  //       children: [
                  //         Icon(Icons.bookmark,
                  //             color: Colors.orange.shade700,
                  //             size: 14), // Changed from timer_off to bookmark
                  //         const SizedBox(width: 4),
                  //         Text(
                  //           "Booked", // Changed from "Expired" to "Booked"
                  //           style: TextStyle(
                  //             color: Colors.orange
                  //                 .shade700, // Changed from red to orange
                  //             fontSize: 11,
                  //             fontWeight: FontWeight.bold,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // Verified Badge
                  if (isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color.fromARGB(166, 29, 178, 3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield,
                              color: Color.fromARGB(213, 4, 156, 19), size: 15),
                          const SizedBox(width: 4),
                          Text(
                            "Verified",
                            style: TextStyle(
                              color: const Color.fromARGB(208, 3, 191, 21),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Route Display (for regular bookings)
          if (itemType == "booking") _buildDottedRoute(from, to, isTwoWay),
          const SizedBox(height: 10),

          // Date and Time with Booked indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${HomeController.formatTripDate(booking["date"])} @ ${booking["time"]}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isExpired ? Colors.grey : Colors.redAccent,
                  // decoration: isExpired ? TextDecoration.lineThrough : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Time Ago and Carrier Badge
          Row(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.grey : const Color(0xFF6A1B9A),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.orange.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    HomeController.timeAgo(booking['added_on']),
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),
              if (carrier == 1)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isExpired ? Colors.grey : const Color(0xFF6A1B9A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Need Carrier",
                    style: TextStyle(
                        color: const Color.fromARGB(255, 247, 247, 247),
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Car Type and Rate/Free In
          (itemType == "booking")
              ? Row(
                  children: [
                    Expanded(
                        child: _infoBox(
                            "Car Type",
                            booking['carType'] ?? "Sedan",
                            Colors.grey.shade100,
                            isExpired)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _infoBox(
                            "Rate", rate, Colors.grey.shade100, isExpired)),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                        child: _infoBox(
                            "Car Type",
                            booking['carType'] ?? "Sedan",
                            Colors.grey.shade100,
                            isExpired)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _infoBox("Free In", booking["from"],
                            Colors.grey.shade100, isExpired)),
                  ],
                ),

          // Remarks Section
          if (remarks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isExpired ? Colors.grey.shade100 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isExpired
                          ? Colors.grey.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Opacity(
                    opacity: isBooked || isExpired ? 0.3 : 1.0,
                    child: Text(
                      maskMobileNumbers("$remarks"),
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: isBooked || isExpired
                            ? Colors.grey.shade500
                            : Colors.black87,
                        fontStyle: isBooked || isExpired
                            ? FontStyle.italic
                            : FontStyle.normal,
                        // decoration:                            isExpired ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
                // Booked Stamp - Using the existing booked.png for all booked/expired bookings
                if (isBooked || isExpired)
                  Positioned(
                    top: -2,
                    right: 4,
                    child: Transform.rotate(
                      angle: 0.2,
                      child: Image.asset(
                        "assets/images/ic_booked.png",
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Action Buttons - Only for active (non-booked) and non-expired bookings
          if (!isBooked && !isExpired)
            Row(
              children: [
                // Share button
                Expanded(
                  child: _actionButton(
                    Icons.share_rounded,
                    () =>
                        controller.shareBooking(itemType == "booking", booking),
                  ),
                ),
                const SizedBox(width: 12),
                // WhatsApp button
                if (canSendWhatsApp) ...[
                  Expanded(
                    child: _actionButton(
                      FontAwesomeIcons.whatsapp,
                      () => controller.openWhatsApp(
                          itemType == "booking", booking['mobile'], booking),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                // Call button
                if (canSendCall)
                  Expanded(
                    child: _actionButton(
                      Icons.call,
                      () => controller.makePhoneCall(
                          booking['mobile'], bookingid),
                    ),
                  ),
              ],
            ),

          // Booked Message - Show message for booked/expired bookings
          if ((isBooked || isExpired) && !isBooked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isExpired
                        ? "This booking has been booked" // Changed from expired message
                        : "This booking is confirmed",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value, Color bgColor, bool isExpired) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isExpired ? Colors.grey.shade100 : bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired ? Colors.grey.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 10,
                color: isExpired ? Colors.grey.shade500 : Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isExpired ? Colors.grey.shade500 : const Color(0xFF6A1B9A),
              // decoration: isExpired ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF6A1B9A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        alignment: Alignment.center,
      ),
    );
  }

  // void _showPosBottomSheet(BuildContext context) {
  //   Get.bottomSheet(
  //     SafeArea(
  //       child: Container(
  //         padding: const EdgeInsets.all(20),
  //         decoration: const BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //         ),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Text(
  //               'Post',
  //               style: GoogleFonts.montserrat(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(height: 20),
  //             _buildPostOption(
  //               icon: Icons.add_road,
  //               title: 'Smart Booking',
  //               onTap: () => {Get.back(), controller.navigateToSmartBooking()},
  //             ),
  //             const SizedBox(height: 20),
  //
  //             _buildPostOption(
  //               icon: Icons.add_road,
  //               title: 'New Booking',
  //               onTap: () => {Get.back(), controller.onNewBooking()},
  //             ),
  //             const SizedBox(height: 12),
  //             _buildPostOption(
  //               icon: Icons.directions_car,
  //               title: 'Free Vehicle',
  //               onTap: () => {Get.back(), controller.onFreeVehicle()},
  //             ),
  //             const SizedBox(height: 20),
  //           ],
  //         ),
  //       ),
  //     ),
  //     isScrollControlled: true,
  //   );
  // }
  //
  // Widget _buildPostOption({
  //   required IconData icon,
  //   required String title,
  //   required VoidCallback onTap,
  // }) {
  //   return InkWell(
  //     onTap: onTap,
  //     borderRadius: BorderRadius.circular(12),
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
  //       decoration: BoxDecoration(
  //         border: Border.all(color: Colors.grey.shade300),
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(icon, color: const Color(0xFF6A1B9A)),
  //           const SizedBox(width: 16),
  //           Text(title, style: const TextStyle(fontSize: 16)),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _showCitySearchDialog(BuildContext context, HomeController c) {
    final searchController = TextEditingController();
    final searchFocusNode = FocusNode();
    const apiKey = "AIzaSyAVaPMPGqeahxVzZbpEJGbGkiW0RNMzIEM";

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (searchFocusNode.canRequestFocus) {
              FocusScope.of(ctx).requestFocus(searchFocusNode);
            }
          });
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  width: 42,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Search City",
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6A1B9A),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GooglePlaceAutoCompleteTextField(
                    focusNode: searchFocusNode,
                    textEditingController: searchController,
                    googleAPIKey: apiKey,
                    inputDecoration: InputDecoration(
                      hintText: "Search city e.g. Ranchi, Patna, Surat...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon:
                          const Icon(Icons.search, color: Color(0xFF6A1B9A)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    debounceTime: 500,
                    countries: const ["in"],
                    isLatLngRequired: false,
                    itemClick: (Prediction prediction) {
                      final raw = prediction.description ?? '';
                      String city = _extractCleanCity(prediction);

                      if (city.isEmpty &&
                          prediction.structuredFormatting?.mainText != null) {
                        city = prediction.structuredFormatting!.mainText!;
                      }

                      if (city.isEmpty) {
                        Get.snackbar("Error", "Could not read city name");
                        return;
                      }

                      c.updateSearch(city);

                      Get.snackbar(
                        "Selected",
                        "Searching for trips from $city",
                        backgroundColor: const Color(0xFF6A1B9A),
                        colorText: Colors.white,
                        duration: const Duration(seconds: 2),
                      );

                      Navigator.pop(ctx);
                    },
                    getPlaceDetailWithLatLng: (Prediction prediction) {},
                    seperatedBuilder: const Divider(),
                    isCrossBtnShown: true,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Search for trips from specific cities",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        });
  }

  String _extractCleanCity(Prediction prediction) {
    if (prediction.description == null) return "";

    String description = prediction.description!;

    if (description.contains(", India")) {
      description = description.replaceAll(", India", "");
    }

    final parts = description.split(",");
    if (parts.isNotEmpty) {
      return parts[0].trim();
    }

    return description.trim();
  }
}

class Triangle extends StatelessWidget {
  final Color color;
  final double size;
  final bool left;
  const Triangle({
    super.key,
    required this.color,
    required this.size,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TrianglePainter(color: color, left: left),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool left;
  const _TrianglePainter({required this.color, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (left) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
