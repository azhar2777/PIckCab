class Slides {
  bool? status;
  List<BannerData>? bannerData;

  Slides({this.status, this.bannerData});

  Slides.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    if (json['banner_data'] != null) {
      bannerData = <BannerData>[];
      json['banner_data'].forEach((v) {
        bannerData!.add(new BannerData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    if (this.bannerData != null) {
      data['banner_data'] = this.bannerData!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class BannerData {
  String? id;
  String? image;
  String? link;
  String? isActive;

  BannerData({this.id, this.image, this.link, this.isActive});

  BannerData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    image = json['image'];
    link = json['link'];
    isActive = json['is_active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['image'] = this.image;
    data['link'] = this.link;
    data['is_active'] = this.isActive;
    return data;
  }
}