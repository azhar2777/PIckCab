import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pickcab_partner/smartbooking/SmartBookingScreen.dart';
import 'package:pickcab_partner/utils/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../../const/const.dart';
import '../../const/custom_notification.dart';
import '../freebooking/freebooking_new.dart';
import '../login/login_screen.dart';
import '../my_bookings/my_booking_screen.dart';
import '../alerts/alerts_screen.dart';
import '../profile/profile_screen.dart';
import '../new_booking/new_booking_screen.dart';
import '../../services/notification_service.dart';

class HomeController extends GetxController {
  // Bookings Data
  final RxList<Map<String, dynamic>> bookings = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> freebookings =
      <Map<String, dynamic>>[].obs;

  // UI States
  final RxBool isApiCalled = true.obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString searchQuery = ''.obs;
  final RxInt selectedTab = 0.obs;

  // Auto-removal timers
  Timer? _cleanupTimer;
  final Map<String, Timer> _pendingRemovalTimers = {};

  // Track removed bookings to prevent them from reappearing
  final Set<String> _removedBookingIds = <String>{};
  final Set<String> _removedFreeBookingIds = <String>{};

  // Track when bookings were removed
  final Map<String, DateTime> _removedBookingsExpiry = {};

  // CITY SEARCH
  final RxList<String> allCities = <String>[].obs;
  final RxList<String> filteredCities = <String>[].obs;
  final RxBool isCitiesLoading = true.obs;



  @override
  void onInit() {
    super.onInit();
    fetchIndianCities();
    _startAutoCleanupTimer();
    _loadRemovedBookings(); // Load previously removed bookings

  }

  @override
  void onReady() {
    super.onReady();
    NotificationService.updateTokenAfterLogin();
    callAllFunctions();
  }

  void callAllFunctions() async {
    try{
      isApiCalled.value = false;
      await fetchAvailableBookings();
      await fetchAvailablefreeBookings();
    }
    catch (e) {
      debugPrint("callAllFunctions error: $e");

    } finally {
      isApiCalled.value = true;

    }

  }

  @override
  void onClose() {
    _cleanupTimer?.cancel();
    _cancelAllPendingRemovalTimers();
    _saveRemovedBookings(); // Save removed bookings before closing
    super.onClose();
  }



  // ==================== PERSISTENCE METHODS ====================

  /// Load removed bookings from SharedPreferences
  Future<void> _loadRemovedBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load regular removed bookings
      final String? removedBookingsJson = prefs.getString('removed_bookings');
      if (removedBookingsJson != null) {
        final List<dynamic> list = jsonDecode(removedBookingsJson);
        _removedBookingIds.addAll(list.map((e) => e.toString()));
      }

      // Load free removed bookings
      final String? removedFreeBookingsJson =
          prefs.getString('removed_free_bookings');
      if (removedFreeBookingsJson != null) {
        final List<dynamic> list = jsonDecode(removedFreeBookingsJson);
        _removedFreeBookingIds.addAll(list.map((e) => e.toString()));
      }

      // Load removed bookings expiry times
      final String? removedExpiryJson =
          prefs.getString('removed_bookings_expiry');
      if (removedExpiryJson != null) {
        final Map<String, dynamic> map = jsonDecode(removedExpiryJson);
        map.forEach((key, value) {
          _removedBookingsExpiry[key] = DateTime.parse(value.toString());
        });
      }

