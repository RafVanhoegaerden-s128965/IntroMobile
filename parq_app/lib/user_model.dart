class User {
  String email;
  String id;
  String password;
  String username;

  User(
      {required this.email,
      required this.id,
      required this.password,
      required this.username});

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'id': id,
      'password': password,
      'username': username,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      email: map['email'],
      id: map['id'],
      password: map['password'],
      username: map['username'],
    );
  }
}
