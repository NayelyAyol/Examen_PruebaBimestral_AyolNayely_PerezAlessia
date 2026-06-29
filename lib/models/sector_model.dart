class SectorModel {
  final String id;
  final String name;
  final String zone;
  final String description;
  final String? assignedCoordinatorId;
  final String? assignedCoordinatorName;

  SectorModel({
    required this.id,
    required this.name,
    required this.zone,
    required this.description,
    this.assignedCoordinatorId,
    this.assignedCoordinatorName,
  });

  factory SectorModel.fromMap(Map<String, dynamic> map, String id) {
    return SectorModel(
      id: id,
      name: map['name'] ?? '',
      zone: map['zone'] ?? '',
      description: map['description'] ?? '',
      assignedCoordinatorId: map['assignedCoordinatorId'],
      assignedCoordinatorName: map['assignedCoordinatorName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'zone': zone,
      'description': description,
      'assignedCoordinatorId': assignedCoordinatorId,
      'assignedCoordinatorName': assignedCoordinatorName,
    };
  }

  SectorModel copyWith({
    String? id,
    String? name,
    String? zone,
    String? description,
    String? assignedCoordinatorId,
    String? assignedCoordinatorName,
  }) {
    return SectorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      zone: zone ?? this.zone,
      description: description ?? this.description,
      assignedCoordinatorId:
          assignedCoordinatorId ?? this.assignedCoordinatorId,
      assignedCoordinatorName:
          assignedCoordinatorName ?? this.assignedCoordinatorName,
    );
  }
}