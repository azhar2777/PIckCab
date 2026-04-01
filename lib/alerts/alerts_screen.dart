import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;

import '../../includes/header.dart';
import 'check.dart';
import 'alerts_controller.dart'; // ← adjust path if needed

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late final AlertsController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<AlertsController>()) {
      Get.put(AlertsController(), permanent: true);
    }
    controller = Get.find<AlertsController>();
    controller.fetchCities();
  }

  // ───────────────────────────────────────────────
  //   Helper: extract clean city name from description
  // ───────────────────────────────────────────────
  String _extractCleanCity(Prediction prediction) {
    final desc = prediction.description ?? '';
    if (desc.isEmpty) return '';

    final parts = desc.split(', ');
    if (parts.isEmpty) return desc.trim();

    // Most common patterns in India:
    // "Ranchi, Jharkhand, India"          → Ranchi
    // "Kanke, Ranchi, Jharkhand, India"   → Ranchi (prefer second part)
    // "Bangalore Rural, Karnataka, India" → Bangalore Rural

    String city = parts[0].trim();

    if (parts.length >= 3) {
      final last = parts.last.toLowerCase().trim();
      if (last == 'india' || last.contains('india')) {
        if (parts.length >= 4 && parts[1].trim().length > 3) {
          // likely "Area, City, State, India" → take City
          city = parts[1].trim();
        } else {
          city = parts[0].trim();
        }
      }
    }

    // Clean up common suffixes
    city = city
        .replaceAll(
            RegExp(r'\s+(City|District|Municipal|Corp|Corp\.)$',
                caseSensitive: false),
            '')
        .trim();

    return city.isNotEmpty ? city : desc.trim();
  }

  void _showAddCityBottomSheet(BuildContext context) {
    final tempController = TextEditingController();
    const apiKey = "AIzaSyAVaPMPGqeahxVzZbpEJGbGkiW0RNMzIEM"; // ← CHANGE THIS

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              "Add Alert City",
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
                textEditingController: tempController,
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                debounceTime: 500,
                countries: const ["in"],
                isLatLngRequired: false,

                // ────────────────────────────────────────────────────────
                // MAIN FIX: handle selection here (most reliable trigger)
                // ────────────────────────────────────────────────────────
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

                  // Limit check
                  if (controller.cities.length >= 15) {
                    Get.snackbar(
                      "Limit Reached",
                      "You can add maximum 15 alert cities",
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    Navigator.pop(ctx);
                    return;
                  }

                  // Duplicate check (case-insensitive)
                  final alreadyAdded = controller.cities.any(
                    (c) => c.city.toLowerCase() == city.toLowerCase(),
                  );

                  if (alreadyAdded) {
                    Get.snackbar(
                        "Already Added", "$city is already in your list");
                    Navigator.pop(ctx);
                    return;
                  }

                  // ── This is the line that was missing / not reached ──
                  controller.addCity(city);

                  // Get.snackbar(
                  //   "Success",
                  //   "$city added to alerts",
                  //   backgroundColor: Colors.green[700],
                  //   colorText: Colors.white,
                  //   duration: const Duration(seconds: 2),
                  // );

                  Navigator.pop(ctx);
                },

                // Optional: keep for future use (lat/lng, state, etc.)
                getPlaceDetailWithLatLng: (Prediction prediction) async {
                  // You can leave this empty or log for debugging
                  // print("Details fetched: ${prediction.description}");
                },

                seperatedBuilder: const Divider(),
                isCrossBtnShown: true,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Select a city to get load/post notifications from that location",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostBottomSheet() {
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
              _option(Icons.add_road, 'New Booking', () {
                Get.back();
                AlertsController.to.onNewBooking();
              }),
              const SizedBox(height: 12),
              _option(Icons.directions_car, 'Free Vehicle', () {
                Get.back();
                AlertsController.to.onFreeVehicle();
              }),
            ],
          ),
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
      appBar: const AppHeader(),
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: controller.fetchCities,
        color: const Color(0xFF6A1B9A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Get.to(() => const CheckScreen()),
                child: Text(
                  "Set Alert Cities",
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6A1B9A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Get notified when loads are posted from these cities (Max 15)",
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () => _showAddCityBottomSheet(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.add_circle_outline, color: Color(0xFF6A1B9A)),
                      SizedBox(width: 16),
                      Text(
                        "Add New City",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Spacer(),
                      Icon(Icons.arrow_forward_ios,
                          size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Obx(() {
                return Text(
                  "Your Alert Cities (${controller.cities.length}/15)",
                  style: GoogleFonts.montserrat(
                      fontSize: 17, fontWeight: FontWeight.w600),
                );
              }),
              const Divider(height: 30),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Obx(() {
                  if (controller.isLoading.value && controller.cities.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (controller.cities.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off,
                              size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text("No cities added yet",
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: controller.cities.map((c) {
                        return InputChip(
                          avatar: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 16, color: Colors.white),
                          label: Text(
                            c.city,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: const Color(0xFF6A1B9A),
                          shape: const StadiumBorder(
                              side: BorderSide(color: Colors.white24)),
                          onPressed: () =>
                              controller.openHomeAndSearchCity(c.city),
                          deleteIcon: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                                color: Color(0xFF6A1B9A),
                                shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                size: 18, color: Colors.white),
                          ),
                          onDeleted: () {
                            showDialog(
                              context: context,
                              builder: (dialogCtx) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: const Text("Remove Alert City?"),
                                content: Text(
                                    "Stop receiving alerts for loads from ${c.city}?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogCtx),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(dialogCtx);
                                      controller.deleteCity(c.city);
                                    },
                                    child: const Text("Remove",
                                        style: TextStyle(
                                            color: Color(0xFF6A1B9A))),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),


    );
  }
}
