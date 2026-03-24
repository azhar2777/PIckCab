import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
// import 'package:otp_autofill/otp_autofill.dart';
import 'package:pinput/pinput.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../const/const.dart';
import 'register_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late VideoPlayerController _videoController;
  final c = Get.put(RegisterController());

  @override
  void initState() {
    super.initState();
    // c.getAppSignature();

    _videoController = VideoPlayerController.asset('assets/video/login.mp4')
      ..initialize().then((_) {
        setState(() {});
        _videoController.setLooping(true);
        _videoController.setVolume(0.0);
        _videoController.play();
      }).catchError((e) {
        debugPrint('Video init error: $e');
      });

    // c.otpController = OTPTextEditController(
    //   codeLength: 6,
    //   onCodeReceive: (code) {
    //     if (code != null && code.length == 6) {
    //       setState(() {
    //         c.otpController.text = code;
    //       });
    //       Future.delayed(const Duration(milliseconds: 400), () {
    //         // _verifyOtp();
    //       });
    //     }
    //   },
    // );

    // c.startListeningForOtp();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _getPlaceDetails(
      String placeId, String apiKey) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=address_components,formatted_address,geometry'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          return json['result'];
        }
      }
    } catch (e) {
      debugPrint('Place details error: $e');
    }
    return null;
  }

  String _extractCleanCity(String description) {
    final parts = description.split(', ');
    if (parts.length < 3) return description.trim();

    String city = parts[0].trim();
    if (parts.length >= 4 && parts[1].trim().length > 3) {
      city = parts[1].trim();
    }

    return city
        .replaceAll(
            RegExp(r'\s+(City|Municipal|Corp|District)$', caseSensitive: false),
            '')
        .trim();
  }

  void _showCityBottomSheet(BuildContext context, RegisterController c) {
    final tempController = TextEditingController();
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
                  "Select Your City",
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
                    textEditingController: tempController,
                    googleAPIKey: apiKey,
                    inputDecoration: InputDecoration(
                      hintText:
                          "Search city, e.g. Ranchi, Jamshedpur, Patna...",
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
                    itemClick: (Prediction? prediction) {
                      if (prediction == null ||
                          prediction.description == null ||
                          prediction.description!.isEmpty) {
                        return;
                      }

                      final description = prediction.description!;
                      String fullAddress = description.trim();
                      String cleanCity = _extractCleanCity(description);

                      if (prediction.placeId != null) {
                        _getPlaceDetails(prediction.placeId!, apiKey)
                            .then((details) {
                          if (details != null && mounted) {
                            fullAddress =
                                details['formatted_address'] ?? fullAddress;

                            final components = details['address_components']
                                    as List<dynamic>? ??
                                [];
                            for (final comp in components) {
                              final types = (comp['types'] as List<dynamic>?)
                                      ?.cast<String>() ??
                                  [];
                              final name = comp['long_name'] as String? ?? '';
                              if (types.contains('locality')) {
                                cleanCity = name;
                                break;
                              }
                            }

                            if (mounted) {
                              c.cityController.text = fullAddress;
                              c.selectedCity.value = cleanCity;
                              c.cityError.value = "";
                            }
                          }
                        });
                      } else {
                        c.cityController.text = fullAddress;
                        c.selectedCity.value = cleanCity;
                        c.cityError.value = "";
                      }

                      Navigator.pop(ctx);
                    },
                    getPlaceDetailWithLatLng: (Prediction p) {},
                    seperatedBuilder: const Divider(),
                    isCrossBtnShown: true,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Selected city will be used for service availability",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        });
  }

  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) {
      Get.snackbar("Error", "URL not configured");
      return;
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.inAppWebView)) {
      Get.snackbar("Error", "Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(RegisterController());

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
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
                : const ColoredBox(color: Colors.black26),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.85),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Obx(
                  () => c.showOtpScreen.value
                      ? _buildOtpScreen(context, c)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 36),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 30),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white24, width: 1.5),
                                ),
                                child: Image.network(
                                  "$imageurlstatic/pp_logo.png",
                                  width: 100,
                                  height: 100,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.local_taxi,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 1400),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Transform.translate(
                                    offset: Offset(0, 20 * (1 - value)),
                                    child: Opacity(
                                      opacity: value,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.15),
                                              width: 1.2),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.15),
                                                blurRadius: 20,
                                                spreadRadius: 2),
                                          ],
                                        ),
                                        child: Text(
                                          "One APP | Many Cities \n Unlimited Rides",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.6,
                                            height: 1.3,
                                            shadows: const [
                                              Shadow(
                                                  blurRadius: 8,
                                                  color: Colors.black54,
                                                  offset: Offset(0, 2)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 40),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.11),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.18)),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10)),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Create Account",
                                      style: GoogleFonts.exo2(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(
                                              blurRadius: 10,
                                              color: Colors.black45,
                                              offset: Offset(2, 2)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                    _inputField_username(
                                      c.nameController,
                                      "Full Name",
                                      error: c.nameError.value,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                            RegExp(r'[a-zA-Z ]')),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    _inputField(
                                      c.phoneController,
                                      "Mobile Number",
                                      keyboard: TextInputType.phone,
                                      prefix: "+91 ",
                                      error: c.phoneError.value,
                                    ),
                                    // const SizedBox(height: 18),
                                    // _inputField(
                                    //   c.emailController,
                                    //   "Email Id",
                                    //   keyboard: TextInputType.emailAddress,
                                    //   error: c.emailError.value,
                                    // ),
                                    const SizedBox(height: 18),
                                    Text(
                                      "City",
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white70),
                                    ),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () =>
                                          _showCityBottomSheet(context, c),
                                      borderRadius: BorderRadius.circular(16),
                                      child: TextField(
                                        controller: c.cityController,
                                        enabled: false,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor:
                                              Colors.white.withOpacity(0.12),
                                          prefixIcon: const Icon(
                                              Icons.location_city_outlined,
                                              color: Colors.white70),
                                          hintText:
                                              "Tap to search & select city",
                                          hintStyle: const TextStyle(
                                              color: Colors.white60),
                                          errorText: c.cityError.value.isEmpty
                                              ? null
                                              : c.cityError.value,
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              borderSide: BorderSide.none),
                                          suffixIcon: const Icon(
                                              Icons.arrow_drop_down,
                                              color: Colors.white70),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    AnimatedOpacity(
                                      opacity: c.cityController.text.isNotEmpty
                                          ? 1.0
                                          : 0.0,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: Text(
                                          c.cityController.text,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color:
                                                Colors.white.withOpacity(0.75),
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Center(
                                      child: GestureDetector(
                                        onTap: c.captureImage,
                                        child: Container(
                                          height: 140,
                                          width: 140,
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.white24),
                                          ),
                                          child: c.capturedImage.value == null
                                              ? const Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.camera_alt,
                                                        size: 48,
                                                        color: Colors.white70),
                                                    SizedBox(height: 8),
                                                    Text("Add Photo",
                                                        style: TextStyle(
                                                            color: Colors
                                                                .white70)),
                                                  ],
                                                )
                                              : ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  child: Image.file(
                                                      c.capturedImage.value!,
                                                      fit: BoxFit.cover),
                                                ),
                                        ),
                                      ),
                                    ),
                                    if (c.imageError.value.isNotEmpty)
                                      Center(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            c.imageError.value,
                                            style: const TextStyle(
                                                color: Colors.orangeAccent),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 24),
                                    Obx(
                                      () => Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Checkbox(
                                                value: c.isTermsAccepted.value,
                                                onChanged: c.toggleTerms,
                                                fillColor: MaterialStateProperty
                                                    .resolveWith<Color>(
                                                        (states) {
                                                  if (states.contains(
                                                      MaterialState.selected)) {
                                                    return const Color(
                                                        0xFF8E24AA);
                                                  }
                                                  return const Color.fromARGB(
                                                      255, 62, 59, 63);
                                                }),
                                                checkColor:
                                                    const Color.fromARGB(
                                                        255, 201, 23, 23),
                                                side: const BorderSide(
                                                    color: Colors.white70,
                                                    width: 1.4),
                                              ),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () => _launchUrl(
                                                      "https://pickcab-partner.pickcab.in/terms-conditions/"),
                                                  child: RichText(
                                                    text: TextSpan(
                                                      children: [
                                                        TextSpan(
                                                          text:
                                                              "I agree to the ",
                                                          style: GoogleFonts
                                                              .poppins(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .white70),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              "Terms & Conditions",
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 14,
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            decoration:
                                                                TextDecoration
                                                                    .underline,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (c.termsError.value.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 12, top: 10),
                                              child: Text(
                                                c.termsError.value,
                                                style: const TextStyle(
                                                    color: Color(0xFF8E24AA),
                                                    fontSize: 13),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: c.isLoading.value
                                            ? null
                                            : c.register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF8E24AA),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                          elevation: 0,
                                        ),
                                        child: c.isLoading.value
                                            ? const CircularProgressIndicator(
                                                color: Colors.white)
                                            : Text(
                                                "Register & Send OTP",
                                                style: GoogleFonts.exo2(
                                                  fontSize: 17,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _launchUrl(
                                          "https://pickcab-partner.pickcab.in/privacy-policy/"),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: Colors.white.withOpacity(0.12),
                                          border: Border.all(
                                              color: Colors.white
                                                  .withOpacity(0.25)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                                Icons.privacy_tip_outlined,
                                                color: Colors.white,
                                                size: 20),
                                            const SizedBox(width: 8),
                                            RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: "Click here ",
                                                    style: GoogleFonts.exo2(
                                                        fontSize: 14,
                                                        color: Colors.white70),
                                                  ),
                                                  TextSpan(
                                                    text: "Privacy Policy",
                                                    style: GoogleFonts.exo2(
                                                      fontSize: 15,
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpScreen(BuildContext context, RegisterController c) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.11),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Icon(Icons.sms_rounded,
                  size: 90, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 30),
              Text(
                "Verify Phone Number",
                style: GoogleFonts.exo2(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                "Enter the 6-digit OTP sent to",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
              ),
              Text(
                "+91 ${c.phoneController.text}",
                style: GoogleFonts.exo2(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              const SizedBox(height: 40),

              // OTP Input with Pinput + Auto-fill
              Pinput(
                controller: c.otpController,
                length: 6,
                keyboardType: TextInputType.number,
                autofocus: true,
                androidSmsAutofillMethod:
                    AndroidSmsAutofillMethod.smsRetrieverApi,
                defaultPinTheme: PinTheme(
                  width: 50,
                  height: 56,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white30),
                  ),
                ),
                focusedPinTheme: PinTheme(
                  width: 50,
                  height: 56,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white),
                  ),
                ),
                submittedPinTheme: PinTheme(
                  width: 50,
                  height: 56,
                  textStyle: GoogleFonts.poppins(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onCompleted: (pin) {
                  // Auto verify when OTP is complete
                  if (!c.isVerifying.value) {
                    c.verifyOtp();
                  }
                },
              ),

              if (c.otpError.value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    c.otpError.value,
                    style: const TextStyle(
                        color: Colors.orangeAccent, fontSize: 14),
                  ),
                ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: c.isVerifying.value ? null : c.verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E24AA),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: c.isVerifying.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Verify & Continue",
                          style: GoogleFonts.exo2(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
    String? prefix,
    String? error,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixText: prefix,
        errorText: error?.isNotEmpty == true ? error : null,
        errorStyle: const TextStyle(color: Colors.orangeAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white70, width: 2),
        ),
      ),
    );
  }

  Widget _inputField_username(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
    String? prefix,
    String? error,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixText: prefix,
        errorText: error?.isNotEmpty == true ? error : null,
        errorStyle: const TextStyle(color: Colors.orangeAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white70, width: 2),
        ),
      ),
    );
  }
}
