import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pickcab_partner/alerts/alerts_controller.dart';
import 'package:pickcab_partner/dashboard/AddCityBottomSheet.dart';
import 'package:pickcab_partner/services/presence_service.dart';
import 'package:pickcab_partner/utils/Utils.dart';
import 'package:pickcab_partner/utils/firebase_util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../alerts/alerts_screen.dart';
import '../const/const.dart';
import '../const/custom_notification.dart';
import '../edit_profile/EditProfileScreen.dart';
import '../freebooking/freebooking_new.dart';
import '../home/home_controller.dart';
import '../login/login_screen.dart';
import '../model/PPUser.dart';
import '../my_bookings/my_booking_controller.dart';
import '../my_bookings/my_booking_screen.dart';
import '../new_booking/new_booking_screen.dart';
import '../profile/profile_screen.dart';
import '../smartbooking/SmartBookingScreen.dart';
import 'HtmlBottomSheet.dart';
// import 'UpdateAppScreen.dart';

class DashboardController extends GetxController with WidgetsBindingObserver {
  static DashboardController get to => Get.find();

  // Notice
  final noticeHtml = ''.obs;
  var selectedIndex = 0.obs;
  // Show Smart booking
  final RxBool showSmartBooking = true.obs;
  final RxBool isBottomSheetOpen = false.obs;
  final RxBool isCityBottomSheetOpen = false.obs;
  var showDelete = false.obs;
  bool isUpdateDialogShowing = false;

  RxMap<String, dynamic> userProfile = <String, dynamic>{}.obs;

  final List<String> allowedMobiles = <String>[
    "8828451293",
    "9572511011",
    "9122220415",
    "7491010771",
    "9876543220",
    "9876543210",
    "9330662777"
  ];

  void changeTab(int index) {
    selectedIndex.value = index;
    print("changeTabIndex $index");

    if (index == 0) {
      Get.find<HomeController>().callAllFunctions();
      Get.find<AlertsController>().fetchCities();
    } else if (index == 1) {
      Get.find<MyBookingController>().fetchMyBookings();
    }
  }

