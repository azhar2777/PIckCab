import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;

import 'EditProfileController.dart';

class Editprofilescreen extends StatefulWidget {
  const Editprofilescreen({super.key});

  @override
  State<Editprofilescreen> createState() => _EditprofilescreenState();
}

class _EditprofilescreenState extends State<Editprofilescreen> {
  final controller = Get.put(Editprofilecontroller(), permanent: true);


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


  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(
            () => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child:
          controller.isLoading.value ? Center(
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: Color(0xFF6A1B9A),),
            ),
          ):
          ListView(
            children: [
              SizedBox(height: 30,),
              const SizedBox(height: 30),

              Center(
                child: Stack(
                  children: [

                    controller.capturedImage.value != null ? Container(
                      height: 140,
                      width: 140,
                      decoration: BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(70),
                        color: Colors.white,
                        // shape: BoxShape.circle,

                      ),
                      child: ClipRRect(
                        borderRadius:
                        BorderRadius.circular(70),
                        child: Image.file(
                            controller.capturedImage.value!,
                            fit: BoxFit.cover),
                      ),
                    ):  CircleAvatar(
                      radius: 70,
                      backgroundImage: NetworkImage(user['avatarUrl'] ?? ''),
                      onBackgroundImageError: (_, __) {},
                    ),
                    Positioned(
                      right: 8,
                      bottom: 0,
                      child: InkWell(
                        onTap: controller.captureImage,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Color(0xFF6A1B9A),
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40,),
              Text(
                "Full Name",
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  color: Color(0xFF6A1B9A),),
              ),
              const SizedBox(height: 8),
              _inputField_username(
                controller.nameController,
                "",
                error: controller.nameError.value,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                      RegExp(r'[a-zA-Z ]')),
                ],
              ),
              SizedBox(height: 20,),
              Text(
                "City",
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6A1B9A),),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () =>
                    _showCityBottomSheet(context, controller),
                borderRadius: BorderRadius.circular(10),
                child: TextField(
                  controller: controller.cityController,
                  enabled: false,
                  style: const TextStyle(
                      color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,

                    prefixIcon: const Icon(
                      Icons.location_city_outlined,
                      color: Color(0xFF6A1B9A),
                    ),

                    hintText: "Tap to search & select city",
                    hintStyle: const TextStyle(color: Colors.black54),

                    errorText: controller.cityError.value.isEmpty
                        ? null
                        : controller.cityError.value,
                    errorStyle: const TextStyle(color: Colors.red),
                    // ✅ Default border
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),

                    // ✅ When enabled (not focused)
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(
                        color: Colors.grey,
                        width: 1,
                      ),
                    ),

                    // ✅ When focused
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(
                        color: Color(0xFF6A1B9A),
                        width: 1.5,
                      ),
                    ),

                    // ✅ When error occurs
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),

                    // ✅ When focused + error
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),

                    suffixIcon: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedOpacity(
                opacity: controller.cityController.text.isNotEmpty
                    ? 1.0
                    : 0.0,
                duration:
                const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4),
                  child: Text(
                    controller.cityController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color:
                      Colors.black54.withOpacity(0.75),
                      height: 1.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Update Button
              SizedBox(
                width: double.infinity,
                child: Obx(
                      () => ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : () =>{
                      FocusManager.instance.primaryFocus?.unfocus(),
                      controller.updateProfile(),

                      },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 10,
                    ),
                    child: controller.isSubmitting.value
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
                      "Update",
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
      ),
    ),
    );
  }

  void _showCityBottomSheet(BuildContext context, Editprofilecontroller c) {
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
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,

        prefixIcon: const Icon(
          Icons.person_sharp,
          color: Color(0xFF6A1B9A),
        ),

        hintText: "Tap to search & select city",
        hintStyle: const TextStyle(color: Colors.black54),

        errorText: error?.isNotEmpty == true ? error : null,
        errorStyle: const TextStyle(color: Colors.red),

        // ✅ Default border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),

        // ✅ When enabled (not focused)
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),

        // ✅ When focused
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: Color(0xFF6A1B9A),
            width: 1.5,
          ),
        ),

        // ✅ When error occurs
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),

        // ✅ When focused + error
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1.5,
          ),
        ),


      ),
    );
  }
}
