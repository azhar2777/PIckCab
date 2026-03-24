// // lib/my_bookings/my_booking_screen.dart
// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../includes/header.dart';
// import 'my_booking_controller.dart';

// class MyBookingScreen extends StatefulWidget {
//   const MyBookingScreen({super.key});

//   @override
//   State<MyBookingScreen> createState() => _MyBookingScreenState();
// }

// class _MyBookingScreenState extends State<MyBookingScreen> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       await MyBookingController.to.fetchFreeBookings();
//       await MyBookingController.to.fetchMyBookings();
//     });
//   }

//   void _showPostBottomSheet(BuildContext context) {
//     Get.bottomSheet(
//       SafeArea(
//         child: Container(
//           padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 50,
//                 height: 5,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 'Post',
//                 style: GoogleFonts.montserrat(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: const Color(0xFF6A1B9A),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               _buildOption(Icons.add_road, 'New Booking', () {
//                 Get.back();
//                 MyBookingController.to.onNewBooking();
//               }),
//               const SizedBox(height: 16),
//               _buildOption(Icons.directions_car, 'Free Vehicle', () {
//                 Get.back();
//                 MyBookingController.to.onFreeVehicle();
//               }),
//             ],
//           ),
//         ),
//       ),
//       isScrollControlled: true,
//     );
//   }

//   Widget _buildOption(IconData icon, String title, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
//         decoration: BoxDecoration(
//           color: Colors.grey.shade50,
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: Colors.grey.shade200),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, color: const Color(0xFF6A1B9A), size: 28),
//             const SizedBox(width: 20),
//             Text(
//               title,
//               style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
//             ),
//             const Spacer(),
//             const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showDeleteConfirmation(BuildContext context, String bookingId) {
//     Get.dialog(
//       AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Row(
//           children: [
//             Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
//             const SizedBox(width: 12),
//             const Text("Delete Booking?",
//                 style: TextStyle(fontWeight: FontWeight.bold)),
//           ],
//         ),
//         content: const Text("This action cannot be undone."),
//         actions: [
//           TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
//           ElevatedButton(
//             style:
//                 ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
//             onPressed: () async {
//               Get.back();
//               await MyBookingController.to.deleteBooking(bookingId);
//             },
//             child: const Text("Delete", style: TextStyle(color: Colors.white)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     Get.put(MyBookingController(), permanent: true);

//     return Scaffold(
//       appBar: AppHeader(),
//       backgroundColor: Colors.grey.shade50,
//       body: Obx(() {
//         final c = MyBookingController.to;

//         if (c.isLoading.value) {
//           return Center(
//               child: CircularProgressIndicator(color: const Color(0xFF6A1B9A)));
//         }

//         final availableBookings = c.bookings;
//         final freeBookings = c.freeBookings; // From new API

//         return DefaultTabController(
//           length: 2,
//           child: Column(
//             children: [
//               // Tab Bar with Counts
//               Container(
//                 color: Colors.white,
//                 child: TabBar(
//                   labelColor: const Color(0xFF6A1B9A),
//                   unselectedLabelColor: Colors.grey.shade600,
//                   indicatorColor: const Color(0xFF6A1B9A),
//                   labelStyle: const TextStyle(
//                       fontWeight: FontWeight.bold, fontSize: 15),
//                   tabs: [
//                     Tab(text: "My Booking (${availableBookings.length})"),
//                     Tab(text: "Free Vehicle (${freeBookings.length})"),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: TabBarView(
//                   children: [
//                     _buildBookingList(context, availableBookings, c,
//                         isFreeTab: false),
//                     _buildBookingList(context, freeBookings, c,
//                         isFreeTab: true),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       }),
//       bottomNavigationBar: _buildBottomNav(context),
//     );
//   }

