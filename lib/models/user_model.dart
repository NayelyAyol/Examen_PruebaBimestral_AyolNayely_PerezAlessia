class UserModel {
  final String uid;
  final String email;
  final String name;
  final String rol;
  final bool isFirstLogin;

  String get role => rol;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.rol,
    required this.isFirstLogin,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      rol: map['rol'] ?? map['role'] ?? 'coordinador_brigada',
      isFirstLogin: map['isFirstLogin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'rol': rol,
      'isFirstLogin': isFirstLogin,
    };
  }
}