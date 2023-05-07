import 'dart:developer';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:parq_app/functions/add_functions.dart';
import 'package:parq_app/functions/delete_functions.dart';
import 'package:parq_app/functions/get_functions.dart';
import '../models/car_model.dart';
import '../models/parking_model.dart';
import '../models/ticket_model.dart';
import '../models/user_model.dart';
import 'cars_view.dart';
//import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final String? userId;
  const MapPage({super.key, this.userId});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  User? _user;

  /// Sets adding marker on map active
  bool _active = false;
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
  List<Car> _carsNotInUse = [];
  List<Ticket> _tickets = [];
  List<Ticket> _activeTickets = [];

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

  void _getValues() async {
    String userId = widget.userId.toString();
    List<Parking> parkings = await getAllParkings();
    List<Car> cars = await getAllCarsOfUser(userId);
    List<Ticket> tickets = await getAllTicketsOfUser(userId);
    List<Ticket> activeTickets = await getAllActiveTicketsOfUser(userId);
    List<Car> carsNotInUse = await getAllCarsNotInUse(userId);
    //Get users
    Future<void> getUser() async {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: widget.userId)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final userDoc = snapshot.docs.first;
          final userData = userDoc.data();
          final user = User.fromMap(userData);
          setState(() {
            _user = user;
          });
        }
      } catch (error) {
        // Handel eventuele fouten af
        log('Fout bij het ophalen van de gebruikersnaam: $error');
      }
    }

    setState(() {
      getUser();
      _parkings = parkings;
      log("Total Parkings: ${_parkings.length}");
      var userParkings =
          _parkings.where((parking) => parking.userId == widget.userId);
      log("User Parkings: ${userParkings.length}");
      _cars = cars;
      log("User cars: ${_cars.length}");
      _carsNotInUse = carsNotInUse;
      log("User cars not in use: ${_carsNotInUse.length}");
      _tickets = tickets;
      log("User tickets: ${_tickets.length}");
      _activeTickets = activeTickets;
      log("Active user tickets: ${_activeTickets.length}");
    });
  }

  //Build popup GreenParking
  Widget _buildPopUpGreenParking(BuildContext context, Parking parking) {
    DateTime timeData = parking.time.toDate();
    //TODO: time when leaving
    String time = "${timeData.hour}:${timeData.minute}";
    Car? selectedCar;

    return AlertDialog(
        title: const Text('Parking'),
        content: SizedBox(
            height: 105,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                //TODO: show option to set time
                Text('Start Time: ${time}'),
                //TODO: show car color
                Text('Parked: ${parking.car.toString()}'),
                //TODO: get username
                Text('User: '),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //const Text("Choose Car:"),
                    DropdownButton(
                      items: _carsNotInUse.isNotEmpty
                          ? _carsNotInUse.map((car) {
                              return DropdownMenuItem(
                                value: car,
                                child: Text('${car.brand} ${car.type}'),
                              );
                            }).toList()
                          //TODO: Error Handle if list == null
                          : null,
                      onChanged: (car) {
                        setState(() {
                          selectedCar = car;
                          log("Selected carId: ${selectedCar?.id.toString()}");
                        });
                      },
                      value: selectedCar,
                    ),
                  ],
                )
              ],
            )),
        actions: <Widget>[
          ElevatedButton(
              onPressed: () {
                // Navigeer naar car page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CarPage(
                      userId: _user!.id,
                    ),
                  ),
                );
              },
              child: const Text('Change car')),
          ElevatedButton(
            onPressed: () async {
              String carId = selectedCar!.id;
              if (carId.isNotEmpty) {
                String streetName = await getAddress(
                    double.parse(parking.lat), double.parse(parking.lng));
                Ticket ticket = Ticket(
                  id: parking.id,
                  userId: widget.userId.toString(),
                  carId: carId,
                  lat: parking.lat,
                  lng: parking.lng,
                  street: streetName,
                  time: Timestamp.now(),
                  active: "true",
                );
                addTicket(ticket);
                deleteParking(parking);
                Navigator.of(context).pop();
              }
              setState(() {
                print('test');
                _getValues();
              });
            },
            child: const Text('Park'),
          ),
        ]);
  }

  @override
  void initState() {
    super.initState();
    _getValues();
    //_getCurrentLocation();
  }

  Future<void> _showSetTimePopUp(
      BuildContext context, Car car, Ticket ticket) async {
    DateTime selectedTime = DateTime.now();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Time'),
          content: SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              initialDateTime: selectedTime,
              onDateTimeChanged: (DateTime newDateTime) {
                selectedTime = newDateTime;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                addParking(Parking(
                    id: FirebaseFirestore.instance
                        .collection('parkings')
                        .doc()
                        .id,
                    car: car.brand,
                    userId: car.userId,
                    lat: ticket.lat,
                    lng: ticket.lng,
                    time: Timestamp.fromDate(selectedTime)));
                deActivateTicket(ticket);
                Navigator.of(context).pop();
                setState(() {
                  _getValues();
                });
              },
            ),
          ],
        );
      },
    );
  }

  //build popup ticket
  Future<Widget> buildPopUpTicket(BuildContext context, Ticket ticket) async {
    DateTime timeData = ticket.time.toDate();
    String time = "${timeData.hour}:${timeData.minute}";
    Car car = await getCarWithId(ticket.carId);
    return AlertDialog(
      title: const Text('Ticket details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Car: ${car.brand}'),
          Text('Street: ${ticket.street}'),
          Text('Time parked: $time'),
        ],
      ),
      actions: [
        ElevatedButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Leave'),
          onPressed: () async {
            Navigator.of(context).pop();
            await _showSetTimePopUp(context, car, ticket);
          },
        ),
      ],
    );
  }

  //build popup RedParking
  Widget _buildPopUpRedParking(BuildContext context, Parking parking) {
    return AlertDialog(
        title: const Text('Own Parking'),
        content: SizedBox(
            height: 100,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [],
            )));
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
            zoom: 16.0,
            maxZoom: 18.0,
            minZoom: 14.0,
            maxBounds: LatLngBounds(
              LatLng(51.2210, 4.4037),
              LatLng(51.2410, 4.4237),
            ),
            keepAlive: true,
            onTap: _active
                ? (position, latlng) {
                    Parking parking = Parking(
                        id: FirebaseFirestore.instance
                            .collection('parkings')
                            .doc()
                            .id,
                        car: _carsNotInUse.isNotEmpty
                            ? _carsNotInUse.first.brand
                            //TODO: Error handling if carlist = empty
                            : "error",
                        userId: widget.userId.toString(),
                        lat: latlng.latitude.toString(),
                        lng: latlng.longitude.toString(),
                        time: Timestamp.now());
                    addParking(parking);
                    setState(() {
                      _getValues();
                      _active = !_active;
                    });
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
              //TODO: use location of users -- function in comment (fix error)
              Marker(
                point: LatLng(51.2310, 4.4137),
                //LatLng(_latitude, _longitude),
                width: 25,
                height: 25,
                builder: (context) => Transform.rotate(
                  angle: -(_mapController.rotation - 15) * math.pi / 180,
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
                                        _buildPopUpGreenParking(
                                            context, parking));
                              }
                            : () {
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        _buildPopUpRedParking(
                                            context, parking));
                              }, //TODO: user krijgt andere popup voor zijn eigen parkings??
                        child: Transform.rotate(
                          angle: -_mapController.rotation * math.pi / 180,
                          child: parking.userId == widget.userId
                              ? _parkIconUser
                              : _parkIcon,
                        )),
                  )),
              ..._activeTickets.map((ticket) => Marker(
                    point: LatLng(
                        double.parse(ticket.lat), double.parse(ticket.lng)),
                    width: 35,
                    height: 35,
                    builder: (context) => GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return FutureBuilder<Widget>(
                                future: buildPopUpTicket(context, ticket),
                                builder: (BuildContext context,
                                    AsyncSnapshot<Widget> snapshot) {
                                  if (snapshot.hasData) {
                                    return snapshot.data!;
                                  } else {
                                    return const CircularProgressIndicator();
                                  }
                                },
                              );
                            },
                          );
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
