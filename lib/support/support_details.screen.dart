import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pickcab_partner/profile/profile_screen.dart';
import 'package:pickcab_partner/support/support_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../includes/header.dart';
import '../alerts/alerts_screen.dart';
import '../const/const.dart';
import '../freebooking/freebooking_new.dart';
import '../home/home_screen.dart';
import '../my_bookings/my_booking_screen.dart';
import '../new_booking/new_booking_screen.dart';


// Model
class SupportMessages {
  late final String id;
  final String message;
  final String messageType;
  final String senderId; // "0" = pending, etc.
  final String createdAt; // API doesn't send date → optional

  SupportMessages({
    required this.id,
    required this.message,
    required this.messageType,
    required this.senderId,
    required this.createdAt,
  });

  factory SupportMessages.fromJson(Map<String, dynamic> json) {
    return SupportMessages(
      id: json['id']?.toString() ?? '',
      message: json['message'] ?? '',
      messageType: json['message_type'] ?? 'Request',
      senderId: json['sender_id']?.toString() ?? '-1',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

// Controller
class SupportDetailController extends GetxController {

  static SupportDetailController get to => Get.find();

  final RxList<SupportMessages> messages = <SupportMessages>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;


  final selectedType = RxString('');
  final commentController = TextEditingController();


  // final String baseUrl = 'https://guplfx.com/pickcab/api/support';
  // ← change to https if needed + remove double slash if present in real URL

  // Replace with real user ID (from auth controller, shared prefs, etc.)
  // final String userId = '12'; // ← TEMPORARY – MUST COME FROM AUTH LAYER

  @override
  void onInit() {
    super.onInit();


  }

  Future<void> fetchMessages(String supportId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");


    try {
      isLoading(true);
      errorMessage('');

      final uri = Uri.parse('$appurl/support/getMessages?support_id=$supportId');
      final request = http.Request('GET', uri);

      final response = await request.send();

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final jsonData = jsonDecode(body);

        if (jsonData['status'] == true) {
          print(jsonData);
          final List<dynamic> data = jsonData['data'] ?? [];
          messages.assignAll(
            data.map((item) => SupportMessages.fromJson(item)).toList(),
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

  Future<void> sendMessage(String supportId) async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString("user_id");

    if (commentController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please write a message',
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
        Uri.parse('$appurl/support/sendSupportMessage'),
      );

      request.fields.addAll({
        'message': commentController.text.trim(),
        'user_id': userId.toString(),
        'support_id': supportId,
      });

      final response = await request.send();

      Get.back(); // close loading

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);

        if (json['status'] == true) {
          Get.snackbar('Success', json['message'],
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green.shade900);

          commentController.clear();
          // Refresh list
          SupportDetailController controller = Get.find<SupportDetailController>();
          controller.fetchMessages(supportId);

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

  Future<void> markAsResolved(String supportId) async {
    final prefs = await SharedPreferences.getInstance();
    var userId = prefs.getString("user_id");

    // if (commentController.text.trim().isEmpty) {
    //   Get.snackbar('Error', 'Please write a message',
    //       backgroundColor: Colors.red.shade100, colorText: Colors.red.shade900);
    //   return;
    // }

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$appurl/support/markResoved'),
      );

      request.fields.addAll({
        'user_id': userId.toString(),
        'support_id': supportId,
      });

      final response = await request.send();

      Get.back(); // close loading

      if (response.statusCode == 200) {
        final body = await response.stream.bytesToString();
        final json = jsonDecode(body);
        print(json);

        if (json['status'] == true) {
          print(json);
          Get.back();
          Get.snackbar('Success', json['message'],
              backgroundColor: Colors.green.shade100,
              colorText: Colors.green.shade900);

    //       Future.delayed(const Duration(milliseconds: 2000), () {
    //         Get.closeCurrentSnackbar();
    //
    //
    // });

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
  void navigateToHome() => Get.offAllNamed('/home');
  // ... rest same
}

class SupportDetailsScreen extends StatefulWidget {
  final SupportTicket supportTicket;
  const SupportDetailsScreen({super.key, required this.supportTicket});

  @override
  State<SupportDetailsScreen> createState() => _SupportDetailsScreenState();
}

class _SupportDetailsScreenState extends State<SupportDetailsScreen> {
  late final SupportDetailController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<SupportDetailController>()) {
      Get.put(SupportDetailController(), permanent: true);
    }
    controller = Get.find<SupportDetailController>();

    controller.fetchMessages(widget.supportTicket.id);

  }

  // _showPostBottomSheet, _buildPostOption, _option methods remain THE SAME

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Recently';
    DateTime date = DateTime.parse(dateStr!);

    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours} h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} min ago';
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
      appBar: AppBar(
        title: Text(
          "Support Messages",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // appBar: const AppHeader(),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async =>{
          controller.fetchMessages(widget.supportTicket.id)
        },
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
                    onPressed: ()=>{
                      controller.fetchMessages(widget.supportTicket.id)
                    },
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Support messages",
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6A1B9A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Send messages to get status of your ticket.",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),

              const Divider(height: 30),

              Expanded(
                child: controller.messages.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.support_agent,
                          size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text("No support tickets yet",
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Container(

                        width: double.infinity,
                        // color: Colors.red,
                        child: Card(
                          margin: EdgeInsets.only(bottom: 12, right: controller.messages[index].senderId == "-1" ? 90: 0, left: controller.messages[index].senderId == "-1" ? 0: 90),
                          color: controller.messages[index].senderId == "-1" ?
                          Color(0xFFE5E5EA): Color(0XFF007AFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          child: Container(
                            // padding: EdgeInsets.all(8),
                            constraints: const BoxConstraints(
                              // minHeight: 70,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                      "${controller.messages[index].message}",
                                    style: TextStyle(
                                        fontSize: 15,
                                      color: controller.messages[index].senderId == "-1" ? Color(0xFF333333) : Colors.white,

                                    ),
                                  ),
                                ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6, right: 12,),
                                  child: Text(
                                      _formatDate(controller.messages[index].createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: controller.messages[index].senderId == "-1" ? Color(0xFF333333) : Colors.white,

                                    ),
                                  ),
                                ),
                              ],
                            ),
                              ],
                            ),

                          ),),
                      ),
                    );
                  },
                ),
              ),

              widget.supportTicket.status == "1" ?
              Padding(
                padding: const EdgeInsets.all(16),
                child: // Submit form (same as before)
                SizedBox(
                  width: context.mediaQuery.size.width,
                  child: Container(

                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                                child: Text("Resolved",
                                  style: TextStyle(
                                    fontSize: 20,
                                    color:  Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                ),
                ),
              )
              :
              Padding(
                padding: const EdgeInsets.all(16),
                child: // Submit form (same as before)
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


                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.commentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: "Write messages",
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
                          onPressed: ()=>{
                            controller.sendMessage(widget.supportTicket.id)
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A1B9A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Send",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: ()=>{
                            // controller.markAsResolved(widget.supportTicket.id)
                            _showLogoutDialog(context, widget.supportTicket.id)
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A1B9A),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Mark As resolved",
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
              ),
            ],
          );
        }),
      ),

      // Bottom navigation bar remains THE SAME
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
  void _showLogoutDialog(BuildContext context, String supportId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              'Resolve',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to close this ticket?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Get.back();
                      controller.markAsResolved(supportId);
                    },
                    child: Text(
                      'Resolve',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
