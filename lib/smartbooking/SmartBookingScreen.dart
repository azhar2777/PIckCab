import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'SmartBookingController.dart';

class SmartBookingScreen extends StatefulWidget {
  const SmartBookingScreen({super.key});

  @override
  State<SmartBookingScreen> createState() => _SmartBookingScreenState();
}

class _SmartBookingScreenState extends State<SmartBookingScreen> {
  final controller = Get.put(SmartBookingController(), permanent: true);
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !controller.showBookingForm.value, // only allow pop if form is hidden
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (controller.showBookingForm.value) {
          // Hide the form instead of popping
          controller.showBookingForm.value = false;
          print("Booking form hidden, back blocked");
          // Don't call maybePop here!
        } else {
          // Form is already hidden, allow back navigation
          print("Back allowed, navigating...");
          Navigator.of(context).maybePop(); // optional, usually handled by PopScope
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            "Create Booking",
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Obx(
          () => SafeArea(
            child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: controller.showBookingForm.value
                        ? Container(
                      child: ListView(
                        children: [
                          const SizedBox(height: 12),
                          Center(
                            child: Text("Booking Details",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF6A1B9A),),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Obx(
                                () => Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => controller.tripType.value = 'one_way',
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: controller.tripType.value == 'one_way'
                                          ? const Color(0xFF6A1B9A)
                                          : Colors.grey.shade200,
                                      foregroundColor: controller.tripType.value == 'one_way'
                                          ? Colors.white
                                          : Colors.black87,
                                      elevation: controller.tripType.value == 'one_way' ? 6 : 0,
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
                                    onPressed: () => controller.tripType.value = 'two_way',
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: controller.tripType.value == 'two_way'
                                          ? const Color(0xFF6A1B9A)
                                          : Colors.grey.shade200,
                                      foregroundColor: controller.tripType.value == 'two_way'
                                          ? Colors.white
                                          : Colors.black87,
                                      elevation: controller.tripType.value == 'two_way' ? 6 : 0,
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

                          const SizedBox(height: 20.0,),
                          // Date & Time
                          Row(
                            children: [
                              Expanded(
                                child: _DateField(controller: controller, context: context, label: "Pickup Date",),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _TimeField(controller: controller, label: "Pickup Time",),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0,),
                          buildInputTextFiels(
                            controller.pickupLocationController,
                            "Pickup Location",
                            hintText:
                            "Pickup Location",
                            keyboard: TextInputType.name,
                            expands: false,
                          ),
                          const SizedBox(height: 10.0,),
                          buildInputTextFiels(
                            controller.dropLocationController,
                            "Drop Location",
                            hintText:
                            "Drop Location",
                            keyboard: TextInputType.name,
                            expands: false,
                          ),
                          const SizedBox(height: 10.0,),

                          buildInputTextFiels(
                            controller.mobileController,
                            "Mobile Number",
                            hintText:
                            "Mobile Number",
                            keyboard: TextInputType.name,
                            expands: false,
                          ),
                          const SizedBox(height: 10.0,),
                          buildInputTextFiels(
                            controller.priceController,
                            "Price",
                            hintText:
                            "Price",
                            keyboard: TextInputType.name,
                            expands: false,
                          ),
                          const SizedBox(height: 10.0,),
                          buildInputTextFiels(
                            controller.remarkController,
                            "Message",
                            hintText:
                            "remark",
                            keyboard: TextInputType.multiline,
                            expands: false,
                            maxLines: 5,
                          ),
                          const SizedBox(height: 30.0,),
                          /// 👇 Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: controller.isSubmitting.value
                                  ? null
                                  : () {
                                FocusManager.instance.primaryFocus
                                    ?.unfocus();

                                controller.getBookingData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A1B9A),
                                padding:
                                const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 10,
                              ),
                              child: Obx(() => controller.isSubmitting.value
                                  ? const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
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
                                    "Saving...",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                    ),
                                  ),
                                ],
                              )
                                  : const Text(
                                "Add Booking",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )),
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    )
                        : Column(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: buildInputTextFiels(
                                    controller.messageController,
                                    "",
                                    hintText:
                                        "Write or Paste your booking details...",
                                    keyboard: TextInputType.multiline,
                                    expands: true,
                                  ),
                                ),
                              ),

                              /// 👇 Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: controller.isSubmitting.value
                                      ? null
                                      : () {
                                          FocusManager.instance.primaryFocus
                                              ?.unfocus();

                                          controller.getBookingData();
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6A1B9A),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 10,
                                  ),
                                  child: Obx(() => controller.isSubmitting.value
                                      ? const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
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
                                              "Extracting...",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Text(
                                          "Extract Booking Details",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )),
                                ),
                              ),

                              const SizedBox(height: 20),
                            ],
                          ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget buildInputTextFiels(
      TextEditingController controller,
      String label, { // this will be the floating label
        String hintText = "",
        TextInputType keyboard = TextInputType.text,
        String? prefix,
        String? error,
        List<TextInputFormatter>? inputFormatters,
        int? maxLines = 1,
        int? minLines,
        bool expands = false,
      }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      maxLines: expands ? null : maxLines,
      minLines: minLines,
      expands: expands,
      textAlignVertical: TextAlignVertical.top,
      style: GoogleFonts.poppins(
        fontSize: 16,
        color: const Color(0xFF333333),
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label, // 🔹 Floating label
        floatingLabelBehavior: FloatingLabelBehavior.auto, // default behavior
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.black54),
        errorText: error?.isNotEmpty == true ? error : null,
        errorStyle: const TextStyle(color: Colors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: Color(0xFF6A1B9A),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: Color(0xFF6A1B9A),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  void _showPostBottomSheet() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          height: Get.height, // 👈 FULL SCREEN
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.close_rounded,
                        size: 40,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

// Date & Time Fields (unchanged)
class _DateField extends StatelessWidget {
  final SmartBookingController controller;
  final String label;
  final BuildContext context;
  const _DateField({required this.controller, required this.context, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
// Floating label
        Obx(() {
          final hasValue = controller.selectedTime.value != null;
          return Text(
            label,
            style: TextStyle(
              fontSize: hasValue ? 12 : 16,
              color: hasValue ? Colors.purple : Colors.grey.shade600,
              fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
            ),
          );
        }),
        const SizedBox(height: 4),
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
                        'yyyy-MM-dd',
                      ).format(controller.selectedDate.value!)
                          : 'Select pickup date',
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
  final SmartBookingController controller;
  final String label;

  const _TimeField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Floating label
        Obx(() {
          final hasValue = controller.selectedTime.value != null;
          return Text(
            label,
            style: TextStyle(
              fontSize: hasValue ? 12 : 16,
              color: hasValue ? Colors.purple : Colors.grey.shade600,
              fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
            ),
          );
        }),
        const SizedBox(height: 4),
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
                        'Select pickup time',
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


