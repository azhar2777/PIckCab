import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../includes/header.dart';
import 'booking_details_controller.dart';

class FreeBookingDetailsScreen extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic>? initialData;
  final Map<String, dynamic>? initialUserData;

  const FreeBookingDetailsScreen({
    super.key,
    required this.bookingId,
    this.initialData,
    this.initialUserData,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FreeBookingDetailsController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initialData != null) {
        controller.initialize(
          Map<String, dynamic>.from(initialData!),
          initialUserData != null
              ? Map<String, dynamic>.from(initialUserData!)
              : null,
        );
      } else {
        controller.fetchBookingDetails(bookingId);
      }
    });

    return Scaffold(
      appBar: AppHeader(
        showBackButton: true,
      ),
      backgroundColor: Colors.white,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF6A1B9A),
            ),
          );
        }

        final booking =
            Map<String, dynamic>.from(controller.bookingDetails.value);

        if (booking.isEmpty) {
          return const Center(
            child: Text('No booking details found'),
          );
        }

        final bool isTwoWay = booking['trip_type'] == 'round_trip';
        final bool isBooked = controller.isBooked();
        final String tripId = booking['trip_id']?.toString() ?? "N/A";
        final String bookingId = booking['id']?.toString() ?? "N/A";
        final String from = booking['start_location'] ?? "Unknown";
        final String to = booking['end_location'] ?? "Unknown";
        final String date = controller.formatTripDate(booking['trip_date']);
        final String time = booking['trip_time'] ?? 'N/A';
        final String carType = booking['car_type'] ?? 'Not specified';
        final String price = controller.getPriceDisplay();
        final String remarks = (booking['remarks'] ?? '').toString().trim();
        final String maskedRemarks = controller.maskMobileNumbers(remarks);
        final String addedOn = booking['added_on'] ?? '';
        final bool canSendWhatsApp = controller.canSendWhatsApp();
        final bool canSendCall = controller.canSendCall();
        final bool needsCarrier = controller.needsCarrier();
        final String status = booking['status'] == "1" ? "Available" : "Booked";
        final Color statusColor =
            booking['status'] == "1" ? Colors.green : Colors.red;
        final String priceType = booking['price_type'] ?? 'Not specified';
        final String userId = booking['user_id']?.toString() ?? 'N/A';
        final String bookById =
            booking['book_by_id']?.toString() ?? 'Not booked yet';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with ID and Status
              _buildHeaderCard(
                tripId: tripId,
                status: status,
                statusColor: statusColor,
              ),

              const SizedBox(height: 16),

              // Route Information
              _buildRouteCard(
                from: from,
                to: to,
                isTwoWay: isTwoWay,
                date: date,
                time: time,
                needsCarrier: needsCarrier,
              ),

              const SizedBox(height: 16),

              // Vehicle & Price Details
              _buildDetailsCard(
                carType: carType,
                price: price,
                priceType: priceType,
              ),

              const SizedBox(height: 16),

              // Remarks Section
              if (remarks.isNotEmpty) ...[
                _buildRemarksCard(
                  remarks: maskedRemarks,
                  isBooked: isBooked,
                ),
                const SizedBox(height: 16),
              ],

              // Contact Action Buttons
              _buildActionButtons(controller),

              const SizedBox(height: 16),

              // Additional Information
              // _buildAdditionalInfoCard(
              //   bookingId: bookingId,
              //   userId: userId,
              //   addedOn: addedOn,
              //   bookById: bookById,
              //   sendWhatsApp: canSendWhatsApp,
              //   sendCall: canSendCall,
              //   carrier: needsCarrier,
              // ),

              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeaderCard({
    required String tripId,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip ID',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tripId,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF6A1B9A),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(0xFF6A1B9A),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == "Available" ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: Color(0xFF6A1B9A),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard({
    required String from,
    required String to,
    required bool isTwoWay,
    required String date,
    required String time,
    required bool needsCarrier,
  }) {
    const dotColor = Color(0xFF6A1B9A);
    const double triangleSize = 12.0;
    const double lineHeight = 2.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6A1B9A).withOpacity(0.1),
            const Color(0xFF9C27B0).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Dotted Route Visualization
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FROM',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      from,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6A1B9A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // const SizedBox(width: 8),

              // Center Dotted Line with Icon
              Expanded(
                flex: 3,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Positioned(
                    //   top: -32,
                    //   child: Container(
                    //     width: 28,
                    //     height: 28,
                    //     decoration: BoxDecoration(
                    //       color: dotColor,
                    //       shape: BoxShape.circle,
                    //       boxShadow: [
                    //         BoxShadow(
                    //           color: dotColor.withOpacity(0.3),
                    //           blurRadius: 8,
                    //           spreadRadius: 2,
                    //         ),
                    //       ],
                    //     ),
                    //     child: Center(
                    //       child: Icon(
                    //         isTwoWay ? Icons.sync_alt : Icons.arrow_forward,
                    //         color: Colors.white,
                    //         size: 14,
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    // Dotted Line
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final available =
                            constraints.maxWidth - (triangleSize * 1.5);
                        final dotCount = (available / 8).floor().clamp(8, 100);
                        return Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: triangleSize),
                          child: Row(
                            children: List.generate(
                              dotCount,
                              (_) => Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 1.5),
                                  height: lineHeight,
                                  color: dotColor.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Trip Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: dotColor.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        isTwoWay ? "Round Trip" : "One Way",
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: dotColor,
                        ),
                      ),
                    ),

                    // Left Triangle
                    if (isTwoWay)
                      Positioned(
                        left: -1,
                        child: Triangle(
                          color: dotColor.withOpacity(0.8),
                          size: triangleSize,
                          left: true,
                        ),
                      ),

                    // Right Triangle
                    Positioned(
                      right: -1,
                      child: Triangle(
                        color: dotColor.withOpacity(0.8),
                        size: triangleSize,
                        left: false,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TO',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      to,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6A1B9A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Date & Time Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Date
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B9A).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF6A1B9A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Date',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),

                // Time
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6A1B9A).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.access_time,
                          color: Color(0xFF6A1B9A),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Time',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        time,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                // // Divider
                // Container(
                //   width: 1,
                //   height: 40,
                //   color: Colors.grey.shade300,
                // ),

                // Posted
                // Expanded(
                //   child: Column(
                //     children: [
                //       Container(
                //         width: 40,
                //         height: 40,
                //         decoration: BoxDecoration(
                //           color: const Color(0xFF6A1B9A).withOpacity(0.1),
                //           shape: BoxShape.circle,
                //         ),
                //         child: const Icon(
                //           Icons.schedule,
                //           color: Color(0xFF6A1B9A),
                //           size: 20,
                //         ),
                //       ),
                //       const SizedBox(height: 8),
                //       Text(
                //         'Posted',
                //         style: GoogleFonts.poppins(
                //           fontSize: 12,
                //           color: Colors.grey.shade600,
                //         ),
                //       ),
                //       const SizedBox(height: 4),
                //       Text(
                //         'Just now',
                //         style: GoogleFonts.montserrat(
                //           fontSize: 14,
                //           fontWeight: FontWeight.w600,
                //           color: Colors.black87,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),

          // Carrier Required Banner
          if (needsCarrier) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping,
                      color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Carrier required for this trip',
                      style: GoogleFonts.poppins(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

// Helper method for date & time items (simplified version)
  Widget _infoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF6A1B9A).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF6A1B9A), size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard({
    required String carType,
    required String price,
    required String priceType,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip Details',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _detailBox(
                  icon: Icons.directions_car,
                  title: 'Vehicle Type',
                  value: carType,
                  color: const Color(0xFF6A1B9A),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _detailBox(
                  icon: Icons.currency_rupee_outlined,
                  title: 'Price',
                  value: price,
                  color: Color(0xFF6A1B9A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.price_change,
                  color: Color(0xFF6A1B9A),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price Type',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        priceType == 'fixed'
                            ? 'Fixed Price'
                            : priceType == 'negotiable'
                                ? 'Negotiable'
                                : priceType,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6A1B9A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBox({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksCard({
    required String remarks,
    required bool isBooked,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notes, color: const Color(0xFF6A1B9A)),
              const SizedBox(width: 12),
              Text(
                'Remarks',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remarks,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                if (isBooked) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'This trip has been booked',
                          style: GoogleFonts.poppins(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

// Actions

  Widget _buildActionButtons(FreeBookingDetailsController controller) {
    final booking = controller.bookingDetails.value;
    final bool canSendWhatsApp = controller.canSendWhatsApp();
    final bool canSendCall = controller.canSendCall();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Contact Options',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Share Button (Always shown)
              Expanded(
                child: _actionButton(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  color: const Color(0xFF6A1B9A),
                  onTap: controller.shareBooking,
                ),
              ),

              if (canSendWhatsApp) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    icon: FontAwesomeIcons.whatsapp,
                    label: 'WhatsApp',
                    color: Colors.green,
                    onTap: () async {
                      controller.openWhatsApp();
                    },
                  ),
                ),
              ],

              if (canSendCall) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    icon: Icons.call,
                    label: 'Call',
                    color: Colors.blue,
                    onTap: () {
                      // You need to get the actual phone number from user API
                      controller.makePhoneCall();
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xFF6A1B9A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Color(0xFF6A1B9A), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6A1B9A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard({
    required String bookingId,
    required String userId,
    required String addedOn,
    required String bookById,
    required bool sendWhatsApp,
    required bool sendCall,
    required bool carrier,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _infoRow('Booking ID', bookingId),
          _infoRow('User ID', userId),
          // _infoRow('Posted On', addedOn),
          _infoRow(
              'Booked By ID', bookById == 'null' ? 'Not booked' : bookById),
          _infoRow('WhatsApp Allowed', sendWhatsApp ? 'Yes' : 'No'),
          _infoRow('Call Allowed', sendCall ? 'Yes' : 'No'),
          _infoRow('Carrier Required', carrier ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6A1B9A),
            ),
          ),
        ],
      ),
    );
  }
}

class Triangle extends StatelessWidget {
  final Color color;
  final double size;
  final bool left;
  const Triangle({
    super.key,
    required this.color,
    required this.size,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TrianglePainter(color: color, left: left),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool left;
  const _TrianglePainter({required this.color, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    if (left) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
