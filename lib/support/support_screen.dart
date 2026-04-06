import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pickcab_partner/dashboard/DashboardScreen.dart';
import 'package:pickcab_partner/support/support_details.screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../includes/header.dart';
import '../alerts/alerts_screen.dart';
import '../const/const.dart';
import '../freebooking/freebooking_new.dart';
import '../home/home_screen.dart';
import '../my_bookings/my_booking_screen.dart';
import '../new_booking/new_booking_screen.dart';

// Model updated to match API response
class SupportTicket {
  final String id;
  final String message;
  final String messageType;
  final String status; // "0" = pending, etc.
  final DateTime? submittedAt; // API doesn't send date → optional

  SupportTicket({
    required this.id,
    required this.message,
    required this.messageType,
    required this.status,
    this.submittedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id']?.toString() ?? '',
      message: json['message'] ?? '',
      messageType: json['message_type'] ?? 'Request',
      status: json['status']?.toString() ?? '0',
      // submittedAt: no date in API → leave null or parse if added later
    );
  }
}

// Controller
class SupportController extends GetxController {
  static SupportController get to => Get.find();

  final RxList<SupportTicket> tickets = <SupportTicket>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  final List<String> supportTypes = [
    'Booking Issue',
    'App Bug/Crash',
    'Driver Related',
    'Account Issue',
    'Other',
  ];

  final selectedType = RxString('');
  final commentController = TextEditingController();

  // final String baseUrl = 'https://guplfx.com/pickcab/api/support';
  // ← change to https if needed + remove double slash if present in real URL

  // Replace with real user ID (from auth controller, shared prefs, etc.)
  // final String userId = '12'; // ← TEMPORARY – MUST COME FROM AUTH LAYER

  @override
  void onInit() {
    super.onInit();
    selectedType.value = supportTypes.first;
    fetchTickets();
  }

  Future<void> fetchTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");

    try {
      isLoading(true);
      errorMessage('');

      final uri = Uri.parse('$appurl/support/mySupports?user_id=$userId');
      final request = http.Request('GET', uri);

      final response = await request.send();

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final jsonData = jsonDecode(body);
        print(jsonData);

        if (jsonData['status'] == true) {
          final List<dynamic> data = jsonData['data'] ?? [];
          tickets.assignAll(
            data.map((item) => SupportTicket.fromJson(item)).toList(),
          );
        } else {
          errorMessage(jsonData['message'] ?? 'Failed to load tickets');
        }
      } else {
        errorMessage('Server error: ${response.reasonPhrase}');
      }
    } catch (e) {
      errorMessage('Network error: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> submitTicket() async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString("user_id");

    if (commentController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please describe your issue',
          backgroundColor: Colors.red.shade100, colorText: Colors.red.shade900);
      return;
    }

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$appurl/support/add'),
      );

      request.fields.addAll({
        'user_id': userId.toString(),
        'message': commentController.text.trim(),
        'message_type':
            '${selectedType.value}', // or 'Request' if backend expects fixed value
      });

      // print("selectedType.value ${selectedType.value}");

      final response = await request.send();

      Get.back(); // close loading

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);

        if (json['status'] == true) {
          Get.snackbar('Success', 'Ticket submitted successfully',
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green.shade900);

          commentController.clear();
          // Refresh list
          fetchTickets();
        } else {
          Get.snackbar('Error', json['message'] ?? 'Failed to submit',
              backgroundColor: Colors.red.shade100);
        }
      } else {
        Get.snackbar('Error', 'Server error: ${response.reasonPhrase}',
            backgroundColor: Colors.red.shade100);
      }
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Something went wrong: $e',
          backgroundColor: Colors.red.shade100);
    }
  }

  // Navigation methods...
  void navigateToHome() => Get.offAll(() => DashboardScreen(selectedTab: 0,), transition: Transition.fadeIn);
  // ... rest same
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  late final SupportController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<SupportController>()) {
      Get.put(SupportController(), permanent: true);
    }
    controller = Get.find<SupportController>();
  }

  // _showPostBottomSheet, _buildPostOption, _option methods remain THE SAME

  String _formatDate(DateTime? date) {
    if (date == null) return 'Recently';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
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
                title: 'New Booking',
                onTap: () {
                  Get.back();
                  Get.to(() => const NewBookingScreen(),
                      transition: Transition.fadeIn);
                },
              ),
              const SizedBox(height: 12),
              _buildPostOption(
                icon: Icons.directions_car,
                title: 'Free Vehicle',
                onTap: () {
                  Get.back();
                  Get.to(() => const FreebookingNew(),
                      transition: Transition.downToUp);
                },
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

  Widget _option(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6A1B9A)),
            const SizedBox(width: 16),
            Text(title),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: const AppHeader(),
      appBar: AppBar(
        title: Text(
          "Support",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: controller.fetchTickets,
        color: const Color(0xFF6A1B9A),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 80, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(controller.errorMessage.value),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: controller.fetchTickets,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Support",
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6A1B9A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Submit a new support request or view your previous tickets",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),

                // Submit form (same as before)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Submit New Ticket",
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() => DropdownButtonFormField<String>(
                            value: controller.selectedType.value,
                            decoration: InputDecoration(
                              labelText: "Support Type",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF8E24AA),
                                  width: 2,
                                ),
                              ),
                            ),
                            items: controller.supportTypes
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null)
                                controller.selectedType.value = val;
                            },
                          )),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.commentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: "Describe your issue",
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF8E24AA),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.submitTicket,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A1B9A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Submit Ticket",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  "Your Support Tickets",
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 30),

                if (controller.tickets.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.support_agent,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text("No support tickets yet",
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = controller.tickets[index];
                      return InkWell(
                        onTap:  () async =>{
                          // Get.to(() => SupportDetailsScreen(supportTicket: controller.tickets[index],), transition: Transition.fadeIn)
                          await Get.to(
                                () => SupportDetailsScreen(
                              supportTicket: controller.tickets[index],
                            ),
                            transition: Transition.fadeIn,
                          ),

                          controller.fetchTickets(),
                    },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(

                                  children: [
                                    Chip(
                                      label: Text(
                                        ticket.messageType,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: const Color(0xFF6A1B9A),
                                    ),

                                    const Spacer(),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _formatDate(ticket.submittedAt),
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 8,),

                                      ],
                                    ),

                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  ticket.message,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ticket.status == "1" ?
                                    Text(
                                      "Status: ${ticket.status == "1" ? "Resolved" : "In Progress"}",
                                      style: TextStyle(
                                        color: ticket.status == "1"
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ):Container(),
                                    Icon(Icons.open_in_new, size: 30, color: const Color(0xFF6A1B9A),),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // if (ticket.status == "1") ...[
                                //   const SizedBox(height: 8),
                                //
                                // ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        }),
      ),

      // // Bottom navigation bar remains THE SAME
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
      //                   if (i == 0)
      //                     Get.to(() => const HomeScreen(),
      //                         transition: Transition.fadeIn);
      //                   if (i == 1)
      //                     Get.to(() => const MyBookingScreen(),
      //                         transition: Transition.fadeIn);
      //                   if (i == 2) _showPostBottomSheet(context);
      //                   if (i == 3)
      //                     Get.to(() => const AlertsScreen(),
      //                         transition: Transition.fadeIn);
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
