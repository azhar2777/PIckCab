import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../const/const.dart';
import '../home/home_screen.dart';
import 'login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  final controller = Get.put(LoginController());
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    final appname = prefs.getString("app_name");

    if (appname == "pickcab" &&
        userId != null &&
        userId.isNotEmpty &&
        userId != "null") {
      // Get.offAll(() => const HomeScreen(), transition: Transition.fade);
    }
  }

  @override
  void initState() {
    super.initState();
    checkLoginStatus();

    controller.otpController = TextEditingController();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();

    _videoController = VideoPlayerController.asset('assets/video/login.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.setVolume(0.0);
        _videoController.play();
      }).catchError((error) {
        debugPrint('Video initialization error: $error');
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Video
          SizedBox.expand(
            child: _videoController.value.isInitialized
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
          ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Logo with animation
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.network(
                            '$imageurlstatic/pp_logo.png',
                            width: 90,
                            height: 90,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.local_taxi,
                              size: 70,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Slogan with animation
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            "One APP | Many Cities\nUnlimited Rides",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                              height: 1.3,
                              shadows: const [
                                Shadow(
                                  blurRadius: 10,
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Glassmorphic Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Obx(() {
                          final isOtpMode = controller.showOTP.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isOtpMode
                                              ? 'Enter OTP'
                                              : 'Welcome Back!',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: const [
                                              Shadow(
                                                blurRadius: 12,
                                                color: Colors.black38,
                                                offset: Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isOtpMode
                                              ? 'Code sent to +91 ${controller.phoneController.text}'
                                              : 'Enter your mobile number to continue',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white70,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isOtpMode)
                                    TextButton(
                                      onPressed: controller.goBackToMobile,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: Text(
                                        'Change',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // Phone Field
                              if (!isOtpMode) ...[
                                _buildPhoneField(),
                                const SizedBox(height: 28),
                              ],

                              // OTP Field
                              if (isOtpMode) ...[
                                Center(
                                  child: SizedBox(
                                    width: 280,
                                    child: Pinput(
                                      controller: controller.otpController,
                                      length: 6,
                                      keyboardType: TextInputType.number,
                                      autofocus: true,
                                      defaultPinTheme: PinTheme(
                                        width: 48,
                                        height: 56,
                                        textStyle: GoogleFonts.poppins(
                                          fontSize: 22,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white24,
                                            width: 1.2,
                                          ),
                                        ),
                                      ),
                                      focusedPinTheme: PinTheme(
                                        width: 48,
                                        height: 56,
                                        textStyle: GoogleFonts.poppins(
                                          fontSize: 22,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.18),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFBA68C8)
                                                  .withOpacity(0.3),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                      submittedPinTheme: PinTheme(
                                        width: 48,
                                        height: 56,
                                        textStyle: GoogleFonts.poppins(
                                          fontSize: 22,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.22),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: const Color(0xFFBA68C8)
                                                .withOpacity(0.5),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      onCompleted: (pin) {
                                        controller.verifyOTP();
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                              ],

                              // Action Button
                              _buildActionButton(isOtpMode),

                              if (isOtpMode) ...[
                                const SizedBox(height: 20),
                                Obx(
                                  () => Center(
                                    child: GestureDetector(
                                      onTap: controller.resendTimer.value == 0
                                          ? () => controller.sendOTP()
                                          : null,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          controller.resendTimer.value > 0
                                              ? 'Resend OTP in ${controller.resendTimer.value}s'
                                              : "Didn't receive OTP? Resend",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color:
                                                controller.resendTimer.value > 0
                                                    ? Colors.white60
                                                    : Colors.white,
                                            fontWeight: FontWeight.w500,
                                            decoration:
                                                controller.resendTimer.value ==
                                                        0
                                                    ? TextDecoration.underline
                                                    : TextDecoration.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 20),

                              Center(
                                child: Container(
                                  width: double.infinity,

                                  decoration: BoxDecoration(
                                      // color: Colors.red,
                                      border: Border.all(
                                        color: Color(0xFFBA68C8),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(8.0))),
                                  child: TextButton(
                                    onPressed: controller.navigateToRegister,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 16,
                                      ),
                                    ),
                                    child: Text(
                                      "New partner? Sign Up",
                                      style: GoogleFonts.poppins(
                                        color: Color(0xFFBA68C8),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 18,
                                        // decoration: TextDecoration.underline,
                                        decorationColor: Colors.white70,
                                        decorationThickness: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Register Link
                              // Center(
                              //   child: TextButton(
                              //     onPressed: controller.navigateToRegister,
                              //     style: TextButton.styleFrom(
                              //       padding: const EdgeInsets.symmetric(
                              //         horizontal: 20,
                              //         vertical: 12,
                              //       ),
                              //     ),
                              //     child: Text(
                              //       "New partner? Sign Up",
                              //       style: GoogleFonts.poppins(
                              //         color: Colors.white,
                              //         fontWeight: FontWeight.w500,
                              //         fontSize: 15,
                              //         decoration: TextDecoration.underline,
                              //         decorationColor: Colors.white70,
                              //         decorationThickness: 1.5,
                              //       ),
                              //     ),
                              //   ),
                              // ),
                            ],
                          );
                        }),
                      ),

                      const SizedBox(height: 30),

                      // Version Text
                      Text(
                        'Version 1.0.0',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white38,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Obx(
      () => TextField(
        controller: controller.phoneController,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Mobile Number',
          labelStyle: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixText: '+91 ',
          prefixStyle: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          counterText: '',
          errorText: controller.phoneError.value.isEmpty
              ? null
              : controller.phoneError.value,
          errorStyle: GoogleFonts.poppins(
            color: Colors.orangeAccent,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.15),
              width: 1.2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFFBA68C8),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.orangeAccent,
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Colors.orangeAccent,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isOtpMode) {
    return Obx(
      () => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8E24AA), Color(0xFFBA68C8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8E24AA).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isOtpMode
              ? (controller.isVerifying.value ? null : controller.verifyOTP)
              : (controller.isLoading.value ? null : controller.sendOTP),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withOpacity(0.6),
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
            minimumSize: const Size(double.infinity, 58),
          ),
          child: controller.isLoading.value || controller.isVerifying.value
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  isOtpMode ? 'Verify & Continue' : 'Login With OTP',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
