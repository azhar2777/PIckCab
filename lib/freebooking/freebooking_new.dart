import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../includes/header.dart';
import 'freebooking_controller.dart'; // Adjust path if needed

class FreebookingNew extends StatefulWidget {
  const FreebookingNew({super.key});

  @override
  State<FreebookingNew> createState() => _FreebookingNewState();
}

class _FreebookingNewState extends State<FreebookingNew> {
  late FreeNewBookingController c;

  final DateFormat _dateFormat = DateFormat("MMM d, yyyy @ h:mm a");

  Future<void> _selectDateTime(bool isStart) async {
    DateTime currentValue = isStart ? c.startTime.value : c.endTime.value;
    DateTime now = DateTime.now();

    DateTime safeInitialDate = currentValue.isBefore(now) ? now : currentValue;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: safeInitialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2030),
    );

    if (pickedDate == null || !mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentValue),
    );

    if (pickedTime == null) return;

    final DateTime fullDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (fullDateTime.isBefore(now)) {
      Get.snackbar(
        'Invalid Date & Time',
        'Please select current or future date & time',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (isStart) {
      c.startTime.value = fullDateTime;
    } else {
      c.endTime.value = fullDateTime;
    }
  }

  String _extractCleanCity(Prediction prediction) {
    final description = prediction.description ?? '';
    if (description.isEmpty) return '';

    final parts = description.split(', ');
    if (parts.isEmpty) return description.trim();

    // Most reliable: take first part or second if looks like area
    String city = parts[0].trim();

    if (parts.length >= 3) {
      // Try to prefer main city over locality/area
      if (parts.length >= 4 && parts[1].trim().length > 3) {
        city = parts[1].trim();
      }
    }

    // Remove common unwanted suffixes
    city = city
        .replaceAll(
            RegExp(r'\s+(City|Municipal|Corp|Limited|LLP)$',
                caseSensitive: false),
            '')
        .trim();

    return city;
  }

  void _showCityBottomSheet(
    BuildContext context,
    FreeNewBookingController c,
    TextEditingController controller,
    String label,
  ) {
    final tempController = TextEditingController();
    final searchFocusNode = FocusNode();

    const apiKey =
        "AIzaSyAVaPMPGqeahxVzZbpEJGbGkiW0RNMzIEM"; // ← REPLACE WITH YOUR REAL KEY

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
                  "Select $label City",
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
                    focusNode: searchFocusNode,
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
                    itemClick: (Prediction? prediction) {
                      if (prediction == null ||
                          prediction.description == null ||
                          prediction.description!.isEmpty) {
                        return;
                      }

                      String cityName = _extractCleanCity(prediction);

                      if (cityName.isEmpty) {
                        cityName = prediction.description!.split(',')[0].trim();
                      }

                      controller.text = cityName; // ← only city name is shown
                      Navigator.pop(ctx);
                    },
                    getPlaceDetailWithLatLng: (Prediction p) {
                      // optional - not used here
                    },
                    seperatedBuilder: const Divider(),
                    isCrossBtnShown: true,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Select city where your vehicle is currently located",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    c = Get.put(FreeNewBookingController());

    c.startTime.value = DateTime.now();
    c.endTime.value = DateTime.now().add(const Duration(days: 1));
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      );

  InputDecoration _inputDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Post Free Vehicle',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Type
            _buildLabel('Select Vehicle Type'),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField2<String>(
                value: c.vehicleType.value,
                isExpanded: true,
                decoration: _inputDecoration(),
                items: [
                  'Sedan',
                  'Hatchback',
                  'Ertiga',
                  'SUV',
                  'INNOVA',
                  'INNOVA CRYSTA',
                  'FORCE Traveller'
                ]
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (v) => c.vehicleType.value = v!,
              ),
            ),
            const SizedBox(height: 24),

            // Start Time
            _buildLabel('Vehicle Free Start Time'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDateTime(true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(
                      () => Text(
                        _dateFormat.format(c.startTime.value),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: Color(0xFF6A1B9A)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // End Time
            _buildLabel('Vehicle Free End Time'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDateTime(false),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(
                      () => Text(
                        _dateFormat.format(c.endTime.value),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: Color(0xFF6A1B9A)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Location - only city name visible
            _CityFieldFull(
              label: 'Vehicle Location',
              controller: c.locationController,
              onTap: () => _showCityBottomSheet(
                  context, c, c.locationController, "Vehicle"),
            ),
            const SizedBox(height: 24),

            // Details
            _buildLabel('Add details'),
            const SizedBox(height: 8),
            TextFormField(
              controller: c.detailsController,
              minLines: 4,
              maxLines: 6,
              decoration: _inputDecoration(
                hint:
                    'More details about your free vehicle (brand, model, condition, etc.)',
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
                  onPressed: c.isSubmitting.value ? null : c.submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                  ),
                  child: c.isSubmitting.value
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            ),
                            SizedBox(width: 16),
                            Text('Submitting...',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 17)),
                          ],
                        )
                      : const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// Full Width City Field - shows only city name
class _CityFieldFull extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _CityFieldFull({
    required this.label,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: TextField(
            controller: controller,
            enabled: false,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: "Select city",
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                color: Color(0xFF6A1B9A),
              ),
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
