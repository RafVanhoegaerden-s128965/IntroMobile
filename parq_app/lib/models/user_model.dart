class User {
  String email;
  String id;
  String password;
  String username;
  num numRatings;
  num avgRating;
  num totalRating;

  User(
      {required this.email,
      required this.id,
      required this.password,
      required this.username,
      required this.numRatings,
      required this.avgRating,
      required this.totalRating});

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'id': id,
      'password': password,
      'username': username,
      'numRatings': numRatings
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
        email: map['email'],
        id: map['id'],
        password: map['password'],
        username: map['username'],
        numRatings: map['numRatings'],
        avgRating: map['avgRating'],
        totalRating: map['totalRating']);
  }
}
