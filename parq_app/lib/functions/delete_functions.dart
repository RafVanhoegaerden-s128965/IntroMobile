import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/car_model.dart';
import '../models/parking_model.dart';
import '../models/ticket_model.dart';

/// This function deletes a parking.
///
void deleteParking(Parking parking) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('parkings')
      .where('id', isEqualTo: parking.id)
      .get();
  if (snapshot.docs.isNotEmpty) {
    await snapshot.docs.first.reference.delete();
  }
}

/// This function deletes a car.
///
void deleteCar(Car car, Function() callback) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('cars')
      .where('id', isEqualTo: car.id)
      .get();
  if (snapshot.docs.isNotEmpty) {
    await snapshot.docs.first.reference.delete();
    callback();
  }
}

/// This function deletes a car.
///
void deActivateTicket(Ticket ticket) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('tickets')
      .where('id', isEqualTo: ticket.id)
      .get();
  if (snapshot.docs.isNotEmpty) {
    final docId = snapshot.docs.first.id;
    await FirebaseFirestore.instance.collection('tickets').doc(docId).update({
      'active': "false",
    });
  }
}
