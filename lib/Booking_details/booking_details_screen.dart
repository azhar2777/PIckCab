import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pickcab_partner/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../includes/header.dart';
import '../login/login_screen.dart';
import 'booking_details_controller.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  bool _showAllDetails = false;
  // late final BookingDetailsController controller;

  BookingDetailsController controller = Get.put(BookingDetailsController());

  @override
  void initState() {
    super.initState();

    controller.fetchBookingDetails(widget.bookingId);

    // Load data after frame is built
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(
        showBackButton: true,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Obx(() {
          debugPrint(
              "🔄 Building UI for booking ID: ${widget.bookingId}, Controller hash: ${controller.hashCode}");

          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6A1B9A),
              ),
            );
          }

          final booking = controller.bookingDetails.value;

          if (booking.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No booking details found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        controller.fetchBookingDetails(widget.bookingId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Verify we're showing the correct booking ID
          final currentBookingId = booking['id']?.toString();
          if (currentBookingId != widget.bookingId) {
            debugPrint(
                "⚠️ Booking ID mismatch! UI: ${widget.bookingId}, Data: $currentBookingId");
            // Fetch correct data
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.fetchBookingDetails(widget.bookingId);
            });

            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6A1B9A),
              ),
            );
          }

          return _buildContent(booking);
        }),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> booking) {
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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(
                    tripId: tripId, status: status, statusColor: statusColor),
                const SizedBox(height: 16),
                _buildRouteCard(
                  from: from,
                  to: to,
                  isTwoWay: isTwoWay,
                  date: date,
                  time: time,
                  needsCarrier: needsCarrier,
                ),
                const SizedBox(height: 16),
                _buildDetailsCard(
                    carType: carType, price: price, priceType: priceType),
                const SizedBox(height: 16),
                if (remarks.isNotEmpty) ...[
                  _buildRemarksCardCompact(
                      remarks: maskedRemarks, isBooked: isBooked),
                  const SizedBox(height: 16),
                ],
                if (_showAllDetails) ...[
                  _buildAdditionalInfoCard(
                    bookingId: bookingId,
                    userId: userId,
                    addedOn: addedOn,
                    bookById: bookById,
                    sendWhatsApp: canSendWhatsApp,
                    sendCall: canSendCall,
                    carrier: needsCarrier,
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (!isBooked) ...[
                _buildActionButtonsCompact(),
                const SizedBox(height: 12),
              ],
              _buildSeeMoreButton(),
            ],
          ),
        ),
      ],
    );
  }

  // ... (keep all your existing _build methods exactly as they are from your original code)
  // Copy all the _build methods from your original BookingDetailsScreen here

  Widget _buildHeaderCard(
      {required String tripId,
      required String status,
      required Color statusColor}) {
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
      child: Row(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6A1B9A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  status == "Available" ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: const Color(0xFF6A1B9A),
                ),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6A1B9A),
                  ),
                ),
              ],
            ),
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
    return Container(
      padding: const EdgeInsets.all(16),
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
                        color: dotColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final dotCount =
                            (constraints.maxWidth / 10).floor().clamp(8, 100);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            children: List.generate(
                              dotCount,
                              (_) => Expanded(
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 1),
                                  height: 2,
                                  color: dotColor.withOpacity(0.8),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: dotColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        isTwoWay ? "Round" : "One Way",
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: dotColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                        color: dotColor,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: dotColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: dotColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          date,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: dotColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: dotColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (needsCarrier) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping,
                      color: Colors.amber.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Carrier required',
                      style: GoogleFonts.poppins(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
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

  Widget _buildDetailsCard({
    required String carType,
    required String price,
    required String priceType,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Expanded(
            child: _detailBoxCompact(
              icon: Icons.directions_car,
              label: 'Vehicle',
              value: carType,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _detailBoxCompact(
              icon: Icons.currency_rupee,
              label: 'Price',
              value: price,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.price_change,
                      color: Color(0xFF6A1B9A), size: 20),
                  const SizedBox(height: 4),
                  Text(
                    priceType == 'fixed'
                        ? 'Fixed'
                        : priceType == 'negotiable'
                            ? 'Negotiable'
                            : 'N/A',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6A1B9A),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBoxCompact({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF6A1B9A).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6A1B9A), size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6A1B9A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksCardCompact({
    required String remarks,
    required bool isBooked,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6A1B9A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notes, color: Color(0xFF6A1B9A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remarks',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remarks,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (isBooked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'Booked',
                style: GoogleFonts.poppins(
                  color: Colors.red.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsCompact() {
    final bool canSendWhatsApp = controller.canSendWhatsApp();
    final bool canSendCall = controller.canSendCall();

    return Row(
      children: [
        Expanded(
          child: _actionButtonCompact(
            icon: Icons.share_rounded,
            label: 'Share',
            color: const Color(0xFF6A1B9A),
            onTap: controller.shareBooking,
          ),
        ),
        if (canSendWhatsApp) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _actionButtonCompact(
              icon: FontAwesomeIcons.whatsapp,
              label: 'WhatsApp',
              color: Colors.green,
              onTap: controller.openWhatsApp,
            ),
          ),
        ],
        if (canSendCall) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _actionButtonCompact(
              icon: Icons.call,
              label: 'Call',
              color: Colors.blue,
              onTap: controller.makePhoneCall,
            ),
          ),
        ],
      ],
    );
  }

  Widget _actionButtonCompact({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF6A1B9A).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF6A1B9A), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6A1B9A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeeMoreButton() {
    return GestureDetector(
      onTap: () {
        Get.to(HomeScreen());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _showAllDetails ? 'See Less' : 'See More',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _showAllDetails
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: const Color(0xFF6A1B9A),
              size: 20,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Information',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoRowCompact('Booking ID', bookingId),
              ),
              Expanded(
                child: _infoRowCompact('User ID', userId),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _infoRowCompact(
                    'Booked By', bookById == 'null' ? 'Not booked' : bookById),
              ),
              Expanded(
                child: _infoRowCompact('WhatsApp', sendWhatsApp ? 'Yes' : 'No'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _infoRowCompact('Call', sendCall ? 'Yes' : 'No'),
              ),
              Expanded(
                child: _infoRowCompact('Carrier', carrier ? 'Yes' : 'No'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRowCompact(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6A1B9A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
