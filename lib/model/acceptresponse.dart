// To parse this JSON data, do
//
//     final acceptResponse = acceptResponseFromJson(jsonString);

import 'dart:convert';

AcceptResponse acceptResponseFromJson(String str) =>
    AcceptResponse.fromJson(json.decode(str));

String acceptResponseToJson(AcceptResponse data) => json.encode(data.toJson());

class AcceptResponse {
  int code;
  String mesage;
  String timestamp;
  String driverId;
  String customerId;
  String customerName;
  String customerMobile;
  String customerRating;
  String customerPhoto;
  String pickupNotes;
  PLocation pickupLocation;
  List<PLocation> dropLocation;

  AcceptResponse({
    required this.code,
    required this.mesage,
    required this.timestamp,
    required this.driverId,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.customerRating,
    required this.customerPhoto,
    required this.pickupNotes,
    required this.pickupLocation,
    required this.dropLocation,
  });

  factory AcceptResponse.fromJson(Map<String, dynamic> json) => AcceptResponse(
        code: json["code"],
        mesage: json["mesage"],
        timestamp: json["timestamp"],
        driverId: json["driver_id"],
        customerId: json["customer_id"],
        customerName: json["customer_name"],
        customerMobile: json["customer_mobile"],
        customerRating: json["customer_rating"],
        customerPhoto: json["customer_photo"],
        pickupNotes: json["pickup_notes"],
        pickupLocation: PLocation.fromJson(json["pickup_location"]),
        dropLocation: List<PLocation>.from(
            json["drop_location"].map((x) => PLocation.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "code": code,
        "mesage": mesage,
        "timestamp": timestamp,
        "driver_id": driverId,
        "customer_id": customerId,
        "customer_name": customerName,
        "customer_mobile": customerMobile,
        "customer_rating": customerRating,
        "customer_photo": customerPhoto,
        "pickup_notes": pickupNotes,
        "pickup_location": pickupLocation.toJson(),
        "drop_location":
            List<dynamic>.from(dropLocation.map((x) => x.toJson())),
      };
}

class PLocation {
  String lat;
  String long;
  String address;

  PLocation({
    required this.lat,
    required this.long,
    required this.address,
  });

  factory PLocation.fromJson(Map<String, dynamic> json) => PLocation(
        lat: json["lat"],
        long: json["long"],
        address: json["address"],
      );

  Map<String, dynamic> toJson() => {
        "lat": lat,
        "long": long,
        "address": address,
      };
}
