import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/snackbar/snackbar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  static Future<void> getShareMessage(bool isBooking, Map<String, dynamic> booking) async {
    print("isBooking $isBooking");
    print(booking);

    final String tripType =
    (booking['isTwoWay'] == true || booking['isTwoWay'] == "1")
        ? "ROUND TRIP"
        : "ONEWAY";

    final String date = booking['date']?.toString() ?? 'N/A';
    final String time = booking['time']?.toString() ?? 'N/A';
    final String pickupTime = "$date, $time";
    final String rate =
    booking['price'] != null ? "₹ ${booking['price']}" : "N/A";

    const String appLink =
        "https://play.google.com/store/apps/details?id=com.pickcab.partner";
    String text = "";

    if(isBooking){
      text += "\n😊New Booking Available in PickCab Partner Application";
      text += "\n\nPickup:- " + (booking['from']?.toString() ?? 'Unknown');
      text += "\nDrop:- " + (booking['to']?.toString() ?? 'Unknown');
      text += "\nTrip Type:- " + tripType;
      text += "\nVehicle:- " + (booking['carType']?.toString() ?? 'Sedan');
      text += "\nPickup Time:- " + pickupTime;
      text += "\nRate :- " + rate;

      if (booking['remarks'] != null && booking['remarks'] != "No remarks") {
        text += "\n\n\nMessage:- " + booking['remarks'];
      }


    }
    else{
      text += "Vehicle Free in: " + (booking['from']?.toString() ?? 'Unknown');
      text += "\nVehicle:- " + (booking['carType']?.toString() ?? 'Sedan');
      text += "\nTime:- " + pickupTime;


    }

    text += "\n\nPickCab Partner AAP 📱 download link ";
    text += "\n👇🏼";
    text += "\n" + appLink;





    // print(text);

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

  static Future<void> getWhatsappShareMesage(
      bool isBooking,
      String phone, Map<String, dynamic> booking) async {
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

    final String tripType =
        (booking['isTwoWay'] == true || booking['isTwoWay'] == "1")
            ? "ROUND TRIP"
            : "ONEWAY";

    final String date = booking['date']?.toString() ?? 'N/A';
    final String time = booking['time']?.toString() ?? 'N/A';
    final String pickupTime = "$date, $time";
    final String rate =
        booking['price'] != null ? "₹ ${booking['price']}" : "N/A";

    const String appLink =
        "https://play.google.com/store/apps/details?id=com.pickcab.partner";
    String text = "";

    if(isBooking){
      text += "Dear Sir/Ma'am,";
      text += "\n😊am interested, Kripya aage ki jankari pradan karein";
      text += "\n\nPickup:- " + (booking['from']?.toString() ?? 'Unknown');
      text += "\nDrop:- " + (booking['to']?.toString() ?? 'Unknown');
      text += "\nTrip Type:- " + tripType;
      text += "\nVehicle:- " + (booking['carType']?.toString() ?? 'Sedan');
      text += "\nPickup Time:- " + pickupTime;
      text += "\nRate :- " + rate;

      if (booking['remarks'] != null && booking['remarks'] != "No remarks") {
        text += "\n\n\nMessage:- " + booking['remarks'];
      }
    }
    else{
      text += "\nVehicle Free in: " + (booking['from']?.toString() ?? 'Unknown');
      text += "\nVehicle:- " + (booking['carType']?.toString() ?? 'Sedan');
      text += "\nTime:- " + pickupTime;
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
}
