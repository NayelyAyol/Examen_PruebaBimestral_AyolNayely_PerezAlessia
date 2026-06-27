class SectorModel {
  final String id;
  final String name;
  final String zone;
  final String description;
  final String status; // 'Pendiente', 'En Proceso', 'Completado'
  final String? assignedCoordinatorId;
  final String? assignedCoordinatorName;

  SectorModel({
    required this.id,
    required this.name,
    required this.zone,
    required this.description,
    required this.status,
    this.assignedCoordinatorId,
    this.assignedCoordinatorName,
  });

  // Convierte Firestore a SectorModel
  factory SectorModel.fromMap(Map<String, dynamic> map, String id) {
    return SectorModel(
      id: id,
      name: map['name'] ?? '',
      zone: map['zone'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'Pendiente',
      assignedCoordinatorId: map['assignedCoordinatorId'],
      assignedCoordinatorName: map['assignedCoordinatorName'],
    );
  }

  // Convierte SectorModel a mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'zone': zone,
      'description': description,
      'status': status,
      'assignedCoordinatorId': assignedCoordinatorId,
      'assignedCoordinatorName': assignedCoordinatorName,
    };
  }

  // Permite copiar con cambios
  SectorModel copyWith({
    String? id,
    String? name,
    String? zone,
    String? description,
    String? status,
    String? assignedCoordinatorId,
    String? assignedCoordinatorName,
  }) {
    return SectorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      zone: zone ?? this.zone,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedCoordinatorId: assignedCoordinatorId ?? this.assignedCoordinatorId,
      assignedCoordinatorName: assignedCoordinatorName ?? this.assignedCoordinatorName,
    );
  }
}
