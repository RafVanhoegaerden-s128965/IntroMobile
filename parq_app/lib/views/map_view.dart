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
import '../models/car_model.dart';
import '../models/parking_model.dart';
import '../models/ticket_model.dart';
import '../models/user_model.dart';
import 'cars_view.dart';

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

  // Sets filtered markers on map active
  bool _isFiltered = false;

  // Sets after dispose active
  bool _isDisposed = false;

  // Position
  final currentPosition = LatLng(51.2310, 4.4137);

  //Map rotation
  final MapController _mapController = MapController();

  // Timer
  late Timer _timer;

  // Icons
  final _arrowIcon = Image.asset('assets/images/Arrow.png');
  final _parkIcon = Image.asset('assets/images/ParkSpace.png');
  final _carIcon = Image.asset('assets/images/Car.png');
  final _parkIconUser = Image.asset('assets/images/ParkSpaceUser.png');

  // Parking list
  List<Parking> _parkings = [];

  // Car lists
  List<Car> _cars = [];
  List<Car> _carsNotInUse = [];

  // Ticket lists
  List<Ticket> _tickets = [];
  List<Ticket> _activeTickets = [];

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
    _isDisposed = true;
    super.dispose();
  }

  void _getValues() async {
    String userId = widget.userId.toString();
    List<Parking> parkings = await getAllParkings();
    List<Car> cars = await getAllCarsOfUser(userId);
    List<Ticket> tickets = await getAllTicketsOfUser(userId);
    List<Ticket> activeTickets = await getAllActiveTicketsOfUser(userId);
    List<Car> carsNotInUse = await getAllCarsNotInUse(userId);

    //Get user
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
    if (!_isDisposed) {
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
  }

  void _getMapMarkers() async {
    String userId = widget.userId.toString();
    List<Ticket> activeTickets = await getAllActiveTicketsOfUser(userId);
    List<Parking> parkings = await getAllParkings();
    if (!_isDisposed) {
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
  }

  // Ticket popups
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
    String time =
        "${timeData.hour}:${timeData.minute.toString().padLeft(2, '0')} ${timeData.day}/${timeData.month}";
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

  // Parking popups
  Future<Widget> buildPopUpGreenParking(Parking parking) async {
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
                Text('Leaving Time: $time'),
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
                            previousUserIs: parking.userId);
                        addTicket(ticket);
                        deleteParking(parking);
                        Navigator.of(context).pop();
                      }
                    },
                  )
                : TextButton(
                    child: const Text('Add car'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                          builder: (context) => CarPage(
                            userId: _user!.id,
                          ),
                        ),
                      )
                          .then((_) async {
                        _carsNotInUse =
                            await getAllCarsNotInUse(widget.userId.toString());
                        buildPopUpGreenParking(parking);
                      });
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
                      if (_active) {
                        _active = !_active;
                      }
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
                          Navigator.of(context).pop();
                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (context) => CarPage(
                                userId: _user!.id,
                              ),
                            ),
                          )
                              .then((_) async {
                            _carsNotInUse = await getAllCarsNotInUse(
                                widget.userId.toString());
                            buildPopUpRedParking(position, lat, lng);
                          });
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
                    if (_active) {
                      _active = !_active;
                    }
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
                          if (_active) {
                            _active = !_active;
                          }
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

  Future<void> buildPopUpRedEdit(Parking parking, Car car) async {
    DateTime timeData = parking.time.toDate();
    String selectedTime = "${timeData.hour}:${timeData.minute}";
    bool isSaveEnabled = false;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Own parking'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Car: ${car.brand} ${car.type} ${car.color}'),
                  Row(
                    children: [
                      const Text('Time leaving: '),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext builder) {
                                return SizedBox(
                                  height: MediaQuery.of(context)
                                          .copyWith()
                                          .size
                                          .height /
                                      3,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: CupertinoDatePicker(
                                          mode: CupertinoDatePickerMode
                                              .dateAndTime,
                                          initialDateTime: timeData,
                                          minimumDate: DateTime.now()
                                              .add(const Duration(minutes: 1)),
                                          onDateTimeChanged:
                                              (DateTime newDateTime) {
                                            setState(() {
                                              isSaveEnabled = newDateTime
                                                  .isAfter(DateTime.now().add(
                                                      const Duration(
                                                          minutes: 2)));
                                              if (isSaveEnabled) {
                                                timeData = newDateTime;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      CupertinoButton(
                                        child: const Text('Close'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Text(
                            selectedTime,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () {
                    deleteParking(parking);
                    setState(() {
                      _getValues();
                    });
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  onPressed: isSaveEnabled
                      ? () {
                          setState(() {
                            _editParking(parking, Timestamp.fromDate(timeData));
                            _getValues();
                          });
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: Text(
                    'Change time',
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

  // Edit parking
  Future<void> _editParking(Parking parking, Timestamp time) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('parkings')
          .where('id', isEqualTo: parking.id)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        await FirebaseFirestore.instance
            .collection('parkings')
            .doc(docId)
            .update({
          'time': time,
        });
        setState(() {
          _getValues();
        });
      } else {
        log('Car not found in database.');
      }
    } catch (e) {
      log('Failed to update car: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Map',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
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
                //Maker TODO: implement filteredMarkers -- first add correct markers to the lists
                MarkerLayer(
                    markers: !_isFiltered
                        ? [
                            //User
                            Marker(
                              point: LatLng(51.2310, 4.4137),
                              width: 25,
                              height: 25,
                              builder: (context) => Transform.rotate(
                                angle: -(_mapController.rotation - 15) *
                                    math.pi /
                                    180,
                                child: _arrowIcon,
                              ),
                            ),
                            //Parking markers op de map
                            ..._parkings.map((parking) => Marker(
                                  point: LatLng(double.parse(parking.lat),
                                      double.parse(parking.lng)),
                                  width: 35,
                                  height: 35,
                                  builder: (context) => GestureDetector(
                                      onTap: parking.userId != widget.userId
                                          ? () {
                                              showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return FutureBuilder<
                                                        Widget>(
                                                      future:
                                                          buildPopUpGreenParking(
                                                              parking),
                                                      builder: (BuildContext
                                                              context,
                                                          AsyncSnapshot<Widget>
                                                              snapshot) {
                                                        if (snapshot.hasData) {
                                                          return snapshot.data!;
                                                        } else {
                                                          return const CircularProgressIndicator();
                                                        }
                                                      },
                                                    );
                                                  });
                                            }
                                          : () async {
                                              Car? car = await getCarWithId(
                                                  parking.carId);
                                              buildPopUpRedEdit(parking, car);
                                            },
                                      child: Transform.rotate(
                                        angle: -_mapController.rotation *
                                            math.pi /
                                            180,
                                        child: parking.userId == widget.userId
                                            ? _parkIconUser
                                            : _parkIcon,
                                      )),
                                )),
                            ..._activeTickets.map((ticket) => Marker(
                                  point: LatLng(double.parse(ticket.lat),
                                      double.parse(ticket.lng)),
                                  width: 35,
                                  height: 35,
                                  builder: (context) => GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return FutureBuilder<Widget>(
                                              future: buildPopUpTicket(
                                                  context, ticket),
                                              builder: (BuildContext context,
                                                  AsyncSnapshot<Widget>
                                                      snapshot) {
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
                                        angle: -_mapController.rotation *
                                            math.pi /
                                            180,
                                        child: _carIcon,
                                      )),
                                ))
                          ]
                        : [
                            //User
                            Marker(
                              point: LatLng(51.2310, 4.4137),
                              width: 25,
                              height: 25,
                              builder: (context) => Transform.rotate(
                                angle: -(_mapController.rotation - 15) *
                                    math.pi /
                                    180,
                                child: _arrowIcon,
                              ),
                            ),
                            ..._activeTickets.map((ticket) => Marker(
                                  point: LatLng(double.parse(ticket.lat),
                                      double.parse(ticket.lng)),
                                  width: 35,
                                  height: 35,
                                  builder: (context) => GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return FutureBuilder<Widget>(
                                              future: buildPopUpTicket(
                                                  context, ticket),
                                              builder: (BuildContext context,
                                                  AsyncSnapshot<Widget>
                                                      snapshot) {
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
                                        angle: -_mapController.rotation *
                                            math.pi /
                                            180,
                                        child: _carIcon,
                                      )),
                                ))
                          ]),
              ],
            ),
          )
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
        ),
        if (_activeTickets.isNotEmpty)
          Positioned(
            top: 130,
            right: 10,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isFiltered = !_isFiltered;
                  log('Filtered: $_isFiltered');
                });
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  _isFiltered ? Colors.blue : Colors.grey,
                ),
              ),
              child: Text(
                _isFiltered ? 'Unfilter' : 'Filter',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
