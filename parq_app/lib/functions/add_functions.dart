import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_model.dart';
import '../models/parking_model.dart';
import '../models/ticket_model.dart';

/// This function adds a new ticket for current user.
///
void addTicket(Ticket ticket) async {
  await FirebaseFirestore.instance.collection('tickets').add(ticket.toMap());
}

/// This function adds a new parking for current user.
///
Future<void> addParking(Parking parking) async {
  await FirebaseFirestore.instance.collection('parkings').add(parking.toMap());
}

/// This function adds a new car for current user.
///
void addCar(Car car) async {
  await FirebaseFirestore.instance.collection('cars').add(car.toMap());
}
