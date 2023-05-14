import 'dart:async';
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
import 'package:parq_app/main.dart';
import '../models/car_model.dart';
import '../models/parking_model.dart';
import '../models/ticket_model.dart';
import '../models/user_model.dart';
import 'cars_view.dart';
import 'package:intl/intl.dart';

class MapPage extends StatefulWidget {
  final String? userId;
  const MapPage({super.key, this.userId});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  User? _user;

  // Sets adding marker on map active
  bool _active = false;

  // Position
  final currentPosition = LatLng(51.2310, 4.4137);

  late Timer _timer;
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

    //SetState
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

  void _getMapMarkers() async {
    String userId = widget.userId.toString();
    List<Ticket> activeTickets = await getAllActiveTicketsOfUser(userId);
    List<Parking> parkings = await getAllParkings();
    setState(() {
      _parkings = parkings;
      var userParkings =
          _parkings.where((parking) => parking.userId == widget.userId);
      _activeTickets = activeTickets;
      // log("Auto refresh values: [ ALL PARKINGS: ${_parkings.length} ] - [ USER PARKINGS: ${userParkings.length} ] - [ ACTIVE USER TICKETS:  ${_activeTickets.length} ]");
      //Print with colors
      log("\x1b[36mAuto refresh values: \x1b[0m[ \x1b[32mALL PARKINGS: ${_parkings.length}\x1b[0m ] - [ \x1b[31mUSER PARKINGS: ${userParkings.length}\x1b[0m ] - [ \x1b[34mACTIVE USER TICKETS: ${_activeTickets.length}\x1b[0m ]");

      DateTime now = DateTime.now();
      for (var parking in _parkings) {
        DateTime parkingTime = parking.time.toDate();
        if (parkingTime.isBefore(now)) {
          deleteParking(parking);
          _getValues();
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getValues();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        _getMapMarkers();
      } else {
        // cancel the timer
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    // cancel the timer
    _timer.cancel();
    super.dispose();
  }

  Future<void> showSetTimePopUpTicket(
      BuildContext context, Car car, Ticket ticket) async {
    DateTime selectedTime = DateTime.now();
    bool isSaveEnabled = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Set Time'),
              content: SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  initialDateTime: selectedTime.add(const Duration(minutes: 2)),
                  minimumDate: DateTime.now().add(const Duration(minutes: 1)),
                  onDateTimeChanged: (DateTime newDateTime) {
                    selectedTime = newDateTime;
                    setState(() {
                      isSaveEnabled = newDateTime.isAfter(
                          DateTime.now().add(const Duration(minutes: 2)));
                    });
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
                  onPressed: isSaveEnabled
                      ? () {
                          addParking(Parking(
                              id: FirebaseFirestore.instance
                                  .collection('parkings')
                                  .doc()
                                  .id,
                              carId: car.id,
                              userId: car.userId,
                              lat: ticket.lat,
                              lng: ticket.lng,
                              time: Timestamp.fromDate(selectedTime)));
                          deActivateTicket(ticket);
                          Navigator.of(context).pop();
                          setState(() {
                            _getValues();
                          });
                        }
                      : null,
                  child: Text(
                    'Save',
                    style: TextStyle(
                        color: isSaveEnabled ? Colors.blue : Colors.grey),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
          Text('Car: ${car.brand} ${car.type} ${car.color}'),
          Text('Street: ${ticket.street}'),
          Text('Time parked: $time'),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Leave'),
          onPressed: () async {
            Navigator.of(context).pop();
            await showSetTimePopUpTicket(context, car, ticket);
          },
        ),
      ],
    );
  }

  //Rate-Popup -- TODO: finish method
  Future<void> showRatePopup(BuildContext context, Parking parking) async {
    final _ratingController = TextEditingController();
    User user = await getUserWithId(parking.userId);

    // Use a new context from the parent widget
    BuildContext dialogContext;
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder: (BuildContext context) {
        dialogContext = context;
        return AlertDialog(
          title: const Text('Rate'),
          content: SizedBox(
            height: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User: ${user.username}'),
                const Text('Rate this user on a scale of 1/5:'),
                TextFormField(
                  controller: _ratingController,
                  decoration: const InputDecoration(labelText: 'Rating'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a rating.';
                    }
                    if (value != '1' &&
                        value != '2' &&
                        value != '3' &&
                        value != '4' &&
                        value != '5') {
                      return 'Please enter a valid rating';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Rate'),
              onPressed: () async {
                String ratingStr = _ratingController.text;
                int rating = int.parse(ratingStr);
                await rateUser(user.id, rating);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> rateUser(String userId, int rating) async {
    User user = await getUserWithId(userId);

    final numRatings = user.numRatings;
    final totalRating = user.totalRating;
    final newNumRatings = numRatings + 1;
    final newTotalRating = totalRating + rating;
    final newAvgRating = newTotalRating / newNumRatings;
    // TODO: Implement rating logic, e.g. save rating to database
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: userId)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;

        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'numRatings': newNumRatings,
          'totalRating': newTotalRating,
          'avgRating': newAvgRating
        });
        setState(() {
          _getValues();
          log('numRatings: ${user.numRatings}');
          log('avgRating: ${user.avgRating}');
          log('totalRating: ${user.totalRating}');
        });
      } else {
        log('User not found in database.');
      }
    } catch (e) {
      log('Failed to update rating: $e');
    }
  }

  Future<Widget> buildPopUpGreenParking(
      BuildContext context, Parking parking) async {
    //Time variables
    DateTime timeData = parking.time.toDate();
    String time = "${timeData.hour}:${timeData.minute}";

    User user = await getUserWithId(parking.userId);
    Car car = await getCarWithId(parking.carId);
    Car? selectedCar = _carsNotInUse.isNotEmpty ? _carsNotInUse[0] : null;

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return AlertDialog(
          title: const Text('Parking'),
          content: SizedBox(
            height: 105,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Start Time: $time'),
                Text('Parked: ${car.brand} ${car.type} ${car.color}'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('User: ${user.username}'),
                    Text('Rating: ${user.avgRating.toStringAsFixed(1)}/5'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Choose Car:"),
                    _carsNotInUse.isNotEmpty
                        ? DropdownButton(
                            value: selectedCar,
                            onChanged: (car) {
                              setState(() {
                                selectedCar = car;
                                log("Selected carId: ${selectedCar?.id.toString()}");
                                log("Selected car: ${selectedCar?.brand} ${selectedCar?.type}");
                              });
                            },
                            items: _carsNotInUse.map((car) {
                              return DropdownMenuItem(
                                value: car,
                                child: Text('${car.brand} ${car.type}'),
                              );
                            }).toList())
                        : const Text('All cars in use'),
                  ],
                )
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            _carsNotInUse.isNotEmpty
                ? TextButton(
                    child: const Text('Park'),
                    onPressed: () async {
                      if (selectedCar != null) {
                        String streetName = await getAddress(
                            double.parse(parking.lat),
                            double.parse(parking.lng));
                        Ticket ticket = Ticket(
                          id: parking.id,
                          userId: widget.userId.toString(),
                          carId: selectedCar!.id,
                          lat: parking.lat,
                          lng: parking.lng,
                          street: streetName,
                          time: Timestamp.now(),
                          active: "true",
                        );
                        addTicket(ticket);
                        deleteParking(parking);
                        Navigator.of(context).pop();
                        await showRatePopup(context, parking);
                      }
                    },
                  )
                : TextButton(
                    child: const Text('Add car'),
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
                  ),
          ],
        );
      },
    );
  }

  Future<void> buildPopUpRedParking(position, lat, lng) async {
    Car? selectedCar = _carsNotInUse.isNotEmpty ? _carsNotInUse[0] : null;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Choose a car'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    _carsNotInUse.isNotEmpty
                        ? DropdownButton(
                            value: selectedCar,
                            onChanged: (car) {
                              setState(() {
                                selectedCar = car;
                                log("Selected carId: ${selectedCar?.id.toString()}");
                                log("Selected car: ${selectedCar?.brand} ${selectedCar?.type}");
                              });
                            },
                            items: _carsNotInUse.map((car) {
                              return DropdownMenuItem(
                                value: car,
                                child: Text('${car.brand} ${car.type}'),
                              );
                            }).toList(),
                          )
                        : const Text("All cars in use"),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _active = !_active;
                    });
                  },
                ),
                _carsNotInUse.isNotEmpty
                    ? TextButton(
                        child: const Text('Set time'),
                        onPressed: () async {
                          Car car = await getCarWithId(selectedCar!.id);
                          Navigator.of(context).pop();
                          await showSetTimePopUpAddParking(
                              context, car, lat, lng);
                        },
                      )
                    : TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CarPage(
                                userId: _user!.id,
                              ),
                            ),
                          );
                        },
                        child: const Text('Add car'),
                      ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> showSetTimePopUpAddParking(
      BuildContext context, Car car, lat, lng) async {
    DateTime selectedTime = DateTime.now();
    bool isSaveEnabled = false;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Set Time'),
            content: SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                initialDateTime: selectedTime.add(const Duration(minutes: 2)),
                minimumDate: DateTime.now().add(const Duration(minutes: 1)),
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    selectedTime = newDateTime;
                    isSaveEnabled = selectedTime.isAfter(
                        DateTime.now().add(const Duration(minutes: 2)));
                  });
                },
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _active = !_active;
                  });
                },
              ),
              TextButton(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(
                      isSaveEnabled ? Colors.blue : Colors.grey),
                ),
                onPressed: isSaveEnabled
                    ? () {
                        addParking(Parking(
                            id: FirebaseFirestore.instance
                                .collection('parkings')
                                .doc()
                                .id,
                            carId: car.id,
                            userId: car.userId,
                            lat: lat.toString(),
                            lng: lng.toString(),
                            time: Timestamp.fromDate(selectedTime)));
                        Navigator.of(context).pop();
                        setState(() {
                          _getValues();
                          _active = !_active;
                        });
                      }
                    : null,
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
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
            zoom: 16.0,
            maxZoom: 18.0,
            minZoom: 14.0,
            maxBounds: LatLngBounds(
              LatLng(51.2210, 4.4037),
              LatLng(51.2410, 4.4237),
            ),
            keepAlive: true,
            onTap: _active
                ? (position, latlng) async {
                    await buildPopUpRedParking(
                        position, latlng.latitude, latlng.longitude);
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
              Marker(
                point: LatLng(51.2310, 4.4137),
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
                                    builder: (BuildContext context) {
                                      return FutureBuilder<Widget>(
                                        future: buildPopUpGreenParking(
                                            context, parking),
                                        builder: (BuildContext context,
                                            AsyncSnapshot<Widget> snapshot) {
                                          if (snapshot.hasData) {
                                            return snapshot.data!;
                                          } else {
                                            return const CircularProgressIndicator();
                                          }
                                        },
                                      );
                                    });
                              }
                            : () {
                                // showDialog(
                                //     context: context,
                                //     builder: (BuildContext context) =>
                                //         );
                              },
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
      floatingActionButton: Stack(children: <Widget>[
        Positioned(
          bottom: 10,
          right: 10,
          child: FloatingActionButton(
            heroTag: 'Right',
            child: Icon(_active ? Icons.cancel : Icons.add_location_alt),
            onPressed: () {
              setState(() {
                _active = !_active;
              });
            },
          ),
        ),
        Positioned(
          bottom: 10,
          left: 40,
          child: FloatingActionButton(
            heroTag: 'Left',
            child: const Icon(Icons.add_location_alt_outlined),
            onPressed: () {
              buildPopUpRedParking(currentPosition, currentPosition.latitude,
                      currentPosition.longitude)
                  .then((_) {
                setState(() {
                  log('Current position: ${currentPosition}');
                });
              });
            },
          ),
        )
      ]),
    );
  }
}
