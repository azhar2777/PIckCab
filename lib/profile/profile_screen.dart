// lib/profile/profile_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/Get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../includes/header.dart';
import '../support/support_screen.dart';
import 'addhardetail.dart';
import 'profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

final controller = Get.put(ProfileController(), permanent: true);

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    controller.fetchUserProfile();
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 32),
            ),
            const SizedBox(height: 20),
            Text(
              'Logout',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to logout?\nYou will need to login again.',
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
                      ProfileController.to.navigateToLogout();
                    },
                    child: Text(
                      'Logout',
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
                  ProfileController.to.onNewBooking();
                },
              ),
              const SizedBox(height: 12),
              _buildPostOption(
                icon: Icons.directions_car,
                title: 'Free Vehicle',
                onTap: () {
                  Get.back();
                  ProfileController.to.onFreeVehicle();
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

  // Enhanced Verification Card (Pending / In Process / Verified)
  Widget _buildVerificationCard({
    required IconData icon,
    required String title,
    required String status,
    required VoidCallback? onPressed,
  }) {
    final bool isVerified = status == '1';
    final bool isInProcess = status == '2';
    final bool canApply = status == '0';

    late final Color bgColor;
    late final Color borderColor;
    late final Color textColor;
    late final Color badgeBgColor;
    late final Color badgeTextColor;
    late final String badgeText;

    if (isVerified) {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
      textColor = Colors.green.shade800;
      badgeBgColor = Colors.green.shade200;
      badgeTextColor = Colors.green.shade900;
      badgeText = "Verified";
    } else if (isInProcess) {
      bgColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade500;
      textColor = Colors.amber.shade900;
      badgeBgColor = Colors.amber.shade200;
      badgeTextColor = Colors.amber.shade900;
      badgeText = "In Process";
    } else {
      bgColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade300;
      textColor = Colors.orange.shade800;
      badgeBgColor = Colors.orange.shade200;
      badgeTextColor = Colors.orange.shade900;
      badgeText = "Pending";
    }

    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1.8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Icon(icon, color: textColor, size: 34),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: isInProcess
            ? Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "We'll notify you once approved",
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: badgeBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            if (canApply) ...[
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey.shade600,
              ),
            ],
          ],
        ),
        onTap: canApply ? onPressed : null,
        enabled: canApply,
      ),
    );
  }

  String formatVerifiedDate(String? date) {
    if (date == null || date.isEmpty) return '';

    final parsed = DateTime.tryParse(date);
    if (parsed == null) return '';

    return "${parsed.day.toString().padLeft(2, '0')} "
        "${_monthName(parsed.month)} "
        "${parsed.year}, "
        "${parsed.hour.toString().padLeft(2, '0')}:"
        "${parsed.minute.toString().padLeft(2, '0')}";
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  void _showAadhaarVerificationDialog() async {
    final controller = ProfileController.to;

    if (controller.isOtpSending.value || controller.isOtpVerifying.value) {
      return;
    }

    final alreadyVerified = await controller.checkAadhaarStatus();

    if (alreadyVerified) {
      Get.snackbar("Already Verified", "Your Aadhaar is already verified.",
          backgroundColor: Colors.green.shade600, colorText: Colors.white);
      controller.fetchUserProfile(showLoading: false);
      return;
    }

    final isOtpSent = false.obs;
    final resendSeconds = 30.obs;
    Timer? resendTimer;

    void startResendTimer() {
      resendSeconds.value = 30;
      resendTimer?.cancel();
      resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (resendSeconds.value <= 0) {
          timer.cancel();
        } else {
          resendSeconds.value--;
        }
      });
    }

    void disposeTimer() {
      resendTimer?.cancel();
      resendTimer = null;
    }

    Get.dialog(
      Obx(() {
        final bool isLoading = isOtpSent.value
            ? controller.isOtpVerifying.value
            : controller.isOtpSending.value;

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            isOtpSent.value ? "Enter OTP" : "Verify Aadhaar",
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isOtpSent.value) ...[
                Text(
                  "Enter your 12-digit Aadhaar number",
                  style: GoogleFonts.poppins(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: controller.aadhaarController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                    AadhaarInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    hintText: "XXXX XXXX XXXX",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.credit_card),
                  ),
                ),
              ] else ...[
                Text(
                  "OTP sent to your Aadhaar registered mobile",
                  style: GoogleFonts.poppins(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: controller.otpController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: InputDecoration(
                    hintText: "Enter 6-digit OTP",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.sms),
                  ),
                ),
                const SizedBox(height: 16),
                Obx(() {
                  if (resendSeconds.value > 0) {
                    return Text(
                      "Resend OTP in ${resendSeconds.value} seconds",
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: Colors.grey.shade600),
                    );
                  } else {
                    return TextButton(
                      onPressed: () async {
                        final aadhaar = controller.aadhaarController.text
                            .replaceAll(' ', '')
                            .trim();
                        final success = await controller.requestAadhaarOtp(
                            aadhaarNumber: aadhaar);
                        if (success) {
                          startResendTimer();
                        }
                      },
                      child: Text(
                        "Resend OTP",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6A1B9A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                }),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                disposeTimer();
                controller.clearAadhaarFields();
                Get.back();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A1B9A),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!isOtpSent.value) {
                        // Send OTP
                        final aadhaar = controller.aadhaarController.text
                            .replaceAll(' ', '')
                            .trim();
                        if (aadhaar.length != 12) {
                          Get.snackbar("Invalid",
                              "Please enter valid 12-digit Aadhaar number");
                          return;
                        }

                        controller.isOtpSending.value = true;

                        try {
                          final alreadyVerified =
                              await controller.checkAadhaarStatus();
                          if (alreadyVerified) {
                            disposeTimer();
                            Get.back();
                            controller.fetchUserProfile(showLoading: false);
                            return;
                          }

                          final success = await controller.requestAadhaarOtp(
                              aadhaarNumber: aadhaar);
                          if (success) {
                            isOtpSent.value = true;
                            startResendTimer();
                          }
                        } finally {
                          controller.isOtpSending.value = false;
                        }
                      } else {
                        // Verify OTP
                        final otp = controller.otpController.text.trim();
                        if (otp.length != 6) {
                          Get.snackbar(
                              "Invalid OTP", "Please enter 6-digit OTP");
                          return;
                        }

                        final success = await controller.verifyAadhaarWithOtp(
                            aadhaarOtp: otp);
                        if (success) {
                          disposeTimer();
                          controller.clearAadhaarFields();
                          // Navigation is already handled inside verifyAadhaarWithOtp
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      isOtpSent.value ? "Verify OTP" : "Send OTP",
                      style: const TextStyle(color: Colors.white),
                    ),
            ),
          ],
        );
      }),
      barrierDismissible: false,
    ).then((_) {
      disposeTimer();
      controller.clearAadhaarFields();
    });
  }

  Widget _buildImagePickerTile({
    required String title,
    String? subtitle,
    required String path,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                path.isEmpty ? Colors.grey.shade400 : const Color(0xFF6A1B9A),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: path.isNotEmpty
              ? const Color(0xFF6A1B9A).withOpacity(0.05)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              path.isEmpty ? Icons.camera_alt : Icons.check_circle,
              color: const Color(0xFF6A1B9A),
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (path.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(path),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey.shade500,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF6A1B9A), size: 26),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 18,
        color: Colors.grey,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) {
      Get.snackbar("Error", "URL not configured");
      return;
    }

    final Uri uri = Uri.parse(url);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.inAppWebView, // ← this opens inside the app
      webOnlyWindowName: '_self', // optional: helps on web platform
    )) {
      Get.snackbar("Error", "Could not launch $url");
    }
  }

  void _shareApp() {
    // Customize your share text and app link
    const String shareText =
        "PP (PICKCAB PARTNER) app download link https://play.google.com/store/apps/details?id=com.taxi_app";
    Share.share(shareText);
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6A1B9A), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAadhaarVerifiedDetails() {
    final controller = ProfileController.to;
    final details = controller.aadhaarDetails.value;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                // Text(
                //   "Verified on ${formatVerifiedDate(user['aadhar_verified_on'])}",
                //   style: GoogleFonts.poppins(
                //     fontSize: 13,
                //     color: Colors.green.shade800,
                //     fontWeight: FontWeight.w600,
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 16),
            if (details != null) ...[
              _buildDetailRow(Icons.person, "Name", details.name ?? "—"),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.calendar_today, "DOB", details.dob ?? "—"),
              const SizedBox(height: 12),
              _buildDetailRow(
                  Icons.transgender, "Gender", details.gender ?? "—"),
              const SizedBox(height: 16),
              if (details.photoBase64 != null &&
                  details.photoBase64!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(details.photoBase64!),
                    height: 140,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                ),
            ] else ...[
              Text(
                "Basic details loaded from Aadhaar",
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget aadhaarPhotoWidget(String base64Image) {
    try {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          base64Decode(base64Image),
          height: 140,
          width: 120,
          fit: BoxFit.cover,
        ),
      );
    } catch (e) {
      return const Text("Unable to load Aadhaar photo");
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileController(), permanent: true);

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
                // Profile Avatar
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundImage: NetworkImage(user['avatarUrl'] ?? ''),
                        onBackgroundImageError: (_, __) {},
                      ),
                      if (user['verified'] == true)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user['name'] ?? 'User',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: InkWell(
                    onTap: controller.navigateToEditProfile,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Edit Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6A1B9A),

                          ),
                        ),
                        SizedBox(width: 6,),
                        Image.asset("assets/images/editing.png",
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,)
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${user['rating'] ?? '0.0'}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Unique ID Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A1B9A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF6A1B9A),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag, color: Color(0xFF6A1B9A), size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your PP ID",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              user['user_unq_id']?.toString() ?? 'N/A',
                              style: GoogleFonts.montserrat(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF6A1B9A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final id = user['user_unq_id']?.toString() ?? '';
                          if (id.isNotEmpty && id != 'N/A') {
                            Clipboard.setData(ClipboardData(text: id));
                            Get.snackbar(
                              "Copied!",
                              "ID: $id",
                              backgroundColor: Colors.green.shade600,
                              colorText: Colors.white,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6A1B9A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.copy,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _launchUrl(
                      "https://pickcab-partner.pickcab.in/video-tutorial/"),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF6A1B9A),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.school,
                            color: Color(0xFF6A1B9A),
                            size: 32), // Tutorial icon
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "APP Tutorial",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "ऐप चलना सीखें !",
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF6A1B9A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // अगर future में कोई action चाहिए तो यहां add कर सकते हैं
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Aadhaar Verification
                Obx(() {
                  final aadharStatus =
                      user['aadhar_verified']?.toString() ?? '0';

                  return Column(
                    children: [
                      _buildVerificationCard(
                        icon: Icons.credit_card,
                        title: "Aadhaar Verification",
                        status: aadharStatus,
                        onPressed: aadharStatus == '0'
                            ? _showAadhaarVerificationDialog
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // ── Show verified details only when actually verified ──
                      if (aadharStatus == '1' &&
                          user['aadhar_verified_on'] != null) ...[
                        _buildAadhaarVerifiedDetails(),
                      ],
                    ],
                  );
                }),

                // DL Verification
                // _buildVerificationCard(
                //   icon: Icons.badge,
                //   title: "Driving License Verification",
                //   status: dlStatus,
                //   onPressed: dlStatus == '0' ? _showDLVerificationDialog : null,
                // ),
                const SizedBox(height: 32),

                // Contact Details
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          Icons.phone,
                          'Phone',
                          user['phone'] ?? 'N/A',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          Icons.email,
                          'Email',
                          user['email'] ?? 'N/A',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

// === NEW: More Menu Section ===
                // Text(
                //   "More",
                //   style: GoogleFonts.montserrat(
                //     fontSize: 18,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.grey.shade800,
                //   ),
                // ),
                // const SizedBox(height: 12),

                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // _buildMenuTile(
                      //   icon: Icons.info_outline,
                      //   title: "About Us",
                      //   onTap: () =>
                      //       _launchUrl("https://yourwebsite.com/about-us"),
                      // ),
                      const Divider(height: 1, indent: 56),
                      _buildMenuTile(
                        icon: Icons.handshake_outlined,
                        title: "PickCab Partner (PP)",
                        onTap: () =>
                            _launchUrl("https://pickcab-partner.pickcab.in/"),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildMenuTile(
                        icon: Icons.play_circle_outline,
                        title: "App Tutorial",
                        onTap: () => _launchUrl(
                            "https://pickcab-partner.pickcab.in/video-tutorial/"),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildMenuTile(
                        icon: Icons.share,
                        title: "Share App",
                        onTap: _shareApp,
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildMenuTile(
                        icon: Icons.privacy_tip_outlined,
                        title: "Privacy Policy",
                        onTap: () => _launchUrl(
                            "https://pickcab-partner.pickcab.in/privacy-policy/"),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildMenuTile(
                        icon: Icons.description_outlined,
                        title: "Terms & Conditions",
                        onTap: () => _launchUrl(
                            "https://pickcab-partner.pickcab.in/terms-conditions/"),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildMenuTile(
                        icon: Icons.support_agent,
                        title: "Support",
                        onTap: () => Get.to(SupportScreen()),
                      ),
                      const Divider(height: 1, indent: 56),
                      _buildMenuTile(
                        icon: Icons.description_outlined,
                        title: "YOUR DIGITAL SOLUTION ",
                        onTap: () => _launchUrl("https://canaryinn.in/"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    icon: const Icon(Icons.logout, size: 20),
                    label: Text(
                      'Logout',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                    ),
                  ),
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
