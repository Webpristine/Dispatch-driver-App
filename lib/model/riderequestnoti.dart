// To parse this JSON data, do
//
//     final rideRequestModel = rideRequestModelFromJson(jsonString);

import 'dart:convert';

RideRequestModel rideRequestModelFromJson(String str) =>
    RideRequestModel.fromJson(json.decode(str));

String rideRequestModelToJson(RideRequestModel data) =>
    json.encode(data.toJson());

class RideRequestModel {
  String sound;
  String dropAddress;
  String pickupAddress;
  String vibrate;
  String body;
  String title;
  String dropLong;
  String badge;
  String bookingNumber;
  String dropLat;
  String pickupLong;
  String customerName;
  String customerId;
  String pickupLat;
  String customerImage;

  RideRequestModel({
    required this.sound,
    required this.dropAddress,
    required this.pickupAddress,
    required this.vibrate,
    required this.body,
    required this.title,
    required this.dropLong,
    required this.badge,
    required this.bookingNumber,
    required this.dropLat,
    required this.pickupLong,
    required this.customerName,
    required this.customerId,
    required this.pickupLat,
    required this.customerImage,
  });

  factory RideRequestModel.fromJson(Map<String, dynamic> json) =>
      RideRequestModel(
        sound: json["sound"],
        dropAddress: json["drop_address"],
        pickupAddress: json["pickup_address"],
        vibrate: json["vibrate"],
        body: json["body"],
        title: json["title"],
        dropLong: json["drop_long"],
        badge: json["badge"],
        bookingNumber: json["booking_number"],
        dropLat: json["drop_lat"],
        pickupLong: json["pickup_long"],
        customerName: json["customer_name"],
        customerId: json["customer_id"],
        pickupLat: json["pickup_lat"],
        customerImage: json["customer_image"],
      );

  Map<String, dynamic> toJson() => {
        "sound": sound,
        "drop_address": dropAddress,
        "pickup_address": pickupAddress,
        "vibrate": vibrate,
        "body": body,
        "title": title,
        "drop_long": dropLong,
        "badge": badge,
        "booking_number": bookingNumber,
        "drop_lat": dropLat,
        "pickup_long": pickupLong,
        "customer_name": customerName,
        "customer_id": customerId,
        "pickup_lat": pickupLat,
        "customer_image": customerImage,
      };
}
