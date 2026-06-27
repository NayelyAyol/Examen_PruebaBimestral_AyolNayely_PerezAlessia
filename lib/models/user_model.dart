class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role; // 'coordinador_campana' or 'coordinador_brigada'
  final bool isFirstLogin;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.isFirstLogin,
  });

  // Convierte un documento de Firestore a UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'coordinador_brigada',
      isFirstLogin: map['isFirstLogin'] ?? false,
    );
  }

  // Convierte un UserModel a un mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'isFirstLogin': isFirstLogin,
    };
  }
}
