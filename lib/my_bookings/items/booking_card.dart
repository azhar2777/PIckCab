// Booking Card Widget
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating/flutter_rating.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:pickcab_partner/const/const.dart';
import 'package:pickcab_partner/my_bookings/my_booking_controller.dart';

class BookingCard extends StatefulWidget {
  final int currentIndex;
  final Map<String, dynamic> booking;
  final bool
      isMyBookingTab; // true for My Bookings tab, false for Book By Me tab
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String, bool, int) onBookedByOwner;
  final Function(String, String) onMarkAsBooked;

  const BookingCard({
    Key? key,
    required this.booking,
    required this.isMyBookingTab,
    this.onEdit,
    this.onDelete,
    required this.onMarkAsBooked,
    required this.onBookedByOwner,
    required this.currentIndex,
  }) : super(key: key);

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  final controller = Get.find<MyBookingController>();
  double _dragPosition = 0.0;
  bool _isCompleted = false;

  late bool markBooked = controller
      .bookings[widget.currentIndex]['mark_booked'];

  Future<bool> _showMarkAsBookedDialog(
    BuildContext context,
    Map<String, dynamic> booking,
  ) async {
    final ctrl = TextEditingController();
    final bookingId = booking['id'].toString();
    bool isProcessing = false;

    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text("Mark as Booked"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: ctrl,
                        decoration: const InputDecoration(
                          hintText: "User Unq ID",
                        ),
                        enabled: !isProcessing,
                      ),
                      if (isProcessing)
                        const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: isProcessing
                          ? null
                          : () => Navigator.of(dialogContext).pop(false),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              setState(() => isProcessing = true);

                              final unqId = ctrl.text.trim();
                              if (unqId.isEmpty) {
                                setState(() => isProcessing = false);
                                return;
                              }

                              await widget.onMarkAsBooked(bookingId, unqId);
                              if (mounted) {
                                Navigator.of(dialogContext).pop(true);
                              }
                            },
                      child: const Text("Confirm"),
                    ),
                  ],
                );
              },
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isPast = widget.booking['isPast'] as bool? ?? false;
    final bool isBooked = widget.booking['isBooked'] as bool? ?? false;
    final String? bookedBy = widget.booking['booked_by_id']?.toString() ??
        widget.booking['booked_by_unq_id']?.toString();

    final String rate = widget.booking['price'] != null &&
            widget.booking['price'].toString().isNotEmpty
        ? "₹${widget.booking['price']}"
        : "";
    final bool hasDestination =
        (widget.booking['to']?.toString().trim().isNotEmpty ?? false);

    final String? bookedbyid = widget.booking['added_by_id']?.toString();

    // Determine if we should show edit/delete buttons
    // Show only in My Bookings tab, for non-past AND non-booked bookings
    final bool showEditDelete = widget.isMyBookingTab && !isPast && !isBooked;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      child: Column(
        children: [
          // Main Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300, width: 1.3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.booking['isTwoWay'] == true
                                  ? Colors.purple.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.booking['isTwoWay'] == true
                                  ? "Round Trip"
                                  : "One Way",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: widget.booking['isTwoWay'] == true
                                    ? Colors.purple.shade700
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Car Type and Rate Row
                      Row(
                        children: [
                          Expanded(
                              child: _infoBox(
                                  "Car Type",
                                  widget.booking['carType'] ?? "Sedan",
                                  Colors.grey.shade100)),
                          const SizedBox(width: 8),
                          if (widget.isMyBookingTab && rate.isNotEmpty)
                            Expanded(
                                child: _infoBox(
                                    "Rate", rate, Colors.grey.shade100)),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // From → To Location Row
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on,
                                size: 18, color: Color(0xFF6A1B9A)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.booking['from'] ?? 'Location not set',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasDestination) ...[
                              const Icon(Icons.arrow_forward,
                                  size: 22, color: Color(0xFF6A1B9A)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  widget.booking['to'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 22, color: Colors.black87),
                          const SizedBox(width: 10),
                          Text(
                            widget.booking['date'] ?? 'Date not set',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Text(
                            widget.booking['time'] ?? 'Date not set',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),

                      // Remarks
                      if ((widget.booking['remarks'] ?? '')
                          .toString()
                          .trim()
                          .isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text(
                            widget.booking['remarks'],
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),

                      // Show Booked By ID for Book By Me tab
                      if (!widget.isMyBookingTab &&
                          bookedBy != null &&
                          bookedBy.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Row(
                            children: [
                              Icon(Icons.person,
                                  size: 20, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                "Booked By: $bookedBy",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (!widget.isMyBookingTab &&
                          bookedBy != null &&
                          bookedBy.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Row(
                            children: [
                              Icon(Icons.person,
                                  size: 20, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                "Booking User Id: ${bookedbyid.toString().toUpperCase()}",
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 10),

                      // Edit & Delete Buttons - Only shown for:
                      // 1. My Bookings tab
                      // 2. Not past
                      // 3. Not booked
                      if (showEditDelete)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: widget.onEdit,
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                label: const Text("Edit",
                                    style: TextStyle(fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6A1B9A),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF6A1B9A),
                                    // borderRadius: const BorderRadius.only(
                                    //   bottomLeft: Radius.circular(20),
                                    //   bottomRight: Radius.circular(20),
                                    // ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFF6A1B9A),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Obx(() {
                                    final booking = controller
                                        .bookings[widget.currentIndex];

                                    return Switch(
                                      value: controller
                                          .bookings[widget.currentIndex]['mark_booked'],
                                      onChanged: (value) {
                                        // controller
                                        //     .bookings[widget.currentIndex]['mark_booked'] = value;

                                        widget.onBookedByOwner(
                                          booking['id'],
                                          value,
                                          widget.currentIndex,
                                        );
                                      },
                                      thumbColor: WidgetStateProperty.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Colors.green;
                                        }
                                        return Colors.grey;
                                      }),
                                      trackColor: WidgetStateProperty.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return const Color(0xFFFFFFFF);
                                        }
                                        return Colors.white;
                                      }),
                                    );
                                  }),),

                              // ElevatedButton.icon(
                              //   onPressed: widget.onDelete,
                              //   icon:
                              //       const Icon(Icons.delete_outline, size: 20),
                              //   label: const Text("Delete",
                              //       style: TextStyle(fontSize: 16)),
                              //   style: ElevatedButton.styleFrom(
                              //     backgroundColor: const Color(0xFF6A1B9A),
                              //     foregroundColor: Colors.white,
                              //     padding:
                              //         const EdgeInsets.symmetric(vertical: 14),
                              //     shape: RoundedRectangleBorder(
                              //       borderRadius: BorderRadius.circular(14),
                              //     ),
                              //     elevation: 3,
                              //   ),
                              // ),
                            ),
                          ],
                        ),

                      if (showEditDelete) const SizedBox(height: 12),
                    ],
                  ),
                ),

                // Bottom Status Bar (only for My Bookings tab)
                if (widget.isMyBookingTab && widget.booking['pp_id'] != null)
                  Container(
                    // height: 60,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      // border: Border.all(
                      //   color: const Color(0xFF6A1B9A),
                      //   width: 1.5,
                      // ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5.0,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        // crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          "$imageurl/${widget.booking['user_image']}",
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  // ✅ THIS IS THE MAIN FIX
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 3.0),
                                        child: Text(
                                          "${widget.booking['user_name']}",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 17),
                                          const SizedBox(width: 3),
                                          Expanded(
                                            // ✅ ALSO IMPORTANT
                                            child: Text(
                                              "City : ${widget.booking['user_city']} ",
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 1.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "PP ID: ${widget.booking['pp_id']}",
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.start,
                                  //   children: [
                                  //     Container(
                                  //       margin: EdgeInsets.only(left: 4,),
                                  //       height: 20,
                                  //       width: 3,
                                  //       color: Colors.black,
                                  //     ),
                                  //     SizedBox(width: 8.0,),
                                  //     Text(
                                  //       "8.5K Ratings",
                                  //       style: TextStyle(
                                  //         color: Colors.white,
                                  //         fontSize: 14,
                                  //         fontWeight: FontWeight.bold,
                                  //       ),
                                  //     ),
                                  //   ],
                                  // ),
                                  Row(
                                    children: [
                                      StarRating(
                                        size: 14.0,
                                        rating: 3.5,
                                        color: Colors.black,
                                        borderColor: Colors.black54,
                                        allowHalfRating: true,
                                        starCount: 5,
                                        // filledIcon: Icons.favorite,
                                        // halfFilledIcon: Icons.favorite_border,
                                        // emptyIcon: Icons.favorite_outline,
                                      ),
                                      SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                        "3.5",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 11,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Expired Overlay (Blur + Label) - Only for My Bookings tab
          if (widget.isMyBookingTab && isPast)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 15),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time_filled,
                              size: 80, color: Colors.white70),
                          SizedBox(height: 16),
                          Text(
                            "Expired Booking",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "This trip has passed",
                            style:
                                TextStyle(fontSize: 17, color: Colors.white70),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Swipe Gesture - Only for:
          // 1. My Bookings tab
          // 2. Not booked
          // 3. Not past
          if (widget.isMyBookingTab && !isBooked && !isPast)
            Container(
              // bottom: 0,
              // left: 0,
              // right: 0,
              height: 70,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double maxWidth = constraints.maxWidth - 60;

                  return GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragPosition += details.delta.dx;
                        if (_dragPosition < 0) _dragPosition = 0;
                        if (_dragPosition > maxWidth) _dragPosition = maxWidth;
                      });
                    },
                    onHorizontalDragEnd: (details) async {
                      if (_dragPosition > maxWidth * 0.8) {
                        bool confirmed = await _showMarkAsBookedDialog(
                            context, widget.booking);

                        if (confirmed) {
                          setState(() {
                            _isCompleted = true;
                          });
                        } else {
                          setState(() {
                            _dragPosition = 0;
                            _isCompleted = false;
                          });
                        }
                      } else {
                        setState(() {
                          _dragPosition = 0;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.only(left: 10),
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6A1B9A),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          /// Background Progress Fill
                          Container(
                            width: _dragPosition + 60,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6A1B9A).withOpacity(0.7),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                              ),
                            ),
                          ),

                          /// Center Text
                          Center(
                            child: Text(
                              _isCompleted
                                  ? "Booked ✓"
                                  : "Swipe to mark as booked ➜",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          /// Draggable Circle
                          Positioned(
                            left: _dragPosition,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_forward,
                                color: Color(0xFF6A1B9A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A1B9A),
            ),
          ),
        ],
      ),
    );
  }
}
