import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parq_app/models/car_model.dart';
import '../models/parking_model.dart';
import '../models/ticket_model.dart';
import 'package:http/http.dart' as http;

/// This function gets all the parkings.
///
/// Returns a list "List<Parking> parking".
Future<List<Parking>> getAllParkings() async {
  final snapshotParkings =
      await FirebaseFirestore.instance.collection('parkings').get();
  List<DocumentSnapshot> documentsParkings = snapshotParkings.docs;
  List<Parking> parking = [];
  for (var document in documentsParkings) {
    var data = document.data();
    parking.add(Parking.fromMap(data as Map<String, dynamic>));
  }
  return parking;
}

/// This function gets all the tickets of the current user.
///
/// Returns a list "List<Ticket> tickets".
Future<List<Ticket>> getAllTicketsOfUser(String userId) async {
  final snapshotTickets = await FirebaseFirestore.instance
      .collection('tickets')
      .where('userId', isEqualTo: userId)
      .get();
  List<DocumentSnapshot> documentsTickets = snapshotTickets.docs;
  List<Ticket> tickets = [];
  for (var document in documentsTickets) {
    var data = document.data();
    tickets.add(Ticket.fromMap(data as Map<String, dynamic>));
  }
  return tickets;
}

/// This function gets all the active tickets of the current user.
///
/// Returns a list "List<Ticket> tickets".
Future<List<Ticket>> getAllActiveTicketsOfUser(String userId) async {
  List<Ticket> tickets = await getAllTicketsOfUser(userId);
  List<Ticket> activeTickets = [];
  for (var ticket in tickets) {
    if (ticket.active) {
      activeTickets.add(ticket);
    }
  }
  return activeTickets;
}

/// This function gets all the cars of the current user.
///
/// Returns a list "List<Cars> cars".
Future<List<Car>> getAllCarsOfUser(String userId) async {
  final snapshotCars = await FirebaseFirestore.instance
      .collection('cars')
      .where('userId', isEqualTo: userId)
      .get();
  List<DocumentSnapshot> documentsCars = snapshotCars.docs;
  List<Car> cars = [];
  for (var document in documentsCars) {
    var data = document.data();
    cars.add(Car.fromMap(data as Map<String, dynamic>));
  }
  return cars;
}

/// This function gets all the cars of the current user that are not in use.
///
/// Returns a list "List<Cars> carsNotInUse".
Future<List<Car>> getAllCarsNotInUse(String userId) async {
  List<Ticket> tickets = await getAllTicketsOfUser(userId);
  List<Ticket> activeTickets = await getAllActiveTicketsOfUser(userId);
  List<Car> cars = await getAllCarsOfUser(userId);
  List<Car> carsNotInUse = [];
  if (tickets.isEmpty) {
    carsNotInUse = cars;
  } else {
    for (var car in cars) {
      for (var ticket in activeTickets) {
        if (car.id != ticket.carId) {
          carsNotInUse.add(car);
        }
      }
    }
  }
  return carsNotInUse;
}

/// This function gets the streetname.
///
/// Returns a json "json['address']['road'] ?? ''".
Future<String> getAddress(double lat, double lng) async {
  String url =
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return json['address']['road'] ?? '';
  } else {
    throw Exception('Failed to get address.');
  }
}
