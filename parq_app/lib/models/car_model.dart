class Car {
  String name;
  String type;
  String color;

  Car({required this.name, required this.type, required this.color});

  Map<String, dynamic> toMap() {
    return {'name': name, 'type': type, 'color': color};
  }

  factory Car.fromMap(Map<Object?, dynamic> map) {
    return Car(name: map['name'], type: map['type'], color: map['color']);
  }
}
