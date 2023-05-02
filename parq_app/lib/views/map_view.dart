import 'dart:developer';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/car_model.dart';
import '../models/parking_model.dart';
//import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  final String? userId;
  const MapPage({super.key, this.userId});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  //Map rotation
  final MapController _mapController = MapController();
  //Icons
  final _arrowIcon = Image.asset('assets/images/Arrow.png');
  final _parkIcon = Image.asset('assets/images/ParkSpace.png');

  //Markers list
  List<Parking> _parkings = [];
  List<Car> _cars = [];
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
    //Get cars
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

    setState(() {
      _parkings = parking;
      log("Parkings: ${_parkings.length}");
      _cars = cars;
      log("User cars: ${_cars.length}");
    });
  }

  //Build popup
  Widget _buildPopUp(BuildContext context, Parking parking) {
    DateTime timeData = parking.time.toDate();
    String time = "${timeData.hour}:${timeData.minute}";
    //TODO buttom action
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(parking.car.toString()),
          Text(time),
          DropdownButton(
            value: null,
            items: _cars.map((car) {
              return DropdownMenuItem(
                value: car,
                child: Text('${car.name} ${car.type}'),
              );
            }).toList(),
            onChanged: (selectedCar) {},
          ),
          ElevatedButton(
            onPressed: () {
              // Hier kun je code toevoegen die wordt uitgevoerd wanneer de knop wordt ingedrukt
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
          ),
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
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    _buildPopUp(context, parking));
                          },
                          child: Transform.rotate(
                            angle: -_mapController.rotation * math.pi / 180,
                            child: _parkIcon,
                          )),
                    )),
              ],
            ),
          ],
        ));
  }
}
