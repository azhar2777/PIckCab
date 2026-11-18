import 'package:material_ui/material_ui.dart';
import 'package:pickcab_partner/dashboard/DashboardController.dart';
import 'package:pickcab_partner/dashboard/DashboardScreen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

class MandatoryUpdateScreen extends StatefulWidget {
  final int minimumVersionCode;

  const MandatoryUpdateScreen({
    super.key,
    required this.minimumVersionCode,
  });

  @override
  State<MandatoryUpdateScreen> createState() =>
      _MandatoryUpdateScreenState();
}

class _MandatoryUpdateScreenState
    extends State<MandatoryUpdateScreen>
    with WidgetsBindingObserver {

  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Detect when user returns from Play Store
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkInstalledVersion();
    }
  }

  Future<void> checkInstalledVersion() async {
    if (isChecking) return;

    isChecking = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();

      final installedVersionCode =
          int.tryParse(packageInfo.buildNumber) ?? 0;

      debugPrint('Installed version: $installedVersionCode');
      debugPrint('Required version: ${widget.minimumVersionCode}');

      if (installedVersionCode >= widget.minimumVersionCode) {

        // Update completed successfully.
        if (mounted) {
          Get.offAll(() => DashboardScreen(selectedTab: 0));
        }

      } else {
        debugPrint('Update still required');
      }

    } catch (e) {
      debugPrint('Version check error: $e');
    } finally {
      isChecking = false;
    }
  }

  Future<void> openPlayStore() async {
    final url = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.pickcab.partner',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.system_update,
                  size: 90,
                  color: Color(0xFF6A1B9A),
                ),
                const SizedBox(height: 25),
                const Text(
                  'Update Required!',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Please update PickCab Partner to continue.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: openPlayStore,
                    child: const Text('UPDATE NOW'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}