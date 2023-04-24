import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

//Icons
final _arrowIcon = Image.asset('assets/images/Arrow.png');

class MapPage extends StatelessWidget {
  const MapPage({super.key});

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
            //Maker TODO use location of users
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(51.2302, 4.4137),
                  width: 25,
                  height: 25,
                  builder: (context) => _arrowIcon,
                ),
              ],
            ),
          ],
        ));
  }
}
