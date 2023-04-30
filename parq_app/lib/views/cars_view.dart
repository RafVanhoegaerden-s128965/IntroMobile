import 'package:flutter/material.dart';

class CarPage extends StatefulWidget {
  final String? userId;
  const CarPage({super.key, this.userId});

  @override
  State<CarPage> createState() => _CarPageState();
}

//BottomNavBar verdwijnt bij deze pagina
class _CarPageState extends State<CarPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cars',
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: <Widget>[
            //TODO: change car-variables
            Card(
              child: SizedBox(
                  height: 150,
                  width: 400,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('CarName'),
                      Text('CarType'),
                      Text('CarColor')
                    ],
                  )),
            ),
            const Divider(
              thickness: 2,
            ),
            //TODO: change car-variables
            Card(
              child: SizedBox(
                  height: 150,
                  width: 400,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('CarName'),
                      Text('CarType'),
                      Text('CarColor')
                    ],
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
