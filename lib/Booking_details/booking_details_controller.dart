import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pickcab_partner/utils/Utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'services/api_service.dart';

class BookingDetailsController extends GetxController {
  // Observable variables
  var isLoading = true.obs;
  var bookingDetails = <String, dynamic>{}.obs;
  var userData = <String, dynamic>{}.obs;

  // Initialize with booking data

  // Fetch booking details from API
  Future<void> fetchBookingDetails(String bookingId) async {
    try {
      isLoading.value = true;
      final response = await ApiService().getBookingDetails(bookingId);

      if (response['status'] == true) {
        final bookingResponse = response['details'];
        bookingDetails.value =
            Map<String, dynamic>.from(bookingResponse['booking']);
        userData.value = Map<String, dynamic>.from(bookingResponse['user']);
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

  Future<void> openWhatsApp_old() async {
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

  Future<void> openWhatsApp2() async {
    print("openWhatsApp");
    final booking = bookingDetails.value;
    final phone = getUserMobile();
    Utils.getWhatsappShareMesage(true, phone, booking);
  }

  Future<void> openWhatsApp() async {

    final booking = bookingDetails.value;
    final phone = getUserMobile();


    String cleaned = phone.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length == 10) {
      cleaned = "91$cleaned";
    }

    if (cleaned.length != 12) {
      Get.snackbar(
        "Invalid Phone Number",
        "Please check the contact number and try again.",
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final from = booking['start_location'] ?? 'Unknown';
    final to = booking['end_location'] ?? 'Unknown';
    final date = formatTripDate(booking['trip_date']);
    final time = booking['trip_time'] ?? '';


    String formattedTime = '';

    if (time.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(time);
        formattedTime = DateFormat('hh:mm a').format(dateTime);
      } catch (e) {
        print("formattedTime error");
        formattedTime = time;
      }
    }

    final String pickupTime = "$date, $formattedTime";
    final carType = booking['car_type'] ?? 'Car';
    final price =
    booking['price'] != null ? "₹${booking['price']}" : "Contact for price";
    final tripType =
    (booking['trip_type'] == 'round_trip') ? 'Round Trip' : 'One Way';

    const String appLink =
        "https://play.google.com/store/apps/details?id=com.pickcab.partner";

    String text = "";

    text += "Dear Sir/Ma'am,";
    text += "\n😊am interested, Kripya aage ki jankari pradan karein";
    text += "\n\nPickup:- " + from;
    text += "\nDrop:- " + to;
    text += "\nTrip Type:- " + tripType;
    text += "\nVehicle:- " + carType;
    text += "\nPickup Time:- " + pickupTime;
    text += "\nRate :- " + price;

    if (booking['remarks'] != null && booking['remarks'] != "No remarks") {
      text += "\n\n\nMessage:- " + booking['remarks'];
    }
    text += "\n\nPickCab Partner AAP 📱 download link ";
    text += "\n👇🏼";
    text += "\n" + appLink;

    print(text);

    final String encodedMessage = Uri.encodeComponent(text.trim());
    final Uri uri = Uri.parse("https://wa.me/$cleaned?text=$encodedMessage");

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      Get.snackbar(
        "Unable to Open WhatsApp",
        "Please make sure WhatsApp is installed or try again later.\nError: $e",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Share booking
  Future<void> shareBooking2() async {
    final booking = bookingDetails.value;
    Utils.getShareMessage(true, booking);
  }
  Future<void> shareBooking() async {
    final booking = bookingDetails.value;
    final from = booking['start_location'] ?? 'Unknown';
    final to = booking['end_location'] ?? 'Unknown';
    final date = formatTripDate(booking['trip_date']);
    final time = booking['trip_time'] ?? '';


    String formattedTime = '';

    if (time.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(time);
        formattedTime = DateFormat('hh:mm a').format(dateTime);
      } catch (e) {
        print("formattedTime error");
        formattedTime = time;
      }
    }

    final String pickupTime = "$date, $formattedTime";
    final carType = booking['car_type'] ?? 'Car';
    final price =
        booking['price'] != null ? "₹${booking['price']}" : "Contact for price";
    final tripType =
        (booking['trip_type'] == 'round_trip') ? 'Round Trip' : 'One Way';
    // final tripId = booking['trip_id'] ?? '';
    // final remarks = booking['remarks'] ?? '';
    // final userName = getUserName();
    // final userMobile = getUserMobile();

    const String appLink =
        "https://play.google.com/store/apps/details?id=com.pickcab.partner";
    String text = "";
    text += "\n😊New Booking Available in PickCab Partner Application";
    text += "\n\nPickup:- " + from;
    text += "\nDrop:- " + to;
    text += "\nTrip Type:- " + tripType;
    text += "\nVehicle:- " + carType;
    text += "\nPickup Time:- " + pickupTime;
    text += "\nRate :- " + price;

    if (booking['remarks'] != null && booking['remarks'] != "No remarks") {
      text += "\n\n\nMessage:- " + booking['remarks'];
    }

    text += "\n\nPickCab Partner AAP 📱 download link ";
    text += "\n👇🏼";
    text += "\n" + appLink;

    print(text);

    try {
      await Share.share(text, subject: "Ride from ${booking['from']}");
    } catch (e) {
      Get.snackbar(
        "Unable Share booking",
        "\nError: $e",
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
      );
    }


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
