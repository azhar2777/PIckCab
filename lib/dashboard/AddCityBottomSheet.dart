import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'DashboardController.dart';



class AddCityBottomSheet extends StatefulWidget {



  const AddCityBottomSheet({
    super.key,

  });

  @override
  State<AddCityBottomSheet> createState() => _AddCityBottomSheetState();
}

class _AddCityBottomSheetState extends State<AddCityBottomSheet> {
  late final WebViewController webController;
  final DashboardController controller = Get.put(DashboardController());

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: MediaQuery.of(context).size.height*0.4,
      // margin: EdgeInsets.only(bottom: 50),
      padding: EdgeInsets.only(bottom: 0,),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,

        children: [
          // Material(
          //   color: Colors.white.withOpacity(0.5),
          //   elevation: 3,
          //   shape: const CircleBorder(),
          //   child: InkWell(
          //
          //     onTap: () => {
          //       controller.saveBottomsheetInfo(),
          //       Navigator.of(context).pop()
          //     },
          //     customBorder: const CircleBorder(),
          //     child: const SizedBox(
          //       width: 40,
          //       height: 40,
          //       child: Icon(
          //         Icons.close,
          //         size: 24,
          //         color: Color(0xFF6A1B9A),
          //       ),
          //     ),
          //   ),
          // ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(

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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20,),
                    child:Container(
                      // height: 500,
                      width: double.infinity,
                      color: Colors.white,
                      child: Column(
                        children: [
                          Image.asset(
                            "assets/images/ic_add_city.png",
                            width: 100,
                            fit: BoxFit.contain,
                            // color: Color(0xFF6A1B9A),
                          ),
                          Text("Add your City",
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,

                              // color: Color(0xFF6A1B9A),
                            ),
                          ),
                          SizedBox(height: 8.0,),
                          Text("बुकिंग प्राप्त करने के लिए अपना शहर जोड़ें",
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                              // color: Color(0xFF6A1B9A),
                            ),
                          ),

                          SizedBox(height: 15.0,),
                          InkWell(
                            onTap: (){
                              controller.onAddCity();
                            },
                            child: Container(
                              height: 48,
                              // alignment: Alignment.centerLeft,
                              // padding: const EdgeInsets.symmetric(horizontal: 16),
                              // margin: EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Color(0xFF6A1B9A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:const Color(0xFF6A1B9A),
                                ),
                              ),
                              child: Center(
                                child: Text("Add Location / स्थान जोड़ें",
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    // color: Colors.black,
                                    color: Color(0xFFFFFFFF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 35.0,),
                        ],
                      ),
                    )
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}