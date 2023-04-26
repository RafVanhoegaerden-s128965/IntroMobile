import 'package:cloud_firestore/cloud_firestore.dart';

class Parking {
  String car;
  String userId;
  String lat;
  String lng;
  Timestamp time;

  Parking({
    required this.car,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'car': car,
      'lat': lat,
      'lng': lng,
      'time': time,
    };
  }

  factory Parking.fromMap(Map<Object?, dynamic> map) {
    return Parking(
      userId: map['userId'],
      car: map['car'],
      lat: map['lat'],
      lng: map['lng'],
      time: map['time'],
    );
  }
}
