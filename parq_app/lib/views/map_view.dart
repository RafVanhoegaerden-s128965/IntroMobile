import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../parking_model.dart';

class MapPage extends StatefulWidget {
  final String? userId;
  const MapPage({super.key, this.userId});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  //Icons
  final _arrowIcon = Image.asset('assets/images/Arrow.png');
  final _parkIcon = Image.asset('assets/images/ParkSpace.png');

  //Markers list
  List<Parking> _parkings = [];
  void _getValues() async {
    //Connectie met Firebase
    final snapshot =
        await FirebaseFirestore.instance.collection('parkings').get();

    //Lijst maken van alle documenten
    List<DocumentSnapshot> documents = snapshot.docs;
    List<Parking> parking = [];
    //Itereren over elke document en mapen in parking
    for (var document in documents) {
      var data = document.data();
      parking.add(Parking.fromMap(data as Map<String, dynamic>));
    }
    setState(() {
      _parkings = parking;
      print(_parkings.length);
    });
  }

  //Methods
  Widget _buildPopUp(BuildContext context, Parking parking) {
    DateTime timeData = parking.time.toDate();
    String time = "${timeData.hour}:${timeData.minute}";
    //TODO user database variables in this popup
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(parking.car.toString()),
          Text(time),
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
            center: LatLng(51.23102822083908, 4.413773416730323),
            zoom: 16.0,
            maxZoom: 16.0,
            bounds: LatLngBounds(
              LatLng(51.23102822083908, 4.413773416730323),
            ),
            maxBounds: LatLngBounds(
              LatLng(51.2310, 4.4137),
            ),
            keepAlive: true,
          ),
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
                //TODO use location of users
                Marker(
                  point: LatLng(51.2302, 4.4137),
                  width: 25,
                  height: 25,
                  builder: (context) => _arrowIcon,
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
                                _buildPopUp(context, parking),
                          );
                        },
                        child: _parkIcon,
                      ),
                    )),
              ],
            ),
          ],
        ));
  }
}
