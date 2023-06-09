import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  String id;
  String carId;
  String userId;
  String lat;
  String lng;
  String street;
  Timestamp time;
  String active;
  String previousUserIs;

  Ticket(
      {required this.id,
      required this.carId,
      required this.userId,
      required this.lat,
      required this.lng,
      required this.time,
      required this.street,
      required this.active,
      required this.previousUserIs});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'carId': carId,
      'lat': lat,
      'lng': lng,
      'time': time,
      'street': street,
      'active': active,
      'previousUserId': previousUserIs
    };
  }

  factory Ticket.fromMap(Map<Object?, dynamic> map) {
    return Ticket(
        id: map['id'],
        userId: map['userId'],
        carId: map['carId'],
        lat: map['lat'],
        lng: map['lng'],
        time: map['time'],
        street: map['street'],
        active: map['active'],
        previousUserIs: map['previousUserId']);
  }
}
