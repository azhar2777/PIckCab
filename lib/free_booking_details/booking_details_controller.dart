import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'services/api_service.dart';

class FreeBookingDetailsController extends GetxController {
  // Observable variables
  var isLoading = true.obs;
  var bookingDetails = <String, dynamic>{}.obs;
  var userData = <String, dynamic>{}.obs;

  // Initialize with booking data
  void initialize(Map<String, dynamic> booking, Map<String, dynamic>? user) {
    bookingDetails.value = Map<String, dynamic>.from(booking);
    userData.value = user != null ? Map<String, dynamic>.from(user) : {};
    isLoading.value = false;
  }

  // Fetch booking details from API
  Future<void> fetchBookingDetails(String bookingId) async {
    try {
      isLoading.value = true;
      final response = await ApiServiceFree().getBookingDetails(bookingId);

      if (response['status'] == true) {
        // final bookingResponse = response['booking'];
        bookingDetails.value = Map<String, dynamic>.from(response['booking']);
        userData.value = Map<String, dynamic>.from(response['user']);
      } else {
        Get.snackbar('Error', 'Failed to load booking details');
      }
    } catch (e) {
      Get.snackbar('Error', 'Something went wrong: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Get user mobile number
  String getUserMobile() {
    return userData['user_mobile']?.toString() ?? '';
  }

  // Get user name
  String getUserName() {
    return userData['user_name']?.toString() ?? 'Not available';
  }

  // Get user image
  // String getUserImage() {
  //   final image = userData['user_image']?.toString();
  //   if (image != null && image.isNotEmpty) {
  //     return 'https://guplfx.com/pickcab/public/uploads/user_images/$image';
  //   }
  //   return '';
  // }

  // Check if user is verified
  bool isUserVerified() {
    final aadharVerified = userData['aadhar_verified']?.toString() == "1";
    final dlVerified = userData['dl_verified']?.toString() == "1";
    return aadharVerified || dlVerified;
  }

  // Make phone call
  Future<void> makePhoneCall() async {
    final phoneNumber = getUserMobile();
    if (phoneNumber.isEmpty) {
      Get.snackbar('Error', 'Phone number not available');
      return;
    }

    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      Get.snackbar('Error', 'Could not launch phone app');
    }
  }

  // Open WhatsApp
  // Future<void> openWhatsApp() async {
  //   final phoneNumber = getUserMobile();
  //   if (phoneNumber.isEmpty) {
  //     Get.snackbar('Error', 'Phone number not available');
  //     return;
  //   }

  //   // Clean phone number
  //   String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
  //   if (cleanNumber.startsWith('91')) {
  //     cleanNumber = cleanNumber.substring(2);
  //   } else if (cleanNumber.startsWith('0')) {
  //     cleanNumber = cleanNumber.substring(1);
  //   }

  //   final url = 'https://wa.me/91$cleanNumber';
  //   if (await canLaunch(url)) {
  //     await launch(url);
  //   } else {
  //     Get.snackbar('Error', 'WhatsApp not installed');
  //   }
  // }

  Future<void> openWhatsApp() async {
    final phoneNumber = getUserMobile();
    String cleaned = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length == 10) cleaned = "91$cleaned";

    if (cleaned.length != 12) {
      Get.snackbar(
        "Invalid Number",
        "Cannot open WhatsApp with this number",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    final Uri uri = Uri.parse("https://wa.me/$cleaned");

    // 👉 DO NOT USE canLaunchUrl FOR HTTPS
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      Get.snackbar(
        "Error",
        "Unable to open WhatsApp",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
    }
  }

  // Share booking
  Future<void> shareBooking() async {
    final booking = bookingDetails.value;
    final from = booking['start_location'] ?? 'Unknown';
    final to = booking['end_location'] ?? 'Unknown';
    final date = formatTripDate(booking['trip_date']);
    final time = booking['trip_time'] ?? '';
    final carType = booking['car_type'] ?? 'Car';
    final price =
        booking['price'] != null ? "₹${booking['price']}" : "Contact for price";
    final tripType =
        (booking['trip_type'] == 'round_trip') ? 'Round Trip' : 'One Way';
    final tripId = booking['trip_id'] ?? '';
    final remarks = booking['remarks'] ?? '';
    final userName = getUserName();
    final userMobile = getUserMobile();

    final shareText = """
Dear Sir/Ma'am,

PP par prapt hui aapki lead mein meri ruchi hai. Kripya aage ki jankari pradan karein.

Trip ID: $tripId
Date: $date @ $time
From: $from
To: $to
Trip Type: $tripType
Car: $carType
Rate: $price
${remarks.isNotEmpty && remarks.toLowerCase() != 'no remarks' ? "\nNote: $remarks" : ''}

Contact: $userName - $userMobile

PP (PICKCAB PARTNER) app download link
https://play.google.com/store/apps/....
    """
        .trim();

    Share.share(shareText, subject: "Ride from $from to $to");
  }

  // Format date
  String formatTripDate(dynamic date) {
    if (date == null) return 'N/A';

    try {
      if (date is String) {
        final parts = date.split('-');
        if (parts.length == 3) {
          return '${parts[2]}-${parts[1]}-${parts[0]}';
        }
        return date;
      }
      return date.toString();
    } catch (e) {
      return 'Invalid Date';
    }
  }

  // Time ago calculation
  String timeAgo(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() > 1 ? 's' : ''} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  // Mask mobile numbers in text
  String maskMobileNumbers(String text) {
    final RegExp mobileRegex = RegExp(
      r'\b(?:\+91|91|0)?[6-9]\d{9}\b',
    );

    return text.replaceAllMapped(mobileRegex, (Match match) {
      String number = match.group(0)!;

      // Normalize to clean 10-digit number
      if (number.startsWith('+91')) {
        number = number.substring(3);
      } else if (number.startsWith('91')) {
        number = number.substring(2);
      } else if (number.startsWith('0')) {
        number = number.substring(1);
      }

      // If it's a valid 10-digit number, mask it
      if (number.length == 10) {
        return '**********';
      }

      return match.group(0)!;
    });
  }

  // Check if WhatsApp allowed
  bool canSendWhatsApp() {
    return bookingDetails['send_whatsapp']?.toString() == "1";
  }

  // Check if Call allowed
  bool canSendCall() {
    return bookingDetails['send_call']?.toString() == "1";
  }

  // Check if carrier needed
  bool needsCarrier() {
    return bookingDetails['carrier']?.toString() == "1";
  }

  // Check if booking is available
  bool isBooked() {
    return bookingDetails['status']?.toString() == "0";
  }

  // Get price display
  String getPriceDisplay() {
    final price = bookingDetails['price'];
    final priceType = bookingDetails['price_type'];

    if (price != null && price.toString().isNotEmpty) {
      if (priceType == 'fixed') {
        return '₹$price (Fixed)';
      } else if (priceType == 'negotiable') {
        return '₹$price (Negotiable)';
      }
      return '₹$price';
    } else {
      return 'Contact for price';
    }
  }
}
