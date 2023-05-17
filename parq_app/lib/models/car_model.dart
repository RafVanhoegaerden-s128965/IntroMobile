class Car {
  String id;
  String brand;
  String type;
  String color;
  String userId;

  Car({
    required this.id,
    required this.brand,
    required this.type,
    required this.color,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brand': brand,
      'type': type,
      'color': color,
      'userId': userId
    };
  }

  factory Car.fromMap(Map<Object?, dynamic> map) {
    return Car(
        id: map['id'],
        brand: map['brand'],
        type: map['type'],
        color: map['color'],
        userId: map['userId']);
  }
  Car copyWith({
    String? id,
    String? brand,
    String? type,
    String? color,
    String? userId,
  }) {
    return Car(
      id: id ?? this.id,
      brand: brand ?? this.brand,
      type: type ?? this.type,
      color: color ?? this.color,
      userId: userId ?? this.userId,
    );
  }
}
