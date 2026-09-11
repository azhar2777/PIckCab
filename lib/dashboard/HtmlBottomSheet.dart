import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'DashboardController.dart';



class HtmlBottomSheet extends StatefulWidget {

  final String html;

  const HtmlBottomSheet({
    super.key,
    required this.html,
  });

  @override
  State<HtmlBottomSheet> createState() => _HtmlBottomSheetState();
}

class _HtmlBottomSheetState extends State<HtmlBottomSheet> {
  late final WebViewController webController;
  final DashboardController controller = Get.put(DashboardController());

  @override
  void initState() {
    super.initState();

    webController = WebViewController()
      ..setJavaScriptMode(
        JavaScriptMode.unrestricted,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) async {
            final uri = Uri.tryParse(request.url);

            if (uri == null) {
              return NavigationDecision.prevent;
            }

            // Open links in external browser
            if (uri.scheme == 'http' || uri.scheme == 'https') {
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.45,
      // margin: EdgeInsets.only(bottom: 50),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 50),
                child: WebViewWidget(
                  controller: webController,
                ),
              ),
            ),

            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.white,
                elevation: 3,
                shape: const CircleBorder(),
                child: InkWell(

                  onTap: () => {
                    controller.saveBottomsheetInfo(),
                    Navigator.of(context).pop()
                  },
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.close,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}