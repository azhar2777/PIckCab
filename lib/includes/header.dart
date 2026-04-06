// lib/includes/header.dart

import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pickcab_partner/dashboard/DashboardScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../const/const.dart';
import '../const/custom_notification.dart';
import '../dashboard/DashboardController.dart';
import '../home/home_screen.dart';
import '../login/login_screen.dart';
import '../profile/profile_screen.dart';
import '../support/support_screen.dart';

class AppHeader extends StatefulWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final String? titleOverride;

  const AppHeader({
    super.key,
    this.showBackButton = false,
    this.titleOverride,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AppHeaderState extends State<AppHeader> {
  bool alertEnabled = false;
  String userImage = "";
  String userId = "";
  bool isLoading = true;

  // Cache keys
  static const String _cachedUserImage = 'cached_user_image';
  static const String _cachedAlertStatus = 'cached_alert_status';
  static const String _lastFetchTime = 'last_header_fetch_time';

  // Cache duration (e.g., 5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Device info
  String deviceId = '';
  String deviceName = '';
  String deviceModel = '';

  @override
  void initState() {
    super.initState();

    _getDeviceInfo();
    _initializeHeader();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Optional: Refresh when dependencies change
  }

  @override
  void didUpdateWidget(AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Optional: Handle widget updates
  }

  @override
  void dispose() {
    // Clean up resources if needed
    super.dispose();
  }

  // ======================= INITIALIZE =======================
  Future<void> _initializeHeader() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("user_id") ?? "0";

    if (userId == "0" || userId.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    // First load cached data immediately
    await _loadCachedData();

    // Then fetch fresh data in background
    _refreshDataIfNeeded();
  }

  // ======================= LOAD CACHED DATA =======================
  Future<void> _loadCachedData() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();

    if (mounted) {
      setState(() {
        userImage = prefs.getString(_cachedUserImage) ?? "";
        alertEnabled = prefs.getBool(_cachedAlertStatus) ?? false;
        isLoading = false;
      });
    }
  }

  // ======================= REFRESH DATA IF NEEDED =======================
  Future<void> _refreshDataIfNeeded() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final lastFetch = prefs.getInt(_lastFetchTime) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check if cache is expired
    if (now - lastFetch > _cacheDuration.inMilliseconds) {
      await _fetchUserDetails();
    }
  }

  Future<void> _getDeviceInfo() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

      if (GetPlatform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceName = androidInfo.device;
        deviceModel = androidInfo.model;
      } else if (GetPlatform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceName = iosInfo.name;
        deviceModel = iosInfo.model;
      }

      _checkDeviceValidation();
    } catch (e) {
      deviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      deviceName = 'Unknown Device';
      deviceModel = 'Unknown Model';
    }
  }

  // ======================= DEVICE CHECK API =======================
  Future<void> _checkDeviceValidation() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getString("user_id") ?? "0";

    if (deviceId.isEmpty) return;

    final url = Uri.parse("$appurl/checkDevice");

    try {
      var request = http.MultipartRequest('POST', url);
      request.fields.addAll({
        "user_id": userId,
        "device_id": deviceId,
        "device_name": deviceName,
        "device_model": deviceModel,
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (data["action"] == "logout") {
        await prefs.setBool("is_logged_in", true);

        await prefs.remove('is_logged_in');
        await prefs.remove('user_id');
        await prefs.remove('device_id');
        await prefs.remove('app_name');
        await prefs.remove('login_time');
        await prefs.clear();

        if (mounted) {
          CustomNotification.show(
            title: "Session Expired",
            message: "You have been logged in from another device",
            isSuccess: false,
          );

          Get.offAll(() => const LoginScreen());
        }
      }
    } catch (e) {
      debugPrint("Device validation error: $e");
    }
  }

  // ======================= FETCH USER DETAILS =======================
  Future<void> _fetchUserDetails() async {
    if (!mounted) return;

    final url = Uri.parse("$appurl/user_details?user_id=$userId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["status"] == true) {
          final userData = data["user_data"];

          final newAlertStatus = userData["alert_status"].toString() == "1";
          final newUserImage = userData["user_image"] != null &&
                  userData["user_image"].toString().isNotEmpty
              ? "$imageurl/${userData["user_image"]}"
              : "";

          // Save to cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cachedUserImage, newUserImage);
          await prefs.setBool(_cachedAlertStatus, newAlertStatus);
          await prefs.setInt(
              _lastFetchTime, DateTime.now().millisecondsSinceEpoch);

          // Update UI if still mounted
          if (mounted) {
            setState(() {
              alertEnabled = newAlertStatus;
              userImage = newUserImage;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("User detail error: $e");
    }
  }

  // ======================= UPDATE ALERT =======================
  Future<void> _updateAlertStatus(bool newValue) async {
    if (!mounted) return;

    setState(() {
      alertEnabled = newValue;
    });

    final url = Uri.parse("$appurl/update_alert");

    try {
      var request = http.MultipartRequest('POST', url);
      request.fields.addAll({
        "user_id": userId,
        "alert_status": newValue ? "1" : "0",
      });

      await request.send();

      // Update cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cachedAlertStatus, newValue);

      if (mounted) {
        CustomNotification.show(
          title: "Alert",
          message: newValue ? "Alerts Enabled" : "Alerts Disabled",
          isSuccess: true,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          alertEnabled = !newValue;
        });
      }
    }
  }

  // ======================= PUBLIC METHOD TO REFRESH =======================
  Future<void> refreshHeaderData() async {
    if (mounted) {
      await _fetchUserDetails();
    }
  }

  // ======================= NAVIGATION =======================
  void navigateToProfile() async {
    if (!mounted) return;

    print("navigateToProfile");

    final controller = Get.find<DashboardController>();
    controller.selectedIndex.value = 3;
  }
  void navigateToProfile1() async {
    if (!mounted) return;
    print("navigateToProfile");

    // // Navigate and wait for result
    // final result = await Get.to(() => const DashboardScreen(selectedTab: 3),
    //     transition: Transition.fadeIn);
    //
    // // If profile was updated, refresh data


    final result = await Get.off(
          () => const DashboardScreen(selectedTab: 3),
      transition: Transition.fadeIn,
    );
    if (result == true && mounted) {
      await _fetchUserDetails();
    }
  }

  void navigateToSupport() {
    if (mounted) {
      Get.to(() => const SupportScreen(), transition: Transition.fadeIn);
    }
  }

  void navigateToHome() {

    if (mounted) {
      print("navigateToHome");
      Get.offAll(() => const DashboardScreen(selectedTab: 1));
      // Get.to(() => DashboardScreen(selectedTab: 0), transition: Transition.fadeIn);

    }
  }

  // ======================= UI =======================
  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: widget.showBackButton,
      backgroundColor: Colors.white,
      elevation: 1,
      title: GestureDetector(
        onTap: navigateToHome,
        child: Row(
          children: [
            Image.network(
              '$imageurlstatic/pp_logo.png',
              width: 40,
              height: 40,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.local_taxi, size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.titleOverride ?? '',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Row(
          children: [
            const Icon(Icons.notifications_outlined, color: Color(0xFF6A1B9A)),
            Switch(
              value: alertEnabled,
              onChanged:
                  isLoading ? null : (value) => _updateAlertStatus(value),
              activeColor: const Color(0xFF6A1B9A),
            ),
            GestureDetector(
              onTap: navigateToSupport,
              child: const Icon(Icons.support_agent,
                  size: 40, color: Color(0xFF6A1B9A)),
            ),
          ],
        ),
        GestureDetector(
          onTap: navigateToProfile,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: _buildProfileImage(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    if (isLoading && userImage.isEmpty) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (userImage.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: userImage,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.person, size: 20),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.person, size: 20),
        ),
      );
    }

    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, size: 20),
    );
  }
}
