import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parq_app/models/car_model.dart';
import '../models/parking_model.dart';
import '../models/ticket_model.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

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
    if (ticket.active == "true") {
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
  List<Ticket> activeTickets = await getAllActiveTicketsOfUser(userId);
  List<Parking> parkings = await getAllParkings();
  List<Parking> userParkings = [];
  for (var parking in parkings) {
    if (parking.userId == userId) {
      userParkings.add(parking);
    }
  }
  List<Car> cars = await getAllCarsOfUser(userId);
  List<Car> carsNotInUse = [];
  if (activeTickets.isEmpty && userParkings.isEmpty) {
    carsNotInUse = cars;
  } else {
    for (var car in cars) {
      bool inUseT = false;
      for (var ticket in activeTickets) {
        if (car.id == ticket.carId) {
          inUseT = true;
          break;
        }
      }
      bool inUseP = false;
      for (var parking in userParkings) {
        if (car.id == parking.carId) {
          inUseP = true;
          break;
        }
      }
      if (!inUseT && !inUseP) {
        carsNotInUse.add(car);
      }
    }
  }
  return carsNotInUse;
}

///This function gets the user with the given Id
///
///Returns a user
Future<User> getUserWithId(String userId) async {
  late User getUser;
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('id', isEqualTo: userId)
      .get();
  if (snapshot.docs.isNotEmpty) {
    final userDoc = snapshot.docs.first;
    final userData = userDoc.data();
    final user = User.fromMap(userData);
    getUser = user;
  }
  return getUser;
}

///This function gets the car with the given Id
///
///Returns a car
Future<Car> getCarWithId(String carId) async {
  late Car getCar;
  final snapshot = await FirebaseFirestore.instance
      .collection('cars')
      .where('id', isEqualTo: carId)
      .get();

  if (snapshot.docs.isNotEmpty) {
    final carDoc = snapshot.docs.first;
    final carData = carDoc.data();
    final car = Car.fromMap(carData);
    getCar = car;
  }
  return getCar;
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