      debugPrint(
          "📦 Loaded ${_removedBookingIds.length} removed bookings and ${_removedFreeBookingIds.length} removed free bookings");
    } catch (e) {
      debugPrint("❌ Error loading removed bookings: $e");
    }
  }

  /// Save removed bookings to SharedPreferences
  Future<void> _saveRemovedBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clean up old entries (older than 24 hours)
      final now = DateTime.now();
      _removedBookingsExpiry.removeWhere((key, expiryTime) {
        if (now.difference(expiryTime).inHours > 24) {
          _removedBookingIds.remove(key);
          _removedFreeBookingIds.remove(key);
          return true;
        }
        return false;
      });

      // Save regular removed bookings
      await prefs.setString(
          'removed_bookings', jsonEncode(_removedBookingIds.toList()));

      // Save free removed bookings
      await prefs.setString(
          'removed_free_bookings', jsonEncode(_removedFreeBookingIds.toList()));

      // Save expiry times
      final expiryMap = <String, String>{};
      _removedBookingsExpiry.forEach((key, value) {
        expiryMap[key] = value.toIso8601String();
      });
      await prefs.setString('removed_bookings_expiry', jsonEncode(expiryMap));

      debugPrint(
          "📦 Saved ${_removedBookingIds.length} removed bookings and ${_removedFreeBookingIds.length} removed free bookings");
    } catch (e) {
      debugPrint("❌ Error saving removed bookings: $e");
    }
  }

  /// Mark a booking as permanently removed
  void _markAsRemoved(String bookingId, bool isFreeBooking) {
    if (isFreeBooking) {
      _removedFreeBookingIds.add(bookingId);
    } else {
      _removedBookingIds.add(bookingId);
    }
    _removedBookingsExpiry[bookingId] =
        DateTime.now().add(const Duration(hours: 24));
    _saveRemovedBookings(); // Save immediately
  }

  /// Check if a booking was previously removed
  bool _isBookingRemoved(String bookingId, bool isFreeBooking) {
    if (isFreeBooking) {
      return _removedFreeBookingIds.contains(bookingId);
    } else {
      return _removedBookingIds.contains(bookingId);
    }
  }

  // ==================== AUTO-REMOVAL METHODS ====================

  /// Start periodic cleanup timer (every 60 seconds)
  void _startAutoCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _removeExpiredAndBookedBookings();
      _cleanupExpiredRemovedEntries();
    });
  }

  /// Clean up expired removed entries
  void _cleanupExpiredRemovedEntries() {
    final now = DateTime.now();
    final List<String> expiredIds = [];

    _removedBookingsExpiry.removeWhere((key, expiryTime) {
      if (now.isAfter(expiryTime)) {
        expiredIds.add(key);
        return true;
      }
      return false;
    });

    for (var id in expiredIds) {
      _removedBookingIds.remove(id);
      _removedFreeBookingIds.remove(id);
    }

    if (expiredIds.isNotEmpty) {
      _saveRemovedBookings();
      debugPrint("🧹 Cleaned up ${expiredIds.length} expired removed entries");
    }
  }

  /// Cancel all pending removal timers
  void _cancelAllPendingRemovalTimers() {
    for (var timer in _pendingRemovalTimers.values) {
      timer.cancel();
    }
    _pendingRemovalTimers.clear();
  }

  /// Remove expired and booked bookings automatically
  void _removeExpiredAndBookedBookings() {
    final now = DateTime.now();
    final List<String> bookingsToRemove = [];
    final List<String> freeBookingsToRemove = [];

    // Check regular bookings
    for (var booking in bookings) {
      // print("bookingItem "+booking['id']);
      final String bookingId = booking['id'].toString();

      // Skip if already marked as removed
      if (_isBookingRemoved(bookingId, false)) {
        bookingsToRemove.add(bookingId);
        continue;
      }

      final bool isBooked = (booking['status']?.toString() ?? "") == "0";

      if (isBooked) {
        // Get the booking date time and check if 10 minutes have passed
        final DateTime? removalTime = _getBookingRemovalTime(booking);
        if (removalTime != null && now.isAfter(removalTime)) {
          bookingsToRemove.add(bookingId);
          _markAsRemoved(bookingId, false);
          debugPrint(
              "🔄 Auto-removing booked booking ID: $bookingId - Booked at: ${booking['bookingdate_time']}");
        }
      }

      // For expired bookings (based on trip time)
      final bool isExpired = isBookingExpired(booking);
      // print("isExpired ${booking['id']} and $isExpired status");
      if (isExpired) {
        final DateTime? removalTime = _getExpiryRemovalTime(booking);
        // print("removalTime ${booking['id']} and time ${booking['time']} removalTime $removalTime min");
        if (removalTime != null && now.isAfter(removalTime)) {
          bookingsToRemove.add(bookingId);
          _markAsRemoved(bookingId, false);
          debugPrint(
              "🔄 Auto-removing expired booking ID: $bookingId - Trip time expired");
        }
      }
    }

    // Check free bookings
    for (var booking in freebookings) {
      final String bookingId = booking['id'].toString();

      // Skip if already marked as removed
      if (_isBookingRemoved(bookingId, true)) {
        freeBookingsToRemove.add(bookingId);
        continue;
      }

      final bool isBooked = (booking['status']?.toString() ?? "") == "0";
      final bool isExpired = isFreeBookingExpired(booking);

      if (isBooked || isExpired) {
        final DateTime? removalTime = _getRemovalTime(booking, isExpired);
        if (removalTime != null && now.isAfter(removalTime)) {
          freeBookingsToRemove.add(bookingId);
          _markAsRemoved(bookingId, true);
          debugPrint(
              "🔄 Auto-removing free booking ID: $bookingId - ${isExpired ? 'Expired' : 'Booked'}");
        }
      }
    }

    // Remove identified bookings
    if (bookingsToRemove.isNotEmpty) {
      bookings
          .removeWhere((b) => bookingsToRemove.contains(b['id'].toString()));
    }

    if (freeBookingsToRemove.isNotEmpty) {
      freebookings.removeWhere(
          (b) => freeBookingsToRemove.contains(b['id'].toString()));
    }
  }

  /// Get the removal time for booked bookings based on bookingdate_time + 10 minutes
  DateTime? _getBookingRemovalTime(Map<String, dynamic> booking) {
    try {
      final String bookingDateTimeStr =
          booking['bookingdate_time']?.toString() ?? '';

      if (bookingDateTimeStr.isNotEmpty && bookingDateTimeStr != 'N/A') {
        // Parse the booking date time (format: "2026-02-11 09:47:10")
        final DateTime bookingDateTime = DateTime.parse(bookingDateTimeStr);
        // Add 10 minutes for removal delay
        return bookingDateTime.add(const Duration(minutes: 120));
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error calculating booked booking removal time: $e");
      return null;
    }
  }

  /// Get the removal time for expired bookings based on trip time + 30 min + 10 min delay
  DateTime? _getExpiryRemovalTime(Map<String, dynamic> booking) {
    try {
      if (booking.containsKey('date') && booking.containsKey('time')) {
        final String dateStr = booking['date']?.toString() ?? '';
        final String timeStr = booking['time']?.toString() ?? '';

        if (dateStr.isNotEmpty && dateStr != 'N/A' && dateStr != 'Any Day') {
          if (dateStr.contains('-')) {
            final dateParts = dateStr.split('-');
            if (dateParts.length == 3) {
              final year = int.parse(dateParts[0]);
              final month = int.parse(dateParts[1]);
              final day = int.parse(dateParts[2]);

              int hour = 0, minute = 0;
              final timeParsed = parseTime(timeStr);
              if (timeParsed != null) {
                hour = timeParsed.$1;
                minute = timeParsed.$2;
              }

              final tripDateTime = DateTime(year, month, day, hour, minute);
              // Add 30 minutes for expiry + 10 minutes for removal delay
              return tripDateTime.add(const Duration(minutes: 40));
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error calculating expiry removal time: $e");
      return null;
    }
  }

  /// Get the removal time for free bookings
  DateTime? _getRemovalTime(Map<String, dynamic> booking, bool isExpired) {
    try {
      if (booking.containsKey('endTimeStr')) {
        final String timeStr = booking['endTimeStr']?.toString() ?? '';
        if (timeStr.isNotEmpty && timeStr != 'Any Time') {
          final tripDateTime = DateTime.parse(timeStr);
          // Add 30 minutes for expiry + 10 minutes for removal delay
          return tripDateTime.add(const Duration(minutes: 40));
        }
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error calculating removal time: $e");
      return null;
    }
  }

  /// Schedule removal of a specific booking after delay based on bookingdate_time
  void scheduleBookingRemoval(
      String bookingId, String bookingDateTimeStr, bool isFreeBooking) {
    try {
      // Parse the booking date time
      final DateTime bookingDateTime = DateTime.parse(bookingDateTimeStr);
      final DateTime removalTime =
          bookingDateTime.add(const Duration(minutes: 120));
      final now = DateTime.now();

      // Calculate delay until removal
      final Duration delay = removalTime.difference(now);

      // Cancel any existing timer for this booking
      if (_pendingRemovalTimers.containsKey(bookingId)) {
        _pendingRemovalTimers[bookingId]?.cancel();
      }

      if (delay.isNegative) {
        // If removal time has already passed, remove immediately
        if (isFreeBooking) {
          freebookings.removeWhere((b) => b['id'].toString() == bookingId);
          _markAsRemoved(bookingId, true);
          debugPrint(
              "✅ Free booking $bookingId removed immediately (past removal time)");
        }
        else {
          bookings.removeWhere((b) => b['id'].toString() == bookingId);
          _markAsRemoved(bookingId, false);
          debugPrint(
              "✅ Booking $bookingId removed immediately (past removal time)");
        }
      } else {
        // Schedule removal after delay
        debugPrint(
            "⏱️ Scheduling removal for booking $bookingId in ${delay.inMinutes} minutes (at ${removalTime.toString()})");

        _pendingRemovalTimers[bookingId] = Timer(delay, () {
          if (isFreeBooking) {
            freebookings.removeWhere((b) => b['id'].toString() == bookingId);
            _markAsRemoved(bookingId, true);
            debugPrint(
                "✅ Free booking $bookingId removed after scheduled delay");
          } else {
            bookings.removeWhere((b) => b['id'].toString() == bookingId);
            _markAsRemoved(bookingId, false);
            debugPrint("✅ Booking $bookingId removed after scheduled delay");
          }
          _pendingRemovalTimers.remove(bookingId);
        });
      }
    } catch (e) {
      debugPrint("❌ Error scheduling booking removal: $e");
    }
  }

  /// Check if a booking is newly booked and schedule removal based on bookingdate_time
  void checkAndScheduleRemoval(
      Map<String, dynamic> booking, bool isFreeBooking) {
    final String bookingId = booking['id'].toString();

    // Skip if already marked as removed
    if (_isBookingRemoved(bookingId, isFreeBooking)) {
      return;
    }

    final bool isBooked = (booking['status']?.toString() ?? "") == "0";

    if (isBooked) {
      final String bookingDateTimeStr =
          booking['bookingdate_time']?.toString() ?? '';
      if (bookingDateTimeStr.isNotEmpty) {
        scheduleBookingRemoval(bookingId, bookingDateTimeStr, isFreeBooking);
      }
    }
  }

  // ==================== PUBLIC TIME PARSING METHODS ====================

  /// Parse time string in various formats to hour and minute - PUBLIC METHOD
  (int hour, int minute)? parseTime(String timeStr) {
    try {
      if (timeStr.isEmpty || timeStr == 'N/A' || timeStr == 'Any Time') {
        return null;
      }

      String cleanTime = timeStr.trim().toUpperCase();
      int hour = 0;
      int minute = 0;

      // Handle 12-hour format with AM/PM (e.g., "5:13 PM", "10:30AM")
      if (cleanTime.contains('AM') || cleanTime.contains('PM')) {
        final isPM = cleanTime.contains('PM');
        cleanTime = cleanTime.replaceAll('AM', '').replaceAll('PM', '').trim();

        if (cleanTime.contains(':')) {
          final parts = cleanTime.split(':');
          hour = int.tryParse(parts[0]) ?? 0;
          minute = int.tryParse(parts[1]) ?? 0;

          // Convert to 24-hour format
          if (isPM && hour != 12) hour += 12;
          if (!isPM && hour == 12) hour = 0;
        }
      }
      // Handle 24-hour format (e.g., "17:13", "09:30")
      else if (cleanTime.contains(':')) {
        final parts = cleanTime.split(':');
        hour = int.tryParse(parts[0]) ?? 0;
        minute = int.tryParse(parts[1]) ?? 0;
      }
      // Handle compact format (e.g., "1713", "0930")
      else if (cleanTime.length >= 4) {
        hour = int.tryParse(cleanTime.substring(0, 2)) ?? 0;
        minute = int.tryParse(cleanTime.substring(2, 4)) ?? 0;
      }
      // Handle single hour (e.g., "5", "17")
      else if (cleanTime.length <= 2) {
        hour = int.tryParse(cleanTime) ?? 0;
        minute = 0;
      }

      return (hour, minute);
    } catch (e) {
      debugPrint("❌ Time parsing error: $e for time: $timeStr");
      return null;
    }
  }

  // ==================== EXPIRATION CHECK METHODS - PUBLIC ====================

  /// Check if a regular booking is expired (trip date + time + 30 minutes) - PUBLIC METHOD
  bool isBookingExpired(Map<String, dynamic> booking) {
    try {
      final String dateStr = booking['date']?.toString() ?? '';
      final String timeStr = booking['time']?.toString() ?? '';

      if (dateStr.isEmpty || dateStr == 'N/A' || dateStr == 'Any Day') {
        return false;
      }

      // Parse date (expecting YYYY-MM-DD format)
      if (!dateStr.contains('-')) return false;

      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) return false;

      final year = int.tryParse(dateParts[0]) ?? 0;
      final month = int.tryParse(dateParts[1]) ?? 0;
      final day = int.tryParse(dateParts[2]) ?? 0;

      if (year == 0 || month == 0 || day == 0) return false;

      // Parse time
      int hour = 0, minute = 0;
      if (timeStr.isNotEmpty && timeStr != 'N/A' && timeStr != 'Any Time') {
        final timeParsed = parseTime(timeStr);
        if (timeParsed != null) {
          hour = timeParsed.$1;
          minute = timeParsed.$2;
        }
      }

      // Create DateTime object
      final tripDateTime = DateTime(year, month, day, hour, minute);
      final expiryTime = tripDateTime.add(const Duration(minutes: 30));
      final now = DateTime.now();

      return now.isAfter(expiryTime);
    } catch (e) {
      debugPrint("❌ Error checking booking expiration: $e");
      return false;
    }
  }

  /// Check if a free booking is expired - PUBLIC METHOD
  bool isFreeBookingExpired(Map<String, dynamic> booking) {
    try {
      final String timeStr = booking['endTimeStr']?.toString() ?? '';

      if (timeStr.isEmpty || timeStr == 'Any Time') {
        return false;
      }

      // ✅ Direct parse (works for "YYYY-MM-DD HH:mm:ss")
      final tripDateTime = DateTime.parse(timeStr);
      final expiryTime = tripDateTime.add(const Duration(minutes: 30));

      return DateTime.now().isAfter(expiryTime);
    } catch (e) {
      debugPrint("Error checking free booking expiration: $e");
      return false;
    }
  }

  /// Get expiry time text for display - PUBLIC METHOD
  String getExpiryTimeText(Map<String, dynamic> booking, String itemType) {
    try {
      final dateStr = booking['date']?.toString() ?? '';
      final timeStr = booking['time']?.toString() ?? '';

      if (dateStr.isEmpty || timeStr.isEmpty) return "30 min after trip time";

      // Parse trip time
      DateTime tripDateTime;

      if (itemType == "booking") {
        if (dateStr.contains('-')) {
          final dateParts = dateStr.split('-');
          final year = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final day = int.parse(dateParts[2]);

          int hour = 0, minute = 0;
          final timeParsed = parseTime(timeStr);
          if (timeParsed != null) {
            hour = timeParsed.$1;
            minute = timeParsed.$2;
          }

          tripDateTime = DateTime(year, month, day, hour, minute);
          final expiryTime = tripDateTime.add(const Duration(minutes: 30));
          final now = DateTime.now();
          final difference = now.difference(expiryTime);

          if (difference.inMinutes < 60) {
            return "${difference.inMinutes} min ago";
          } else if (difference.inHours < 24) {
            return "${difference.inHours} hours ago";
          } else {
            return "${difference.inDays} days ago";
          }
        }
      }
      return "30 min after trip time";
    } catch (e) {
      return "30 min after trip time";
    }
  }

  // ==================== FILTERED BOOKINGS GETTERS ====================

  /// Show ALL bookings (both active and expired) - just filter by search
  List<Map<String, dynamic>> get filteredBookings {
    if (searchQuery.value.isEmpty) return bookings;

    final query = searchQuery.value.toLowerCase().trim();
    return bookings.where((b) {
      final from = (b['from'] ?? '').toString().toLowerCase();
      return from.contains(query);
    }).toList();
  }

  /// Show ALL free bookings (both active and expired) - just filter by search
  List<Map<String, dynamic>> get filteredfreeBookings {
    if (searchQuery.value.isEmpty) return freebookings;

    final query = searchQuery.value.toLowerCase().trim();
    return freebookings.where((b) {
      final from = (b['from'] ?? '').toString().toLowerCase();
      return from.contains(query);
    }).toList();
  }

  // ==================== UI METHODS ====================

  void updateSearch(String value) => searchQuery.value = value;

  void clearSearch() {
    searchQuery.value = '';
    Get.focusScope?.unfocus();
  }

  void switchTab(int index) {
    selectedTab.value = index;
    clearSearch();
  }

  // ==================== API METHODS ====================

  Future<void> fetchIndianCities() async {
    if (allCities.isNotEmpty) {
      isCitiesLoading.value = false;
      return;
    }

    try {
      isCitiesLoading.value = true;
      final response = await http.get(
        Uri.parse(
          "https://countriesnow.space/api/v0.1/countries/cities/q?country=India",
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["error"] == false && data["data"] is List) {
          final List<String> cities = (data["data"] as List).cast<String>();
          cities.sort();
          allCities.assignAll(cities);
          filteredCities.assignAll(cities);
        }
      }
    } catch (e) {
      debugPrint("City load error: $e");
    } finally {
      isCitiesLoading.value = false;
    }
  }

  void searchCities(String query) {
    if (query.trim().isEmpty) {
      filteredCities.assignAll(allCities);
    } else {
      final lower = query.toLowerCase();
      filteredCities.assignAll(
        allCities.where((city) => city.toLowerCase().contains(lower)).toList(),
      );
    }
  }

  Future<void> fetchAvailableBookings() async {
    hasError.value = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "0";

      final url = Uri.parse("$appurl/available_bookings?user_id=$userId");
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        if (data["status"] == true && data["available_bookings"] != null) {
          final List items = data["available_bookings"];

          final parsed = items.map((item) {

            final b = item["booking"] as Map<String, dynamic>;
            final u = item["user_data"] as Map<String, dynamic>;
            // print(item['booking']);
            return
              {
              'id': b["id"].toString(),
              'trip_id': b["trip_id"]?.toString() ?? "N/A",
              'send_call': b["send_call"]?.toString() ?? "N/A",
              'send_whatsapp': b["send_whatsapp"]?.toString() ?? "N/A",
              'driver': u["user_name"] ?? "Unknown Driver",
              'mobile': u["user_mobile"]?.toString() ?? "",
              'from': b["start_location"] ?? "Unknown",
              'to': b["end_location"] ?? "Unknown",
              'date': b["trip_date"] ?? "",
              'time': b["trip_time"] ?? "",
              'status': b["status"]?.toString() ?? "1",
              'mark_booked': b["mark_booked"]?.toString() ?? "1",
              'isTwoWay': b["trip_type"] == "two_way",
              'carType': b["car_type"] ?? "Sedan",
              'carrier': b["carrier"]?.toString() ?? "0",
              'price': b["price"]?.toString() ?? "N/A",
              'price_type': b["price_type"]?.toString() ?? "N/A",
              'remarks': (b["remarks"] ?? "").toString().trim().isNotEmpty
                  ? b["remarks"]
                  : "No remarks",
              'verified': u["aadhar_verified"]?.toString() == "1",
              'added_on': b["added_on"] ?? DateTime.now().toString(),
              'bookingdate_time': b["bookingdate_time"]?.toString() ?? "",
            };
          }).toList();

          // for (var booking in bookings) {
          //   print(booking['id']);
          // }

          // Filter out already removed bookings
          final filteredParsed = parsed.where((booking) {
            return !_isBookingRemoved(booking['id'].toString(), false);
          }).toList();

          bookings.assignAll(filteredParsed);

          // Check each booking for scheduled removal based on bookingdate_time
          for (var booking in bookings) {

            checkAndScheduleRemoval(booking, false);
          }

          // Run initial cleanup
          _removeExpiredAndBookedBookings();

          print("bookings");
          // print(bookings.toJson());
          debugPrint(
              "📊 Loaded ${bookings.length} bookings (filtered out ${parsed.length - filteredParsed.length} removed)");


        }
      }
    } catch (e) {
      hasError.value = true;
      // CustomNotification.show(
      //   title: "Error",
      //   message: "Failed to load trips",
      //   isSuccess: false,
      // );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAvailablefreeBookings() async {
    hasError.value = false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id") ?? "0";

      final url = Uri.parse("$appurl/free-booking/all?user_id=$userId");
      final response = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == true && data["available_free_bookings"] != null) {
          final List items = data["available_free_bookings"];
          final now = DateTime.now();

          final parsed = items.map<Map<String, dynamic>>((item) {
            final b = item["booking"] as Map<String, dynamic>;
            final u = item["user_data"] as Map<String, dynamic>;

            String dateDisplay = "Any Day";
            String timeDisplay = "Any Time";
            DateTime? tripDateTime;

            if (b["start_time"] != null) {
              String startStr = b["start_time"].toString().trim();

              if (startStr.contains(" ")) {
                final parts = startStr.split(" ");
                final datePart = parts[0];

                try {
                  tripDateTime = DateTime.parse("$datePart ${parts[1]}");

                  // AM PM format
                  timeDisplay = DateFormat('hh:mm a').format(tripDateTime);

                  if (tripDateTime.year == now.year &&
                      tripDateTime.month == now.month &&
                      tripDateTime.day == now.day) {
                    dateDisplay = "Today";
                  } else if (tripDateTime
                      .isAfter(now.subtract(const Duration(days: 1))) &&
                      tripDateTime.isBefore(now.add(const Duration(days: 1)))) {
                    dateDisplay = "Tomorrow";
                  } else {
                    dateDisplay = DateFormat('dd MMM yyyy').format(tripDateTime);
                  }
                } catch (_) {
                  dateDisplay = datePart;
                }
              } else {
                timeDisplay = startStr;
              }
            }

            // if (b["start_time"] != null) {
            //   String startStr = b["start_time"].toString().trim();
            //   if (startStr.contains(" ")) {
            //     final parts = startStr.split(" ");
            //     final datePart = parts[0];
            //     final timePart = parts[1].substring(0, 5);
            //
            //     timeDisplay = timePart;
            //
            //     try {
            //       tripDateTime = DateTime.parse("$datePart ${parts[1]}");
            //       if (tripDateTime.year == now.year &&
            //           tripDateTime.month == now.month &&
            //           tripDateTime.day == now.day) {
            //         dateDisplay = "Today";
            //       } else if (tripDateTime
            //               .isAfter(now.subtract(const Duration(days: 1))) &&
            //           tripDateTime.isBefore(now.add(const Duration(days: 1)))) {
            //         dateDisplay = "Tomorrow";
            //       } else {
            //         dateDisplay =
            //             DateFormat('dd MMM yyyy').format(tripDateTime);
            //       }
            //     } catch (_) {
            //       dateDisplay = datePart;
            //     }
            //   } else {
            //     timeDisplay = startStr;
            //   }
            // }

            final bool isTwoWay = b["end_time"] != null &&
                b["end_time"].toString().trim().isNotEmpty &&
                b["end_time"].toString().split(" ")[0] !=
                    b["start_time"]?.toString().split(" ")[0];

            return {
              'id': b["id"].toString(),
              'trip_id': b["trip_id"]?.toString() ?? "N/A",
              'driver': u["user_name"] ?? "Unknown Driver",
              'mobile': u["user_mobile"]?.toString() ?? "",
              'send_call': b["send_call"]?.toString() ?? "N/A",
              'send_whatsapp': b["send_whatsapp"]?.toString() ?? "N/A",
              'from': b["location"] ?? "Location not set",
              'to': "",
              'date': dateDisplay,
              'time': timeDisplay,
              'endTimeStr': b["end_time"]?.toString() ?? "N/A",
              'status': b["status"]?.toString() ?? "1",
              'isTwoWay': isTwoWay,
              'carType': b["car_type"] ?? "Sedan",
              'carrier': b["carrier"]?.toString() ?? "0",
              'remarks': (b["remarks"] ?? "").toString().trim().isNotEmpty
                  ? b["remarks"]
                  : "No remarks",
              'added_on': b["added_on"] ?? DateTime.now().toString(),
              'bookingdate_time': b["bookingdate_time"]?.toString() ?? "",
              'avatarUrl': "",
              'verified': u["aadhar_verified"]?.toString() == "1" ||
                  u["dl_verified"]?.toString() == "2",
              'user_image': u["user_image"] ?? "",
            };
          }).toList();

          parsed.sort((a, b) =>
              b['added_on'].toString().compareTo(a['added_on'].toString()));

          // Filter out already removed bookings
          final filteredParsed = parsed.where((booking) {
            return !_isBookingRemoved(booking['id'].toString(), true);
          }).toList();

          freebookings.assignAll(filteredParsed);

          // Check each free booking for scheduled removal
          for (var booking in freebookings) {
            checkAndScheduleRemoval(booking, true);
          }

          // Run initial cleanup
          _removeExpiredAndBookedBookings();

          debugPrint(
              "📊 Loaded ${freebookings.length} free bookings (filtered out ${parsed.length - filteredParsed.length} removed)");
        }
      }
    } catch (e) {
      debugPrint("Free bookings fetch error: $e");
      // hasError.value = true;
      // CustomNotification.show(
      //   title: "Error",
      //   message: "Failed to load free vehicle requests",
      //   isSuccess: false,
      // );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshBookings() async {
    await fetchAvailablefreeBookings();
    await fetchAvailableBookings();
  }

  // ==================== NAVIGATION ====================

  void navigateToMyBooking() =>
      Get.to(() => const MyBookingScreen(), transition: Transition.fadeIn);

  void navigateToAlerts() =>
      Get.to(() => const AlertsScreen(), transition: Transition.fadeIn);

  void navigateToProfile() =>
      Get.to(() => const ProfileScreen(), transition: Transition.fadeIn);

  void onNewBooking() =>
      Get.to(() => const NewBookingScreen(), transition: Transition.downToUp);

  void onFreeVehicle() {
    Get.to(() => const FreebookingNew(), transition: Transition.downToUp);
  }

  void navigateToSmartBooking() =>
      Get.to(() => const SmartBookingScreen(), transition: Transition.fadeIn);

  // ==================== ACTIONS ====================
  void updateCallerCount(String bookingId) async {
    // showBookingForm.value = true;
    try {
      var postData = {
        'booking_id' : bookingId,


      };
      print("$appurl/update_call_count");
      print("postData $postData ");
      final response = await http.post(
        Uri.parse("$appurl/update_call_count"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: postData,
      );

      final json = jsonDecode(response.body);
      print(json);

    } catch (e) {
      debugPrint("error while getting booking details : $e");
    }


  }

  Future<void> makePhoneCall(String phone, String bookingId) async {
    print("bookingId $bookingId");
    updateCallerCount(bookingId);
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> openWhatsApp(bool isBooking, String phone, Map<String, dynamic> booking) async {
    Utils.getWhatsappShareMesage(isBooking, phone, booking);
  }

  Future<void> openWhatsApp2(String phone, Map<String, dynamic> booking) async {
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

    final String from = booking['from']?.toString() ?? 'Unknown';
    final String to = booking['to']?.toString() ?? 'Unknown';
    final String date = booking['date']?.toString() ?? 'N/A';
    final String time = booking['time']?.toString() ?? 'N/A';
    final String pickupTime = "$date, $time";
    final String rate =
        booking['price'] != null ? "Rs ${booking['price']}" : "N/A";
    final String carType = booking['carType']?.toString() ?? 'Sedan';
    final String tripType =
        (booking['isTwoWay'] == true || booking['isTwoWay'] == "1")
            ? "ROUND TRIP"
            : "ONEWAY";

    const String appLink =
        "https://play.google.com/store/apps/details?id=com.pickcab.partner";

    final String message = """
Dear Sir/Ma'am, 
am interested, Kripya aage ki jankari pradan karein

Pickup: $from
Drop: $to
Vehicle: $carType
Message: $from to $to
Pickup time: $pickupTime
Rate: $rate
Extra Info: $tripType

Pickcab Partner
New Booking
--------------------------
${from.toUpperCase()} TO ${to.toUpperCase()}
$tripType
RATE       : $rate
Date       : $pickupTime
Car Type   : $carType
*Call      : *

PICKCAB PARTNER AAP download link
$appLink
"""
        .trim();

    final String encodedMessage = Uri.encodeComponent(message);
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

  void shareBooking(bool isBooking,  Map<String, dynamic> booking) {
    Utils.getShareMessage(isBooking, booking);
  }

  void shareBooking2(Map<String, dynamic> booking) {
    const String appLink =
        "https://play.google.com/store/apps/details?id=com.pickcab.partner";
    final text = """

New Booing available in PicCab Partner



Pickup: ${booking['from']}
Drop: ${booking['to']}
${booking['isTwoWay'] ? 'Round Trip' : 'One Way'}
Vehicle: ${booking['carType']}
Message: ${booking['from']} to ${booking['to']} 
Pickup time:: ${formatTripDate(booking['date'])} @ ${booking['time']}
Rate: ${booking['price']}
Extra Info: ${booking['isTwoWay'] ? 'Round Trip' : 'One Way'}

Pickcab Partner
New Booking
--------------------------
${booking['from'].toUpperCase()} TO ${booking['to'].toUpperCase()}
${booking['isTwoWay'] ? 'Round Trip' : 'One Way'}
RATE       : ${booking['price']}
Date       : ${formatTripDate(booking['date'])} @ ${booking['time']}
Car Type   : ${booking['carType']}
*Call      : *

PICKCAB PARTNER AAP download link
$appLink
    """
        .trim();

    Share.share(text, subject: "Ride from ${booking['from']}");
  }

  // ==================== HELPER METHODS ====================

  static String formatTripDate(String date) {
    if (date.isEmpty) return "N/A";
    try {
      final d = DateTime.parse(date);
      final day = d.day;
      final suffix = (day >= 11 && day <= 13)
          ? "th"
          : {1: "st", 2: "nd", 3: "rd"}[day % 10] ?? "th";
      const months = [
        "",
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
      return "$day$suffix ${months[d.month]}";
    } catch (e) {
      return date;
    }
  }

  static String timeAgo(String dateTimeStr) {
    try {
      final DateTime addedOn = DateTime.parse(dateTimeStr);
      final Duration diff = DateTime.now().difference(addedOn);

      if (diff.inSeconds < 60) {
        return "${diff.inSeconds} sec ago";
      } else if (diff.inMinutes < 60) {
        return "${diff.inMinutes} min ago";
      } else if (diff.inHours < 24) {
        return "${diff.inHours} ${diff.inHours == 1 ? 'hour' : 'hours'} ago";
      } else if (diff.inDays < 7) {
        return "${diff.inDays} ${diff.inDays == 1 ? 'day' : 'days'} ago";
      } else if (diff.inDays < 30) {
        final weeks = (diff.inDays / 7).floor();
        return "$weeks ${weeks == 1 ? 'week' : 'weeks'} ago";
      } else {
        final months = (diff.inDays / 30).floor();
        return "$months ${months == 1 ? 'month' : 'months'} ago";
      }
    } catch (e) {
      return "Just now";
    }
  }
}
