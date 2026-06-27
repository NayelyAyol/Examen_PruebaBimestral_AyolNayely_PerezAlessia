class CoordinatorModel {
  final String id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String email;
  final String status; // 'Activo', 'Inactivo'
  final List<String> assignedSectorIds;

  CoordinatorModel({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.email,
    required this.status,
    required this.assignedSectorIds,
  });

  // Nombre completo combinado
  String get nombreCompleto => '$nombres $apellidos';

  // Convierte Firestore a CoordinatorModel
  factory CoordinatorModel.fromMap(Map<String, dynamic> map, String id) {
    return CoordinatorModel(
      id: id,
      cedula: map['cedula'] ?? '',
      nombres: map['nombres'] ?? '',
      apellidos: map['apellidos'] ?? '',
      telefono: map['telefono'] ?? '',
      email: map['email'] ?? '',
      status: map['status'] ?? 'Activo',
      assignedSectorIds: List<String>.from(map['assignedSectorIds'] ?? []),
    );
  }

  // Convierte CoordinatorModel a mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'cedula': cedula,
      'nombres': nombres,
      'apellidos': apellidos,
      'telefono': telefono,
      'email': email,
      'status': status,
      'assignedSectorIds': assignedSectorIds,
    };
  }

  CoordinatorModel copyWith({
    String? id,
    String? cedula,
    String? nombres,
    String? apellidos,
    String? telefono,
    String? email,
    String? status,
    List<String>? assignedSectorIds,
  }) {
    return CoordinatorModel(
      id: id ?? this.id,
      cedula: cedula ?? this.cedula,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      status: status ?? this.status,
      assignedSectorIds: assignedSectorIds ?? this.assignedSectorIds,
    );
  }
}
