class SectorModel {
  final String id;
  final String name;
  final String zone;
  final String description;
  final String? assignedCoordinatorId;
  final String? assignedCoordinatorName;
  final List<String> assignedVaccinatorIds;
  final bool isPendingSync;

  SectorModel({
    required this.id,
    required this.name,
    required this.zone,
    required this.description,
    this.assignedCoordinatorId,
    this.assignedCoordinatorName,
    this.assignedVaccinatorIds = const [],
    this.isPendingSync = false,
  });

  factory SectorModel.fromMap(Map<String, dynamic> map, String id, {bool isPendingSync = false}) {
    return SectorModel(
      id: id,
      name: map['name'] ?? '',
      zone: map['zone'] ?? '',
      description: map['description'] ?? '',
      assignedCoordinatorId: map['assignedCoordinatorId'],
      assignedCoordinatorName: map['assignedCoordinatorName'],
      assignedVaccinatorIds:
          List<String>.from(map['assignedVaccinatorIds'] ?? []),
      isPendingSync: isPendingSync,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'zone': zone,
      'description': description,
      'assignedCoordinatorId': assignedCoordinatorId,
      'assignedCoordinatorName': assignedCoordinatorName,
      'assignedVaccinatorIds': assignedVaccinatorIds,
    };
  }

  SectorModel copyWith({
    String? id,
    String? name,
    String? zone,
    String? description,
    String? assignedCoordinatorId,
    String? assignedCoordinatorName,
    List<String>? assignedVaccinatorIds,
    bool? isPendingSync,
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
      assignedVaccinatorIds:
          assignedVaccinatorIds ?? this.assignedVaccinatorIds,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }
}