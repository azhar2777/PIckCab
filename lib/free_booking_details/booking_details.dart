import 'package:flutter/material.dart';

class BookingDetailsPage extends StatelessWidget {
  final String bookingId;

  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking Details")),
      body: Center(
        child: Text(
          "Booking ID: $bookingId",
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
