import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  //Icons
  final _arrowIcon = Image.asset('assets/images/Arrow.png');
  final _parkIcon = Image.asset('assets/images/ParkSpace.png');

  //TODO Database Refernces
  void _getValues() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('parkings').get();
  }

  //Methods
  Widget _buildPopUp(BuildContext context) {
    //TODO user database variables in this popup
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
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
                Marker(
                    point: LatLng(51.2295, 4.4151),
                    width: 35,
                    height: 35,
                    builder: (context) => GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  _buildPopUp(context),
                            );
                          },
                          child: _parkIcon,
                        ))
              ],
            ),
          ],
        ));
  }
}
