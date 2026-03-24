import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../includes/header.dart';
import 'freebooking_controller.dart'; // Assuming you have or will create this

class FreebookingNewbackup extends StatefulWidget {
  const FreebookingNewbackup({super.key});

  @override
  State<FreebookingNewbackup> createState() => _FreebookingNewbackupState();
}

class _FreebookingNewbackupState extends State<FreebookingNewbackup> {
  late FreeNewBookingController c;

  final DateFormat _dateFormat = DateFormat("MMM d, yyyy @ h:mm a");

  Future<void> _selectDateTime(bool isStart) async {
    DateTime initial = isStart ? c.startTime.value : c.endTime.value;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (pickedDate == null) return;

    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (pickedTime != null) {
      final DateTime fullDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (isStart) {
        c.startTime.value = fullDateTime;
      } else {
        c.endTime.value = fullDateTime;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    c = Get.put(FreeNewBookingController());

    // Set default values matching screenshot
    c.vehicleType.value = 'Hatchback';
    c.startTime.value = DateTime(2025, 12, 27, 12, 3);
    c.endTime.value = DateTime(2025, 12, 27, 12, 3);
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
                items: ['Hatchback', 'Sedan', 'SUV', 'Mini Van', 'Truck']
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
                    const Icon(Icons.calendar_today, color: Colors.orange),
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
                    const Icon(Icons.calendar_today, color: Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Location
            _buildLabel('Vehicle Location'),
            const SizedBox(height: 8),
            TextFormField(
              controller: c.locationController,
              decoration: _inputDecoration(hint: 'Location').copyWith(
                suffixIcon:
                    const Icon(Icons.location_pin, color: Colors.orange),
              ),
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
                  hint: 'More details about your free vehicle...'),
            ),
            const SizedBox(height: 32),

            // Any Location Pickup
            Row(
              children: [
                Obx(
                  () => Radio<bool>(
                    value: true,
                    groupValue: c.anyLocation.value,
                    onChanged: (v) => c.anyLocation.value = v ?? false,
                    activeColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Available to Pick booking from any location?',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
                  onPressed: c.isSubmitting.value ? null : c.submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
