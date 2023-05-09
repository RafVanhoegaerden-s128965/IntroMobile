import 'package:cloud_firestore/cloud_firestore.dart';

class Parking {
  String id;
  String carId;
  String userId;
  String lat;
  String lng;
  Timestamp time;

  Parking({
    required this.id,
    required this.carId,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'carId': carId,
      'lat': lat,
      'lng': lng,
      'time': time,
    };
  }

  factory Parking.fromMap(Map<Object?, dynamic> map) {
    return Parking(
      id: map['id'],
      userId: map['userId'],
      carId: map['carId'],
      lat: map['lat'],
      lng: map['lng'],
      time: map['time'],
    );
  }
}