//   Widget _buildBookingList(BuildContext context,
//       List<Map<String, dynamic>> bookings, MyBookingController c,
//       {required bool isFreeTab}) {
//     if (bookings.isEmpty) {
//       return RefreshIndicator(
//         onRefresh: c.fetchMyBookings,
//         child: _buildEmptyState(
//           isFreeTab ? "No free vehicle requests yet" : "No active trips yet",
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: c.fetchMyBookings,
//       color: const Color(0xFF6A1B9A),
//       child: ListView.builder(
//         padding: const EdgeInsets.all(5),
//         itemCount: bookings.length,
//         itemBuilder: (_, i) => BookingCard(
//           booking: bookings[i],
//           isFreeTab: isFreeTab,
//           onEdit: !isFreeTab
//               ? () => c.onEditBooking(bookings[i]['id'].toString())
//               : null,
//           onDelete: !isFreeTab
//               ? () =>
//                   _showDeleteConfirmation(context, bookings[i]['id'].toString())
//               : null,
//           onMarkAsBooked: (bookingId, unqId) async {
//             await c.markAsBooked(bookingId, unqId);
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState(String message) {
//     return LayoutBuilder(
//       builder: (_, constraints) => SingleChildScrollView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         child: SizedBox(
//           height: constraints.maxHeight,
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.directions_car,
//                     size: 90, color: Colors.grey.shade400),
//                 const SizedBox(height: 24),
//                 Text(
//                   'My Bookings',
//                   style: GoogleFonts.montserrat(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.grey.shade700),
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   message,
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.poppins(
//                       fontSize: 16, color: Colors.grey.shade600),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomNav(BuildContext context) {
//     return SafeArea(
//       child: SizedBox(
//         height: 60,
//         child: Stack(
//           clipBehavior: Clip.none,
//           alignment: Alignment.bottomCenter,
//           children: [
//             Container(
//               decoration: const BoxDecoration(
//                 color: Color.fromARGB(255, 254, 237, 255),
//                 borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//                 boxShadow: [
//                   BoxShadow(
//                       color: Colors.black12,
//                       blurRadius: 10,
//                       offset: Offset(0, -3))
//                 ],
//               ),
//               child: SafeArea(
//                 top: false,
//                 child: BottomNavigationBar(
//                   type: BottomNavigationBarType.fixed,
//                   backgroundColor: Colors.transparent,
//                   elevation: 0,
//                   selectedItemColor: const Color(0xFF6A1B9A),
//                   unselectedItemColor: Colors.grey.shade600,
//                   selectedFontSize: 10,
//                   unselectedFontSize: 10,
//                   showUnselectedLabels: true,
//                   currentIndex: 1,
//                   onTap: (i) {
//                     if (i == 0) MyBookingController.to.navigateToHome();
//                     if (i == 2) _showPostBottomSheet(context);
//                     if (i == 3) MyBookingController.to.navigateToAlerts();
//                     if (i == 4) MyBookingController.to.navigateToProfile();
//                   },
//                   items: const [
//                     BottomNavigationBarItem(
//                         icon: Icon(Icons.home), label: 'Home'),
//                     BottomNavigationBarItem(
//                         icon: Icon(Icons.bookmark_border),
//                         label: 'My Bookings'),
//                     BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
//                     BottomNavigationBarItem(
//                         icon: Icon(Icons.notifications_outlined),
//                         label: 'My Alerts'),
//                     BottomNavigationBarItem(
//                         icon: Icon(Icons.person_outline), label: 'Profile'),
//                   ],
//                 ),
//               ),
//             ),
//             Positioned(
//               child: GestureDetector(
//                 onTap: () => _showPostBottomSheet(context),
//                 child: Container(
//                   width: 68,
//                   height: 68,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: const LinearGradient(
//                         colors: [Color(0xFF7B2CAF), Color(0xFF5A189A)]),
//                     boxShadow: [
//                       BoxShadow(
//                           color: Color(0xFF6A1B9A).withOpacity(0.5),
//                           blurRadius: 20,
//                           offset: const Offset(0, 10))
//                     ],
//                   ),
//                   child: const Icon(Icons.add, color: Colors.white, size: 40),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _infoBox(String label, String value, Color bgColor) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF6A1B9A),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // New Stateful Widget for individual booking cards
// class BookingCard extends StatefulWidget {
//   final Map<String, dynamic> booking;
//   final bool isFreeTab;
//   final VoidCallback? onEdit;
//   final VoidCallback? onDelete;
//   final Function(String, String) onMarkAsBooked;

//   const BookingCard({
//     Key? key,
//     required this.booking,
//     required this.isFreeTab,
//     this.onEdit,
//     this.onDelete,
//     required this.onMarkAsBooked,
//   }) : super(key: key);

//   @override
//   State<BookingCard> createState() => _BookingCardState();
// }

// class _BookingCardState extends State<BookingCard> {
//   double _dragPosition = 0.0;
//   bool _isCompleted = false;

//   Future<bool> _showMarkAsBookedDialog(
//     BuildContext context,
//     Map<String, dynamic> booking,
//   ) async {
//     final ctrl = TextEditingController();
//     final bookingId = booking['id'].toString();
//     bool isProcessing = false;

//     return await showDialog<bool>(
//           context: context,
//           builder: (dialogContext) {
//             return StatefulBuilder(
//               builder: (context, setState) {
//                 return AlertDialog(
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(20)),
//                   title: const Text("Mark as Booked"),
//                   content: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       TextField(
//                         controller: ctrl,
//                         decoration: const InputDecoration(
//                           hintText: "User Unq ID",
//                         ),
//                         enabled: !isProcessing,
//                       ),
//                       if (isProcessing)
//                         const Padding(
//                           padding: EdgeInsets.only(top: 20),
//                           child: CircularProgressIndicator(),
//                         ),
//                     ],
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: isProcessing
//                           ? null
//                           : () => Navigator.of(dialogContext).pop(false),
//                       child: const Text("Cancel"),
//                     ),
//                     ElevatedButton(
//                       onPressed: isProcessing
//                           ? null
//                           : () async {
//                               setState(() => isProcessing = true);

//                               final unqId = ctrl.text.trim();
//                               if (unqId.isEmpty) {
//                                 setState(() => isProcessing = false);
//                                 return;
//                               }

//                               await widget.onMarkAsBooked(bookingId, unqId);
//                               if (mounted) {
//                                 Navigator.of(dialogContext).pop(true);
//                               }
//                             },
//                       child: const Text("Confirm"),
//                     ),
//                   ],
//                 );
//               },
//             );
//           },
//         ) ??
//         false;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool isPast = widget.booking['isPast'] as bool? ?? false;
//     final bool isBooked = widget.booking['status']?.toString() == '0';
//     final String? bookedBy = widget.booking['booked_by_unq_id']?.toString();
//     final String rate =
//         widget.booking['price'] != null ? "₹${widget.booking['price']}" : "";
//     final bool hasDestination =
//         (widget.booking['to']?.toString().trim().isNotEmpty ?? false);

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
//       child: Stack(
//         children: [
//           // Main Card
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: Colors.grey.shade300, width: 1.3),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.08),
//                   blurRadius: 12,
//                   offset: const Offset(0, 6),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Trip Type & Car Type