  void onAddCity() async {
    Get.back(closeOverlays: true);
    changeTab(2);
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    fetchUserProfile();
    // Initial update check after UI renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isClosed) {
        debugPrint("pickCabAlertDialog called from onInit");

        checkForMandatoryUpdate();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!isClosed) {
          
          debugPrint("pickCabAlertDialog called from didChangeAppLifecycleState");
          checkForMandatoryUpdate();
          // Utils.pickCabAlertDialog(
          //   context: Get.context!,
          //   title: "Update Required",
          //   message:
          //       "A new version of PickCab is available. Please update the app to continue using it.",
          //   buttonText: "Update Now",
          //   onPressed: () {
          //     openPlayStore();
          //   },
          // );
        }
      });
    }
  }

  bool isUpdateCheckRunning = false;

  Future<void> checkForMandatoryUpdate() async {
    if (isUpdateCheckRunning || isClosed) return;

    isUpdateCheckRunning = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();


      final installedVersionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      final updateInfo = await InAppUpdate.checkForUpdate();

      final availableVersionCode = updateInfo.availableVersionCode ?? 0;

      debugPrint('Installed: $installedVersionCode');
      debugPrint('Play Store: $availableVersionCode');

      if (availableVersionCode > installedVersionCode) {
        final context = Get.context;

        if (context == null || isClosed) return;

        Utils.pickCabAlertDialog(
          context: context,
          title: "Update Required",
          message:
              "A new version of PickCab is available. Please update the app to continue using it.",
          buttonText: "Update Now",
          onPressed: () {
            openPlayStore();
          },
        );
      }
    } on PlatformException catch (e) {
      debugPrint('In-app update error: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('Update check error: $e');
    } finally {
      isUpdateCheckRunning = false;
    }
  }

  Future<void> openPlayStore() async {
    final Uri url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.pickcab.partner',
    );

    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        Get.snackbar(
          "Unable to Open Play Store",
          "Please try again or check your internet connection.",
        );
      }
    } catch (e) {
      Get.snackbar(
        "Unable to Open Play Store",
        "Please check your internet connection.\nError: $e",
      );
    }
  }

  Future<void> checkForUpdateSafely() async {
    try {
      print("updateAvailable checkForUpdateSafely");
      final info = await InAppUpdate.checkForUpdate()
          .timeout(const Duration(seconds: 5));

      final updateAvailable =
          info.updateAvailability == UpdateAvailability.updateAvailable;

      print("updateAvailable $updateAvailable");

      if (!updateAvailable) return;

      print("updateAvailable ${info}");
      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();

        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
          debugPrint('Flexible update completed.');
        } else {
          debugPrint('Flexible update did not complete successfully.');
        }
      }
    } catch (e) {
      print("updateAvailable checkForUpdateSafely error");
      debugPrint("Update check error: $e");
    }
  }

  // ==================== NAVIGATION ====================

  void navigateToMyBooking() =>
      Get.to(() => const MyBookingScreen(), transition: Transition.fadeIn);

  void navigateToAlerts() =>
      Get.to(() => const AlertsScreen(), transition: Transition.fadeIn);

  void navigateToProfile() =>
      Get.to(() => const ProfileScreen(), transition: Transition.fadeIn);

  void onNewBooking() =>
      Get.to(() => const NewBookingScreen(), transition: Transition.downToUp)
          ?.then((_) {
        Get.find<MyBookingController>().fetchMyBookings();
      });

  void onFreeVehicle() {
    Get.to(() => const FreebookingNew(), transition: Transition.downToUp);
  }

  // void navigateToSmartBooking() =>
  //     Get.to(() => const SmartBookingScreen(), transition: Transition.fadeIn);
  void navigateToSmartBooking() =>
      Get.to(() => SmartBookingScreen(), transition: Transition.fadeIn)
          ?.then((_) {
        Get.find<MyBookingController>().fetchMyBookings();
      });

  // ==================== Fetch User Details ====================
  Future<void> fetchUserProfile() async {
    try {
      final PresenceService presenceService = PresenceService();

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id') ?? '';
      final userToken = prefs.getString('user_token') ?? '';
      if (userId.isEmpty) {
        return;
      }

      await presenceService.initialize(userId);

      print(userId);

      if (userId == null || userId == "0") {
        Get.offAll(() => LoginScreen());
        return;
      }

      final url = Uri.parse("$appurl/user_details?user_id=$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["status"] == true) {
          final data = json["user_data"];
          final userCity = json["user_city"];
          // print("UserData");
          // print(data);

          final prefs = await SharedPreferences.getInstance();

          await prefs.setString("mobile_number", data['user_mobile']);
          await prefs.setString("user_name", data['user_name']);
          final newUserImage = data["user_image"] != null &&
                  data["user_image"].toString().isNotEmpty
              ? "$imageurl/${data["user_image"]}"
              : "";
          await prefs.setString("user_image", newUserImage);

          if (allowedMobiles.contains("${data['user_mobile']}")) {
            showSmartBooking.value = true;
          } else {
            showSmartBooking.value = true;
          }

          if ("${data['user_mobile']}".contains("9572511011")) {
            showDelete.value = true;
          }

          print(
              "is_profile_completed fetch Notice ${data['is_profile_completed']}");

          var cityName =
              userCity is Map ? userCity["city"]?.toString() ?? '' : '';

          if (data['is_profile_completed'].toString() == "1") {
            if (cityName.isEmpty) {
              fetchNotice(1);
              print("cityName is Empty");
            } else {
              print("cityName is $cityName");
              fetchNotice(0);
            }
          } else {
            await Get.to(
              () => const Editprofilescreen(),
              transition: Transition.fadeIn,
            );
          }
          print("updateUserData1 ${data}");
          // PPUser user = PPUser.fromJson(data);
          // FirebaseUtil.updateUserData(user);
          Map<String, dynamic> mapUser = {
            'id': data['id'],
            'user_mobile': data['user_mobile'],
            'aadhar_verified': data['aadhar_verified'],
            'device_token': data['device_token'],
          };

          FirebaseUtil.updateuser(data['id'], mapUser);
        } else {
          throw Exception(json["message"] ?? "Failed to load profile");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Profile fetch error: $e");
      CustomNotification.show(
        title: "Connection Error",
        message: "Failed to load profile. Pull to refresh.",
        isSuccess: false,
      );
    } finally {}
  }

  Future<void> fetchOthersProfile(String userId) async {
    try {
      if (userId.isEmpty || userId == "0") {
        Get.offAll(() => LoginScreen());
        return;
      }

      final url = Uri.parse("$appurl/user_details?user_id=$userId");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData["status"] == true) {
          // Store API JSON data
          userProfile.assignAll(
            Map<String, dynamic>.from(jsonData["user_data"] ?? {}),
          );
        } else {
          throw Exception(
            jsonData["message"] ?? "Failed to load profile",
          );
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Profile fetch error: $e");

      CustomNotification.show(
        title: "Connection Error",
        message: "Failed to load profile. Pull to refresh.",
        isSuccess: false,
      );
    }
  }

  Future<void> fetchNotice(int showCity) async {
    print("fetchNotice called");
    int showAfterEveryHours = 8;
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = Uri.parse("$appurl/getNotice");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json["status"] == true) {
          final data = json["notice_data"];

          if (data != null && data.length > 0 && selectedIndex.value == 0) {
            // print(data[0]);
            noticeHtml.value = data[0]['description'];
            // noticeHtml.value = data[0]['description'];
            // print(noticeHtml.value);
            final noticeStamp = prefs.getString("notice_timestamp");
            if (noticeStamp != null && noticeStamp.isNotEmpty) {
              // print("noticeStamp $noticeStamp");
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final diff = timestamp - int.parse(noticeStamp);

              print("Diffff >>>> $diff");

              if (data[0]['notice_interval'] != null &&
                  int.parse(data[0]['notice_interval']) > 0) {
                showAfterEveryHours = int.parse(data[0]['notice_interval']);
              }
              print(
                  "Diffff >>>> $diff showAfterEveryHours $showAfterEveryHours");
              // if (diff >= 10) {
              if (diff >= showAfterEveryHours * 60 * 60 * 1000) {
                if (!isBottomSheetOpen.value) {
                  isBottomSheetOpen.value = true;
                  Get.bottomSheet(HtmlBottomSheet(html: data[0]['description']),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          isDismissible: false)
                      .whenComplete(() {
                    isBottomSheetOpen.value = false;
                    if (showCity == 1 && !isCityBottomSheetOpen.value) {
                      isCityBottomSheetOpen.value = true;
                      Get.bottomSheet(
                        AddCityBottomSheet(),
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        isDismissible: true,
                      ).whenComplete(() {
                        print("Add City pop up shown");
                        isCityBottomSheetOpen.value = false;
                      });
                    }
                  });
                }
              } else {
                print("More than 60 minutes");
                if (showCity == 1 && !isCityBottomSheetOpen.value) {
                  isCityBottomSheetOpen.value = true;
                  Get.bottomSheet(AddCityBottomSheet(),
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          isDismissible: true)
                      .whenComplete(() {
                    print("Add City pop up shown");
                    isCityBottomSheetOpen.value = false;
                  });
                }
              }
            } else {
              if (!isBottomSheetOpen.value) {
                isBottomSheetOpen.value = true;
                Get.bottomSheet(HtmlBottomSheet(html: data[0]['description']),
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        isDismissible: false)
                    .whenComplete(() {
                  isBottomSheetOpen.value = false;
                  if (showCity == 1 && !isCityBottomSheetOpen.value) {
                    isCityBottomSheetOpen.value = true;
                    Get.bottomSheet(AddCityBottomSheet(),
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            isDismissible: true)
                        .whenComplete(() {
                      print("Add City pop up shown");
                      isCityBottomSheetOpen.value = false;
                    });
                  }
                });
              }
            }
          }
        } else {
          throw Exception(json["message"] ?? "Failed to load html");
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      print("Html fetch error: $e");
      CustomNotification.show(
        title: "Connection Error",
        message: "Failed to load profile. Pull to refresh.",
        isSuccess: false,
      );
    } finally {}
  }

  void saveBottomsheetInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    prefs.setString("notice_timestamp", "$timestamp");
  }
}
