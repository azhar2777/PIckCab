import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../const/const.dart';

class ApiService {
  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    try {
      print('Fetching booking details for ID: $bookingId');
      final response = await http.get(
        Uri.parse('$appurl/booking/details?booking_id=$bookingId'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed data: $data');
        return data;
      } else {
        print('Failed with status: ${response.statusCode}');
        return {
          'status': false,
          'message': 'Server error: ${response.statusCode}'
        };
      }
    } catch (e) {
      print('Error fetching booking details: $e');
      return {'status': false, 'message': 'Network error: $e'};
    }
  }

  // Mock user details for testing (replace with actual API)
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    return {
      'status': true,
      'user': {
        'id': userId,
        'name': 'John Doe',
        'mobile': '9876543210',
        'email': 'john@example.com',
      }
    };
  }

  // Mock book trip (replace with actual API)
  Future<Map<String, dynamic>> bookTrip(String bookingId) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate API call

    return {
      'status': true,
      'message': 'Trip booked successfully!',
      'booking_id': bookingId,
    };
  }

  // Mock delete booking (replace with actual API)
  Future<Map<String, dynamic>> deleteBooking(String bookingId) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate API call

    return {
      'status': true,
      'message': 'Booking deleted successfully!',
    };
  }
}
