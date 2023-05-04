import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parq_app/models/car_model.dart';
import 'package:parq_app/models/user_model.dart';

class CarPage extends StatefulWidget {
  final Car? car;
  final User? user;
  const CarPage({super.key, this.user, this.car});

  @override
  State<CarPage> createState() => _CarPageState();
}

//BottomNavBar verdwijnt bij deze pagina
class _CarPageState extends State<CarPage> {
  List<Car> _cars = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _getValues();
  }

  //Get cars
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

  //Add car
  void _addCar(Car car) async {
    //Gebruik bij het toevoegen bij de id van de car: 'id': FirebaseFirestore.instance.collection('car').doc().id,
    await FirebaseFirestore.instance.collection('cars').add(car.toMap());
    setState(() {
      _getValues();
    });
  }

  //Add car dialog
  void _showAddCarDialog() {
    TextEditingController brandController = TextEditingController();
    TextEditingController typeController = TextEditingController();
    TextEditingController colorController = TextEditingController();

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add Car'),
            content: SizedBox(
              height: 210,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: brandController,
                      decoration: const InputDecoration(
                        hintText: 'Brand',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a brand.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: typeController,
                      decoration: const InputDecoration(
                        hintText: 'Type',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a type.';
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: colorController,
                      decoration: const InputDecoration(
                        hintText: 'Color',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a color.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
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
                    if (_formKey.currentState!.validate()) {
                      String brand = brandController.text.trim();
                      String type = typeController.text.trim();
                      String color = colorController.text.trim();

                      if (brand.isNotEmpty &&
                          type.isNotEmpty &&
                          color.isNotEmpty) {
                        Car car = Car(
                          id: FirebaseFirestore.instance
                              .collection('cars')
                              .doc()
                              .id,
                          userId: widget.user!.id,
                          brand: brand,
                          type: type,
                          color: color,
                        );
                        _addCar(car);
                        Navigator.of(context).pop();
                      }
                    }
                  }),
            ],
          );
        });
  }

  //Edit car
  Future<void> _editCar(Car car) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cars')
          .where('id', isEqualTo: car.id)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('cars').doc(docId).update({
          'brand': car.brand,
          'type': car.type,
          'color': car.color,
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

  void _showEditCarDialog(Car car) {
    log(car.id);
    TextEditingController brandController =
        TextEditingController(text: car.brand);
    TextEditingController typeController =
        TextEditingController(text: car.type);
    TextEditingController colorController =
        TextEditingController(text: car.color);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Edit car'),
              content: SizedBox(
                height: 210,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: brandController,
                        decoration: const InputDecoration(
                          hintText: 'Brand',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a brand.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: typeController,
                        decoration: const InputDecoration(
                          hintText: 'Type',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a type.';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: colorController,
                        decoration: const InputDecoration(
                          hintText: 'Color',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a color.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
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
                    child: const Text('Edit'),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        //New values
                        String newBrand = brandController.text.trim();
                        String newType = typeController.text.trim();
                        String newColor = colorController.text.trim();

                        if (newBrand.isNotEmpty &&
                            newType.isNotEmpty &&
                            newColor.isNotEmpty) {
                          Car updateCar = Car(
                            id: car.id,
                            userId: widget.user!.id,
                            brand: newBrand,
                            type: newType,
                            color: newColor,
                          );
                          _editCar(updateCar);
                          Navigator.of(context).pop();
                        } else {
                          log('Please enter values for all fields.');
                        }
                      }
                    }),
              ]);
        });
  }

  //Delete car
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

  void _showDeleteCar(Car car) async {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Delete Car'),
            content: Text('Are you sure you want to delete ${car.brand}?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
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
                              Text(car.brand),
                              Text(car.type),
                              Text(car.color),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  _showEditCarDialog(car);
                                },
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  _showDeleteCar(car);
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  if (index < _cars.length - 1) const Divider(thickness: 2)
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
