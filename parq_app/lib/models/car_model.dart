class Car {
  String id;
  String name;
  String type;
  String color;
  String userId;

  Car({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'color': color,
      'userId': userId
    };
  }

  factory Car.fromMap(Map<Object?, dynamic> map) {
    return Car(
        id: map['id'],
        name: map['name'],
        type: map['type'],
        color: map['color'],
        userId: map['userId']);
  }
  Car copyWith({
    String? id,
    String? name,
    String? type,
    String? color,
    String? userId,
  }) {
    return Car(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      userId: userId ?? this.userId,
    );
  }
}
