// LAB ACT 5: LoginType tells the rest of the app which backend authenticated
// the current session, so the profile can show the right details and route
// account actions to DummyJSON or Firebase Auth.
enum LoginType {
  dummyJson,
  firebase;

  String get label => this == LoginType.firebase ? 'Firebase' : 'DummyJSON';

  static LoginType fromName(String? name) => LoginType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => LoginType.dummyJson,
  );
}

// ENHANCEMENT 3: A typed model keeps the saved authentication response safe
// to read across the profile and cart features.
class User {
  final int id;
  // Firebase accounts are identified by a string uid instead of an int id.
  final String uid;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final int age;
  final String phone;
  final String accessToken;
  final String refreshToken;
  final LoginType loginType;

  User({
    required this.id,
    this.uid = '',
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    this.age = 0,
    this.phone = '',
    required this.accessToken,
    required this.refreshToken,
    this.loginType = LoginType.dummyJson,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : 0,
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      gender: json['gender'] ?? '',
      image: json['image'] ?? '',
      age: json['age'] is int ? json['age'] : 0,
      phone: json['phone'] ?? '',
      accessToken: json['accessToken'] ?? json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
      loginType: LoginType.fromName(json['loginType']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'image': image,
      'age': age,
      'phone': phone,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'loginType': loginType.name,
    };
  }
}
