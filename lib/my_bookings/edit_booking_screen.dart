import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:intl/intl.dart';

import 'my_booking_controller.dart';

class EditBookingScreen extends StatelessWidget {
  final String tripId;

  const EditBookingScreen({super.key, required this.tripId});

  String _extractCleanCity(Prediction prediction) {
    final description = prediction.description ?? '';
    if (description.isEmpty) return '';

    final parts = description.split(', ');
    if (parts.isEmpty) return description.trim();

    String city = parts[0].trim();

    // Prefer main city name in common Indian formats
    if (parts.length >= 4 && parts[1].trim().length > 3) {
      city = parts[1].trim();
    }

    // Clean unwanted suffixes
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
    MyBookingController c,
    TextEditingController controller,
    String label,
  ) {
    final tempController = TextEditingController();
    final searchFocusNode = FocusNode();
    const apiKey =
        "AIzaSyAVaPMPGqeahxVzZbpEJGbGkiW0RNMzIEM"; // ← Replace with your real key

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
                // Drag handle
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

                      final cityName = _extractCleanCity(prediction);

                      controller.text = cityName; // ← only city name shown
                      Navigator.pop(ctx);
                    },
                    getPlaceDetailWithLatLng: (Prediction p) {
                      // Optional – not needed here
                    },
                    seperatedBuilder: const Divider(),
                    isCrossBtnShown: true,
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Select city for accurate trip planning",
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
  Widget build(BuildContext context) {
    final c = MyBookingController.to;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Edit Booking",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Your Trip',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // Trip Type
            _buildLabel('Trip Type'),
            const SizedBox(height: 12),
            Obx(
              () => Row(
                children: [
                  Expanded(child: _toggleButton(c, 'One Way', 'one_way')),
                  Expanded(child: _toggleButton(c, 'Round Trip', 'two_way')),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Car Type
            _buildLabel('Select Car Type'),
            const SizedBox(height: 8),
            Obx(
              () => DropdownButtonFormField2<String>(
                value: c.selectedCar.value,
                isExpanded: true,
                decoration: _inputDecoration(hint: 'Choose car type'),
                items: [
                  'Sedan',
                  'Hatchback',
                  'Ertiga',
                  'SUV',
                  'INNOVA',
                  'INNOVA CRYSTA',
                  'FORCE Traveller'
                ]
                    .map(
                        (car) => DropdownMenuItem(value: car, child: Text(car)))
                    .toList(),
                onChanged: (v) => c.selectedCar.value = v!,
              ),
            ),
            const SizedBox(height: 24),

            // From & To – now using Google Places
            Row(
              children: [
                Expanded(
                  child: _CityField(
                    label: 'From',
                    controller: c.fromController,
                    onTap: () => _showCityBottomSheet(
                        context, c, c.fromController, "From"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CityField(
                    label: 'To',
                    controller: c.toController,
                    onTap: () =>
                        _showCityBottomSheet(context, c, c.toController, "To"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: _DateField(controller: c, context: context),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TimeField(controller: c, context: context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Carrier
            _buildLabel('Carrier'),
            const SizedBox(height: 8),
            Obx(
              () => Row(
                children: [
                  _RadioOption(
                    title: 'No',
                    value: 'no',
                    group: c.hasCarrier.value,
                    onChanged: (v) => c.hasCarrier.value = v!,
                  ),
                  const SizedBox(width: 24),
                  _RadioOption(
                    title: 'Yes',
                    value: 'yes',
                    group: c.hasCarrier.value,
                    onChanged: (v) => c.hasCarrier.value = v!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Remarks
            _buildLabel('Remarks (Optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: c.remarksController,
              maxLines: 4,
              decoration: _inputDecoration(hint: 'Any special requests...'),
            ),
            const SizedBox(height: 32),

            // Get Contacted Via
            _buildLabel('Get Contacted Via'),
            const SizedBox(height: 8),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: c.sendWhatsapp.value,
                        onChanged: (v) => c.sendWhatsapp.value = v ?? false,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        FontAwesomeIcons.whatsapp,
                        color: Color(0xFF6A1B9A),
                        size: 36,
                      ),
                    ],
                  ),
                  const SizedBox(width: 50),
                  Row(
                    children: [
                      Checkbox(
                        value: c.sendCall.value,
                        onChanged: (v) => c.sendCall.value = v ?? false,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        FontAwesomeIcons.phone,
                        color: Color(0xFF6A1B9A),
                        size: 32,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Price Section
            _buildLabel('Price'),
            const SizedBox(height: 16),

            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: c.priceType.value == 'fixed',
                          activeColor: const Color(0xFF6A1B9A),
                          onChanged: (v) {
                            if (v == true) c.priceType.value = 'fixed';
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('Fixed',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Checkbox(
                          value: c.priceType.value == 'negotiable',
                          activeColor: const Color(0xFF6A1B9A),
                          onChanged: (v) {
                            if (v == true) c.priceType.value = 'negotiable';
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('Negotiable',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: c.priceController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(hint: 'Enter price (₹)'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),

            // Update Button
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
                  onPressed: c.isSubmitting.value
                      ? null
                      : () => c.updateExistingBooking(tripId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A1B9A),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 10,
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
                            Text("Updating...",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 17)),
                          ],
                        )
                      : const Text(
                          "Update Booking",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
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

  Widget _toggleButton(MyBookingController c, String text, String value) =>
      ElevatedButton(
        onPressed: () => c.tripType.value = value,
        style: ElevatedButton.styleFrom(
          backgroundColor: c.tripType.value == value
              ? const Color(0xFF6A1B9A)
              : Colors.grey.shade200,
          foregroundColor:
              c.tripType.value == value ? Colors.white : Colors.black87,
          elevation: c.tripType.value == value ? 6 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(
              left:
                  value == 'one_way' ? const Radius.circular(16) : Radius.zero,
              right:
                  value == 'two_way' ? const Radius.circular(16) : Radius.zero,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A)),
      );

  InputDecoration _inputDecoration({required String hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF8E24AA), width: 2),
        ),
      );
}

class _CityField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onTap;

  const _CityField({
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
            decoration: InputDecoration(
              hintText: "Select $label city",
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: Color(0xFF6A1B9A)),
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final MyBookingController controller;
  final BuildContext context;

  const _DateField({required this.controller, required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => controller.pickDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 20, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => Text(
                      controller.selectedDate.value != null
                          ? DateFormat('dd MMM yyyy')
                              .format(controller.selectedDate.value!)
                          : 'Select date',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final MyBookingController controller;
  final BuildContext context;

  const _TimeField({required this.controller, required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time',
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A)),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => controller.pickTime(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time,
                    size: 20, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 12),
                Obx(
                  () => Text(
                    controller.selectedTime.value?.format(context) ??
                        'Select time',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String title;
  final String value;
  final String group;
  final Function(String?) onChanged;

  const _RadioOption({
    required this.title,
    required this.value,
    required this.group,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: group,
          activeColor: const Color(0xFF6A1B9A),
          onChanged: onChanged,
        ),
        Text(title, style: const TextStyle(fontSize: 15)),
      ],
    );
  }
}
