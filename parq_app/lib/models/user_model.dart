class User {
  String email;
  String id;
  String password;
  String username;
  num rating;

  User(
      {required this.email,
      required this.id,
      required this.password,
      required this.username,
      required this.rating});

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'id': id,
      'password': password,
      'username': username,
      'rating': rating
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
        email: map['email'],
        id: map['id'],
        password: map['password'],
        username: map['username'],
        rating: map['rating']);
  }
}