//                       const SizedBox(height: 18),

//                       Row(
//                         children: [
//                           Expanded(
//                               child: _infoBox(
//                                   "Car Type",
//                                   widget.booking['carType'] ?? "Sedan",
//                                   Colors.grey.shade100)),
//                           const SizedBox(width: 8),
//                           if (widget.isFreeTab)
//                             ...[]
//                           else
//                             Expanded(
//                                 child: _infoBox(
//                                     "Rate", rate, Colors.grey.shade100)),
//                         ],
//                       ),

//                       const SizedBox(height: 8),
//                       // From → To Location Row
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade100,
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(Icons.location_on,
//                                 size: 18, color: Color(0xFF6A1B9A)),
//                             const SizedBox(width: 10),
//                             if (widget.isFreeTab) ...[
//                               Text(
//                                 "Free In",
//                                 style: const TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.w600,
//                                     color: Color(0xFF6A1B9A)),
//                                 textAlign: TextAlign.center,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                               Expanded(
//                                 child: Text(
//                                   widget.booking['from'] ?? 'Location not set',
//                                   style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w600),
//                                   textAlign: TextAlign.center,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ] else
//                               Expanded(
//                                 child: Text(
//                                   widget.booking['from'] ?? 'Location not set',
//                                   style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w600),
//                                   textAlign: TextAlign.center,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             if (hasDestination) ...[
//                               const Icon(Icons.arrow_forward,
//                                   size: 22, color: Color(0xFF6A1B9A)),
//                               const SizedBox(width: 10),
//                               Expanded(
//                                 child: Text(
//                                   widget.booking['to'] ?? '',
//                                   style: const TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w600),
//                                   textAlign: TextAlign.center,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),

//                       const SizedBox(height: 18),

//                       // Date
//                       Row(
//                         children: [
//                           const Icon(Icons.calendar_today_rounded,
//                               size: 22, color: Colors.black87),
//                           const SizedBox(width: 10),
//                           Text(
//                             widget.booking['date'] ?? 'Date not set',
//                             style: const TextStyle(
//                               fontSize: 17,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ],
//                       ),

//                       // Remarks
//                       if ((widget.booking['remarks'] ?? '')
//                           .toString()
//                           .trim()
//                           .isNotEmpty)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 14),
//                           child: Text(
//                             widget.booking['remarks'],
//                             style: TextStyle(
//                               fontSize: 15,
//                               color: Colors.grey.shade700,
//                               fontStyle: FontStyle.italic,
//                               height: 1.4,
//                             ),
//                           ),
//                         ),

//                       const SizedBox(height: 10),

//                       // Edit & Delete Buttons (only for active non-free bookings)
//                       if (!widget.isFreeTab && !isPast)
//                         Row(
//                           children: [
//                             Expanded(
//                               child: ElevatedButton.icon(
//                                 onPressed: widget.onEdit,
//                                 icon: const Icon(Icons.edit_outlined, size: 20),
//                                 label: const Text("Edit",
//                                     style: TextStyle(fontSize: 16)),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF6A1B9A),
//                                   foregroundColor: Colors.white,
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 14),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(14),
//                                   ),
//                                   elevation: 3,
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 14),
//                             Expanded(
//                               child: ElevatedButton.icon(
//                                 onPressed: widget.onDelete,
//                                 icon:
//                                     const Icon(Icons.delete_outline, size: 20),
//                                 label: const Text("Delete",
//                                     style: TextStyle(fontSize: 16)),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: const Color(0xFF6A1B9A),
//                                   foregroundColor: Colors.white,
//                                   padding:
//                                       const EdgeInsets.symmetric(vertical: 14),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(14),
//                                   ),
//                                   elevation: 3,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),

