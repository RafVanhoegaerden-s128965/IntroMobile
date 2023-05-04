import 'dart:developer';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/car_model.dart';
import '../models/parking_model.dart';
import '../models/ticket_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
//import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final String? userId;
  const MapPage({super.key, this.userId});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final _formKey = GlobalKey<FormState>();
  //Map rotation
  final MapController _mapController = MapController();
  //Icons
  final _arrowIcon = Image.asset('assets/images/Arrow.png');
  final _parkIcon = Image.asset('assets/images/ParkSpace.png');
  final _carIcon = Image.asset('assets/images/Car.png');
  final _parkIconUser = Image.asset('assets/images/ParkSpaceUser.png');

  //Markers list
  List<Parking> _parkings = [];
  List<Car> _cars = [];
  List<Ticket> _tickets = [];

  // double _latitude = 0;
  // double _longitude = 0;

  // Get user location
  // Future<void> _getCurrentLocation() async {
  //   Position position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);
  //   setState(() {
  //     _latitude = position.latitude;
  //     _longitude = position.longitude;
  //   });
  // }

  //Get database values
  void _getValues() async {
    //Connectie met Firebase
    //Get parkings
    final snapshotParkings =
        await FirebaseFirestore.instance.collection('parkings').get();
    //Lijst maken van alle documenten
    List<DocumentSnapshot> documentsParkings = snapshotParkings.docs;
    List<Parking> parking = [];
    //Itereren over elke document en mappen in parking
    for (var document in documentsParkings) {
      var data = document.data();
      parking.add(Parking.fromMap(data as Map<String, dynamic>));
    }

    /// Get cars
    final snapshotCars = await FirebaseFirestore.instance
        .collection('cars')
        .where('userId', isEqualTo: widget.userId)
        .get();
    List<DocumentSnapshot> documentsCars = snapshotCars.docs;
    List<Car> cars = [];
    for (var document in documentsCars) {
      var data = document.data();
      cars.add(Car.fromMap(data as Map<String, dynamic>));
    }
    //Get tickets for user
    final snapshotTickets = await FirebaseFirestore.instance
        .collection('tickets')
        .where('userId', isEqualTo: widget.userId)
        .get();
    List<DocumentSnapshot> documentsTickets = snapshotTickets.docs;
    List<Ticket> tickets = [];
    for (var document in documentsTickets) {
      var data = document.data();
      tickets.add(Ticket.fromMap(data as Map<String, dynamic>));
    }

    setState(() {
      _parkings = parking;
      log("Total Parkings: ${_parkings.length}");
      var _userParkings =
          _parkings.where((parking) => parking.userId == widget.userId);
      log("User Parkings: ${_userParkings.length}");
      _cars = cars;
      log("User cars: ${_cars.length}");
      _tickets = tickets;
      log("User tickets: ${_tickets.length}");
    });
  }

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

  void _addTicket(Ticket ticket) async {
    await FirebaseFirestore.instance.collection('tickets').add(ticket.toMap());
    setState(() {
      _getValues();
    });
  }

  bool _active = false;
  Future<void> _addParking(Parking parking) async {
    await FirebaseFirestore.instance
        .collection('parkings')
        .add(parking.toMap());
    setState(() {
      _getValues();
    });
  }

  void _deleteParking(Parking parking) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('parkings')
        .where('id', isEqualTo: parking.id)
        .get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
      setState(() {
        _getValues();
      });
    }
  }

  //Build popup
  Widget _buildPopUpParking(BuildContext context, Parking parking) {
    DateTime timeData = parking.time.toDate();
    String time = "${timeData.hour}:${timeData.minute}";
    Car? _selectedCar;
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(parking.car.toString()),
          Text(time),
          DropdownButton(
            items: _cars.map((car) {
              return DropdownMenuItem(
                value: car,
                child: Text('${car.name} ${car.type}'),
              );
            }).toList(),
            onChanged: (selectedCar) {
              setState(() {
                _selectedCar = selectedCar;
                log("Selected carId: ${_selectedCar?.id.toString()}");
              });
            },
            value: _selectedCar,
          ),
          ElevatedButton(
            onPressed: () async {
              //if (_formKey.currentState!.validate()) {
              String carId = _selectedCar!.id;
              String streetName = await getAddress(
                  double.parse(parking.lat), double.parse(parking.lng));
              if (carId.isNotEmpty) {
                Ticket ticket = Ticket(
                  id: parking.id,
                  userId: widget.userId.toString(),
                  carId: carId,
                  lat: parking.lat,
                  lng: parking.lng,
                  street: streetName,
                  time: Timestamp.now(),
                  active: true,
                );
                _deleteParking(parking);
                _addTicket(ticket);
                Navigator.of(context).pop();
              }
              //}
            },
            child: const Text('Park'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getValues();
    //_getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Map',
        ),
      ),
      body: FlutterMap(
        options: MapOptions(
            rotation: 0,
            center: LatLng(51.2310, 4.4137),
            //LatLng(_latitude, _longitude),
            zoom: 14.0,
            maxZoom: 16.0,
            bounds: LatLngBounds(
              LatLng(51.2310, 4.4137),
            ),
            maxBounds: LatLngBounds(
              LatLng(51.2310, 4.4137),
            ),
            keepAlive: true,
            onTap: _active
                ? (position, latlng) {
                    Parking parking = Parking(
                        id: FirebaseFirestore.instance
                            .collection('parkings')
                            .doc()
                            .id,
                        car: "test",
                        userId: widget.userId.toString(),
                        lat: latlng.latitude.toString(),
                        lng: latlng.longitude.toString(),
                        time: Timestamp.now());
                    _addParking(parking);
                  }
                : null),
        mapController: _mapController,
        children: [
          //Tiles
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          //Maker
          MarkerLayer(
            markers: [
              //User
              //TODO use location of users -- Works if location has permission
              Marker(
                point: LatLng(51.2310, 4.4137),
                //LatLng(_latitude, _longitude),
                width: 25,
                height: 25,
                builder: (context) => Transform.rotate(
                  angle: -_mapController.rotation * math.pi / 180,
                  child: _arrowIcon,
                ),
              ),
              //Parking markers op de map
              ..._parkings.map((parking) => Marker(
                    point: LatLng(
                        double.parse(parking.lat), double.parse(parking.lng)),
                    width: 35,
                    height: 35,
                    builder: (context) => GestureDetector(
                        onTap: parking.userId != widget.userId
                            ? () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        _buildPopUpParking(context, parking));
                              }
                            : null,
                        child: Transform.rotate(
                          angle: -_mapController.rotation * math.pi / 180,
                          child: parking.userId == widget.userId
                              ? _parkIconUser
                              : _parkIcon,
                        )),
                  )),
              ..._tickets.map((ticket) => Marker(
                    point: LatLng(
                        double.parse(ticket.lat), double.parse(ticket.lng)),
                    width: 35,
                    height: 35,
                    builder: (context) => GestureDetector(
                        onTap: () {
                          //TODO: Actie wanneer de gebruiker op klikt
                        },
                        child: Transform.rotate(
                          angle: -_mapController.rotation * math.pi / 180,
                          child: _carIcon,
                        )),
                  ))
            ],
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        child: FloatingActionButton(
          child: Icon(_active ? Icons.cancel : Icons.add_location),
          onPressed: () {
            setState(() {
              _active = !_active;
            });
          },
        ),
      ),
    );
  }
}
