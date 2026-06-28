class VaccinatorModel {
  final String id;
  final String cedula;
  final String nombres;
  final String apellidos;
  final String telefono;
  final String email;
  final String status; // 'Activo', 'Inactivo'
  final List<String> assignedSectorIds;

  VaccinatorModel({
    required this.id,
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.telefono,
    required this.email,
    required this.status,
    required this.assignedSectorIds,
  });

  // Nombre completo del vacunador
  String get nombreCompleto => '$nombres $apellidos';

  // Convierte Firestore a VaccinatorModel
  factory VaccinatorModel.fromMap(Map<String, dynamic> map, String id) {
    return VaccinatorModel(
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

  // Convierte VaccinatorModel a mapa para Firestore
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

  // Permite crear una copia del objeto con nuevos valores
  VaccinatorModel copyWith({
    String? id,
    String? cedula,
    String? nombres,
    String? apellidos,
    String? telefono,
    String? email,
    String? status,
    List<String>? assignedSectorIds,
  }) {
    return VaccinatorModel(
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