//                       if (!widget.isFreeTab && !isPast)
//                         const SizedBox(height: 12),
//                     ],
//                   ),
//                 ),

//                 // Bottom Status Bar
//                 if (!widget.isFreeTab)
//                   Container(
//                     height: 45,
//                     width: double.infinity,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF6A1B9A),
//                       borderRadius: const BorderRadius.only(
//                         bottomLeft: Radius.circular(20),
//                         bottomRight: Radius.circular(20),
//                       ),
//                     ),
//                     child: Center(
//                       child: isBooked
//                           ? Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Icon(Icons.check_circle,
//                                     color: Colors.white, size: 20),
//                                 const SizedBox(width: 10),
//                                 Text(
//                                   "Booked by User ID: ${bookedBy ?? 'N/A'}",
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                               ],
//                             )
//                           : isPast
//                               ? const Text(
//                                   "Expired",
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 15,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 )
//                               : const SizedBox
//                                   .shrink(), // Hide default text when swipe is shown
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           // Expired Overlay (Blur + Label)
//           if (isPast)
//             ClipRRect(
//               borderRadius: BorderRadius.circular(20),
//               child: BackdropFilter(
//                 filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.3),
//                     borderRadius: BorderRadius.circular(20),
//                   ),
//                   child: const Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(Icons.access_time_filled,
//                             size: 80, color: Colors.white70),
//                         SizedBox(height: 16),
//                         Text(
//                           "Expired Booking",
//                           style: TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           "This trip has passed",
//                           style: TextStyle(fontSize: 17, color: Colors.white70),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),

//           // Swipe Gesture (only for active non-booked non-past)
//           if (!widget.isFreeTab && !isBooked && !isPast)
//             Positioned(
//               bottom: 0,
//               left: 0,
//               right: 0,
//               height: 64,
//               child: LayoutBuilder(
//                 builder: (context, constraints) {
//                   double maxWidth = constraints.maxWidth - 60;

//                   return GestureDetector(
//                     onHorizontalDragUpdate: (details) {
//                       setState(() {
//                         _dragPosition += details.delta.dx;
//                         if (_dragPosition < 0) _dragPosition = 0;
//                         if (_dragPosition > maxWidth) _dragPosition = maxWidth;
//                       });
//                     },
//                     onHorizontalDragEnd: (details) async {
//                       if (_dragPosition > maxWidth * 0.8) {
//                         bool confirmed = await _showMarkAsBookedDialog(
//                             context, widget.booking);

//                         if (confirmed) {
//                           setState(() {
//                             _isCompleted = true;
//                           });
//                         } else {
//                           setState(() {
//                             _dragPosition = 0;
//                             _isCompleted = false;
//                           });
//                         }
//                       } else {
//                         setState(() {
//                           _dragPosition = 0;
//                         });
//                       }
//                     },
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF6A1B9A),
//                         borderRadius: const BorderRadius.only(
//                           bottomLeft: Radius.circular(20),
//                           bottomRight: Radius.circular(20),
//                         ),
//                       ),
//                       child: Stack(
//                         alignment: Alignment.centerLeft,
//                         children: [
//                           /// 🔹 Background Progress Fill
//                           Container(
//                             width: _dragPosition + 60,
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF6A1B9A).withOpacity(0.7),
//                               borderRadius: const BorderRadius.only(
//                                 bottomLeft: Radius.circular(20),
//                               ),
//                             ),
//                           ),

//                           /// 🔹 Center Text
//                           Center(
//                             child: Text(
//                               _isCompleted
//                                   ? "Booked ✓"
//                                   : "Swipe to mark as booked ➜",
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),

//                           /// 🔹 Draggable Circle
//                           Positioned(
//                             left: _dragPosition,
//                             child: Container(
//                               width: 60,
//                               height: 60,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 shape: BoxShape.circle,
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black26,
//                                     blurRadius: 6,
//                                   ),
//                                 ],
//                               ),
//                               child: const Icon(
//                                 Icons.arrow_forward,
//                                 color: Color(0xFF6A1B9A),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _infoBox(String label, String value, Color bgColor) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade300),
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 14,
//               fontWeight: FontWeight.bold,
//               color: Color(0xFF6A1B9A),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
