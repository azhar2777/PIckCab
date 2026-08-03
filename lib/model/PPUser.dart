class PPUser {
  String? id;
  String? userUnqId;
  String? userName;
  String? userMobile;
  String? userEmail;
  String? city;
  String? userImage;
  String? userType;
  String? deviceToken;
  String? otp;
  String? addedOn;
  String? alertStatus;
  String? status;
  String? aadharVerified;
  String? dlVerified;
  Null? dlNo;
  Null? aadharNo;
  Null? aadharDetailsJson;
  Null? aadharVerifiedOn;
  String? deviceId;
  String? deviceName;
  String? deviceModel;
  String? loginStatus;
  String? isActive;

  PPUser(
      {this.id,
        this.userUnqId,
        this.userName,
        this.userMobile,
        this.userEmail,
        this.city,
        this.userImage,
        this.userType,
        this.deviceToken,
        this.otp,
        this.addedOn,
        this.alertStatus,
        this.status,
        this.aadharVerified,
        this.dlVerified,
        this.dlNo,
        this.aadharNo,
        this.aadharDetailsJson,
        this.aadharVerifiedOn,
        this.deviceId,
        this.deviceName,
        this.deviceModel,
        this.loginStatus,
        this.isActive});

  PPUser.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userUnqId = json['user_unq_id'];
    userName = json['user_name'];
    userMobile = json['user_mobile'];
    userEmail = json['user_email'];
    city = json['city'];
    userImage = json['user_image'];
    userType = json['user_type'];
    deviceToken = json['device_token'];
    otp = json['otp'];
    addedOn = json['added_on'];
    alertStatus = json['alert_status'];
    status = json['status'];
    aadharVerified = json['aadhar_verified'];
    dlVerified = json['dl_verified'];
    dlNo = json['dl_no'];
    aadharNo = json['aadhar_no'];
    aadharDetailsJson = json['aadhar_details_json'];
    aadharVerifiedOn = json['aadhar_verified_on'];
    deviceId = json['device_id'];
    deviceName = json['device_name'];
    deviceModel = json['device_model'];
    loginStatus = json['login_status'];
    isActive = json['is_active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_unq_id'] = this.userUnqId;
    data['user_name'] = this.userName;
    data['user_mobile'] = this.userMobile;
    data['user_email'] = this.userEmail;
    data['city'] = this.city;
    data['user_image'] = this.userImage;
    data['user_type'] = this.userType;
    data['device_token'] = this.deviceToken;
    data['otp'] = this.otp;
    data['added_on'] = this.addedOn;
    data['alert_status'] = this.alertStatus;
    data['status'] = this.status;
    data['aadhar_verified'] = this.aadharVerified;
    data['dl_verified'] = this.dlVerified;
    data['dl_no'] = this.dlNo;
    data['aadhar_no'] = this.aadharNo;
    data['aadhar_details_json'] = this.aadharDetailsJson;
    data['aadhar_verified_on'] = this.aadharVerifiedOn;
    data['device_id'] = this.deviceId;
    data['device_name'] = this.deviceName;
    data['device_model'] = this.deviceModel;
    data['login_status'] = this.loginStatus;
    data['is_active'] = this.isActive;
    return data;
  }
}