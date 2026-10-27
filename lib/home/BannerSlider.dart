import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../const/const.dart';
import '../model/Slides.dart';

class BannerSlides extends StatelessWidget {
  final List<BannerData> images;
  const BannerSlides({super.key, required this.images});

  Future<void> opoenLink(String url) async {
    if (url.isEmpty) {
      Get.snackbar("Error", "URL not configured");
      return;
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      Get.snackbar("Error", "Could not launch $url");
    }

  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, ),
      child: Container(
        height: 85,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            // color: const Color.fromARGB(255, 174, 174, 174),
            color: Colors.transparent,
            width: 1.5,
          ),
        ),
        child: CarouselSlider(
          options: CarouselOptions(
            autoPlay: true,
            viewportFraction: 1, // Full width
            enlargeCenterPage: false,
            autoPlayInterval: Duration(seconds: 3),
          ),

          items: images.map((item) {
            return InkWell(
              onTap: ()=>{
                opoenLink(item.link.toString())
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.transparent,
                    width: 1,

                  ),
                ),
                clipBehavior: Clip.antiAlias, // 👈 clips the image
                child: Image.network(
                  "${imageurl}Banners/${item.image.toString()}",
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            );
          }).toList(),
      ),
      ),
    );
  }
}

