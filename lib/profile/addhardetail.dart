class AadhaarDetails {
  final String name;
  final String dob;
  final String gender;
  final String aadhaarNumber;
  final AadhaarAddress address;
  final String? photoBase64;

  AadhaarDetails({
    required this.name,
    required this.dob,
    required this.gender,
    required this.aadhaarNumber,
    required this.address,
    this.photoBase64,
  });

  factory AadhaarDetails.fromJson(Map<String, dynamic> json) {
    return AadhaarDetails(
      name: json['name'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      aadhaarNumber: json['aadhaar_number'] ?? '',
      photoBase64: json['photo'],
      address: AadhaarAddress.fromJson(json['address'] ?? {}),
    );
  }
}

class AadhaarAddress {
  final String house;
  final String street;
  final String vtc;
  final String district;
  final String state;
  final String pincode;

  AadhaarAddress({
    required this.house,
    required this.street,
    required this.vtc,
    required this.district,
    required this.state,
    required this.pincode,
  });

  factory AadhaarAddress.fromJson(Map<String, dynamic> json) {
    return AadhaarAddress(
      house: json['house'] ?? '',
      street: json['street'] ?? '',
      vtc: json['vtc'] ?? '',
      district: json['district'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
    );
  }
}
