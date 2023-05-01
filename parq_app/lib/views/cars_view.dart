import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parq_app/models/car_model.dart';
import 'package:parq_app/models/user_model.dart';

class CarPage extends StatefulWidget {
  final User? user;
  const CarPage({super.key, this.user});

  @override
  State<CarPage> createState() => _CarPageState();
}

//BottomNavBar verdwijnt bij deze pagina
class _CarPageState extends State<CarPage> {
  List<Car> _cars = [];

  @override
  void initState() {
    super.initState();
    _getValues();
  }

  void _getValues() async {
    //Connectie met Firebase
    final snapshot = await FirebaseFirestore.instance
        .collection('cars')
        .where('userId', isEqualTo: widget.user?.id.toString())
        .get();
    //Lijst maken van alle documenten
    List<DocumentSnapshot> documents = snapshot.docs;
    List<Car> cars = [];
    //Itereren over elke document en mappen in parking
    for (var document in documents) {
      var data = document.data();
      cars.add(Car.fromMap(data as Map<String, dynamic>));
    }
    setState(() {
      _cars = cars;
      log("Cars: ${_cars.length}");
    });
  }

  void _deleteCar(Car car) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('cars')
        .where('id', isEqualTo: car.id)
        .get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
      setState(() {
        _getValues();
      });
    }
  }

  void _addCar(Car car) async {
    //Gebruik bij het toevoegen bij de id van de car: 'id': FirebaseFirestore.instance.collection('car').doc().id,
    await FirebaseFirestore.instance.collection('cars').add(car.toMap());
    setState(() {
      _getValues();
    });
  }

  void _showAddCarDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController typeController = TextEditingController();
    TextEditingController colorController = TextEditingController();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add Car'),
            content: SizedBox(
              height: 150,
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Name',
                    ),
                  ),
                  TextField(
                    controller: typeController,
                    decoration: const InputDecoration(
                      hintText: 'Type',
                    ),
                  ),
                  TextField(
                    controller: colorController,
                    decoration: const InputDecoration(
                      hintText: 'Color',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Add'),
                onPressed: () {
                  String name = nameController.text.trim();
                  String type = typeController.text.trim();
                  String color = colorController.text.trim();

                  if (name.isNotEmpty && type.isNotEmpty && color.isNotEmpty) {
                    Car car = Car(
                      id: FirebaseFirestore.instance
                          .collection('cars')
                          .doc()
                          .id,
                      userId: widget.user!.id,
                      name: name,
                      type: type,
                      color: color,
                    );
                    _addCar(car);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          );
        });
  }

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
          child: ListView.builder(
            itemCount: _cars.length,
            itemBuilder: (BuildContext context, int index) {
              final car = _cars[index];
              return Column(
                children: [
                  Card(
                    child: SizedBox(
                      height: 150,
                      width: 400,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                car.name,
                              ),
                              Text(car.type),
                              Text(car.color),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  //TODO: edit dialog
                                },
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text('Delete Car'),
                                          content: Text(
                                              'Are you sure you want to delete ${car.name}?'),
                                          actions: [
                                            TextButton(
                                              child: const Text('Cancel'),
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                            TextButton(
                                              child: const Text('Delete'),
                                              onPressed: () {
                                                _deleteCar(car);
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        );
                                      });
                                },
                                icon: const Icon(Icons.delete),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const Divider(
                    thickness: 2,
                  ),
                ],
              );
            },
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddCarDialog();
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
