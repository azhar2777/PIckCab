import 'dart:convert';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:intl/intl.dart';

import '../../includes/header.dart';
import 'new_booking_controller.dart';

import 'package:http/http.dart' as http;

class NewBookingScreen extends StatelessWidget {
  const NewBookingScreen({super.key});

  void _showCityDialog(
    BuildContext context,
    NewBookingController c,
    TextEditingController controller,
    String label,
  ) {
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Select $label City",
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Search city...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF8E24AA),
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (v) => c.searchCities(v),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(
                () => c.filteredCities.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: c.filteredCities.length,
                        itemBuilder: (context, index) {
                          final city = c.filteredCities[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Color(0xFF6A1B9A),
                            ),
                            title: Text(
                              city,
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                            onTap: () {
                              controller.text = city;
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCityAutocomplete(
    BuildContext context,
    NewBookingController c,
    TextEditingController textController,
    String label,
  ) {
    final tempController = TextEditingController();
    final searchFocusNode = FocusNode();

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
                const SizedBox(height: 20),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GooglePlaceAutoCompleteTextField(
                    focusNode: searchFocusNode,
                    // autofocus: true, // ✅ this is the key
                    textEditingController: tempController,

                    googleAPIKey:
                        "AIzaSyAVaPMPGqeahxVzZbpEJGbGkiW0RNMzIEM", // ← Replace with your real key
                    inputDecoration: InputDecoration(
                      hintText: "Search city, e.g. Ranchi, Jamshedpur...",
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
                    debounceTime: 600,
                    countries: const ["in"], // Restrict to India
                    isLatLngRequired:
                        true, // Get lat/lng if needed for distance calc later
                    getPlaceDetailWithLatLng: (Prediction prediction) async {
                      final placeId = prediction.placeId;
                      if (placeId == null) return;

                      final details = await getPlaceDetails(
                          placeId, "AIzaSyAVaPMPGqeahxVzZbpEJGbGkiW0RNMzIEM");

                      if (details != null) {
                        String city = '';
                        String state = '';
                        String fullAddress = details['formatted_address'] ??
                            prediction.description ??
                            '';

                        // Parse address_components
                        final components =
                            details['address_components'] as List<dynamic>? ??
                                [];
                        for (final comp in components) {
                          final types = (comp['types'] as List<dynamic>?)
                                  ?.cast<String>() ??
                              [];
                          final name = comp['long_name'] as String? ?? '';

                          if (types.contains('locality')) {
                            city = name;
                          } else if (types
                              .contains('administrative_area_level_1')) {
                            state = name;
                          }
                        }

                        // Fallbacks
                        city = city.isNotEmpty
                            ? city
                            : _extractCityName(prediction.description ?? '');
                        state = state.isNotEmpty
                            ? state
                            : _extractStateName(prediction.description ?? '');

                        textController.text = city;
                        // c.city.value = city;
                        // c.state.value = state;
                        // c.fullAddress.value = fullAddress;

                        tempController.text = fullAddress;

                        // You also have lat/lng already from prediction if needed
                      } else {
                        // Fallback to parsing if API call fails
                        textController.text =
                            _extractCityName(prediction.description ?? '');
                        tempController.text = prediction.description ?? '';
                      }

                      Navigator.pop(ctx);
                    },
                    itemClick: (Prediction prediction) {
                      // Optional: pre-fill on tap (but we use getPlaceDetailWithLatLng mainly)
                      tempController.text = prediction.description ?? '';
                      tempController.selection = TextSelection.fromPosition(
                        TextPosition(offset: tempController.text.length),
                      );
                    },
                    seperatedBuilder: const Divider(),
                    isCrossBtnShown: true,
                  ),
                ),

                const SizedBox(height: 16),

                // Optional: Show recent/ popular cities if no input yet
                // You can add ListView of favorites here if desired
              ],
            ),
          );
        });
  }

  Future<Map<String, dynamic>?> getPlaceDetails(
      String placeId, String apiKey) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=address_components,formatted_address,name,geometry'
      '&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['status'] == 'OK') {
        return json['result'];
      }
    }
    return null;
  }

  String _extractCityName(String description) {
    final parts = description.split(', ');
    if (parts.length >= 3) {
      // Ranchi, Jharkhand, India → city = Ranchi, state = Jharkhand
      return parts[0].trim();
    }
    return description;
  }

  String _extractStateName(String description) {
    final parts = description.split(', ');
    if (parts.length >= 3) {
      // Last but one is usually state in India
      return parts[parts.length - 2].trim();
    }
    return '';
  }

  String _getFullAddress(String description) {
    return description.trim(); // already the full suggestion
  }

  // Helper: Clean prediction.description to just city name (common in Indian context)
  // String _extractCityName(String fullDescription) {
  //   final desc = fullDescription ?? "";
  //   final parts = desc.split(', ');

  //   if (parts.length >= 3) {
  //     return parts[parts.length - 3].trim();
  //   }

  //   // final parts = fullDescription.split(', ');

  //   // if (parts.length >= 3) {
  //   //   // Often: "Ranchi, Jharkhand, India" → take first meaningful part
  //   //   return parts[0]
  //   //       .trim(); // or parts[parts.length - 3] for city in longer strings
  //   // }
  //   return fullDescription;
  // }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(NewBookingController());

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const AppHeader(showBackButton: false),
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
              'Create New Booking',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),

            // Trip Type
            // _buildLabel('Trip Type'),
            // const SizedBox(height: 12),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => c.tripType.value = 'one_way',
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.tripType.value == 'one_way'
                            ? const Color(0xFF6A1B9A)
                            : Colors.grey.shade200,
                        foregroundColor: c.tripType.value == 'one_way'
                            ? Colors.white
                            : Colors.black87,
                        elevation: c.tripType.value == 'one_way' ? 6 : 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'One Way',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => c.tripType.value = 'two_way',
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.tripType.value == 'two_way'
                            ? const Color(0xFF6A1B9A)
                            : Colors.grey.shade200,
                        foregroundColor: c.tripType.value == 'two_way'
                            ? Colors.white
                            : Colors.black87,
                        elevation: c.tripType.value == 'two_way' ? 6 : 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Round Trip',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
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
                decoration: _inputDecoration(hint: 'Select car type', isFloating: false),
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
                      (car) => DropdownMenuItem(value: car, child: Text(car)),
                    )
                    .toList(),
                onChanged: (v) => c.selectedCar.value = v!,
              ),
            ),
            const SizedBox(height: 30),

            // FROM (Full Width)

            const SizedBox(height: 8),
            _CityFieldFull(
              label: 'Pickup',
              controller: c.fromController,
              onTap: () =>
                  _showCityAutocomplete(context, c, c.fromController, "Pickup"),
            ),
            const SizedBox(height: 24),

            _CityFieldFull(
              label: 'Drop',
              controller: c.toController,
              onTap: () =>
                  _showCityAutocomplete(context, c, c.toController, "Drop"),
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
            const SizedBox(height: 30),
            // ====================== PRICE SECTION ======================
            // _buildLabel('Price'),
            // const SizedBox(height: 16),

            // Price Input Field
            TextFormField(
              controller: c.priceController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(hint: 'Enter price (₹)', isFloating: true),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),

            ),

            const SizedBox(height: 16),

            // Fixed / Negotiable Checkboxes
            Obx(
                  () => Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Fixed
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: c.priceType.value == 'fixed',
                          activeColor: const Color(0xFF6A1B9A),
                          onChanged: (v) {
                            if (v == true) c.priceType.value = 'fixed';
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Fixed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Negotiable
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: c.priceType.value == 'negotiable',
                          activeColor: const Color(0xFF6A1B9A),
                          onChanged: (v) {
                            if (v == true) c.priceType.value = 'negotiable';
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Negotiable',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),



            const SizedBox(height: 14),


            // Remarks
            // _buildLabel('Remarks (Optional)'),
            // const SizedBox(height: 8),
            TextFormField(
              controller: c.remarksController,
              maxLines: 4,
              decoration: _inputDecoration(hint: 'Enter Message...', isFloating: true),

            ),
            const SizedBox(height: 30),


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
                  const SizedBox(width: 32),
                  _RadioOption(
                    title: 'Yes',
                    value: 'yes',
                    group: c.hasCarrier.value,
                    onChanged: (v) => c.hasCarrier.value = v!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),



            // Contact Method - Icons Only
            // Get Contacted Via — ONLY ICON + CHECKBOX, NOTHING ELSE
            _buildLabel('Get Contacted Via'),
            const SizedBox(height: 20),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // WhatsApp
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

                  // Phone
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
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              "Submitting...",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          "Submit Booking",
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

  Widget _buildLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A1A),
        ),
      );

  InputDecoration _inputDecoration({required String hint, bool isFloating =false}) => InputDecoration(
        hintText: hint,
        labelText: hint,
        filled: true,
        fillColor: Colors.white,

    floatingLabelBehavior: isFloating ? FloatingLabelBehavior.always: FloatingLabelBehavior.never, // always float

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

// Full Width City Field (From/To)
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
        Row(
          children: [
            Text(
              label+" Location",
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Icon(Icons.star_outline, color: Colors.red, size: 18,),
          ],
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
            ), // Always bold
            decoration: InputDecoration(
              hintText: "Enter $label location",
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

// Date & Time Fields (unchanged)
class _DateField extends StatelessWidget {
  final NewBookingController controller;
  final BuildContext context;
  const _DateField({required this.controller, required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Pickup Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            Icon(Icons.star_outline, color: Colors.red, size: 18,),
          ],
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
                const Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Color(0xFF6A1B9A),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => Text(
                      controller.selectedDate.value != null
                          ? DateFormat(
                              'dd MMM yyyy',
                            ).format(controller.selectedDate.value!)
                          : 'Select date',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
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
  }
}

class _TimeField extends StatelessWidget {
  final NewBookingController controller;
  final BuildContext context;
  const _TimeField({required this.controller, required this.context});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Pickup Time',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            // Icon(Icons.star_outline, color: Colors.red, size: 18,),
          ],
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
                const Icon(
                  Icons.access_time,
                  size: 20,
                  color: Color(0xFF6A1B9A),
                ),
                const SizedBox(width: 12),
                Obx(
                  () => Text(
                    controller.selectedTime.value?.format(context) ??
                        'Select time',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
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
