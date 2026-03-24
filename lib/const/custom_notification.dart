import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomNotification {
  static void show({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    Get.showSnackbar(
      GetSnackBar(
        duration: const Duration(seconds: 2),
        animationDuration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        borderRadius: 10,
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        snackPosition: SnackPosition.BOTTOM,
        icon: Icon(
          isSuccess ? Icons.check_circle_outline : Icons.error_outline,
          color: Colors.white,
          size: 24,
        ),
        titleText: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        messageText: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        mainButton: TextButton(
          onPressed: () => Get.closeCurrentSnackbar(),
          child: const Text(
            'OK',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
