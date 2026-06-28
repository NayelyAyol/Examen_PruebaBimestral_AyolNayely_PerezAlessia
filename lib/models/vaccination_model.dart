class VaccinationModel {
  final String id;

  // Datos del propietario
  final String ownerName;
  final String ownerCedula;
  final String ownerPhone;

  // Datos de la mascota
  final String petType;
  final String petName;
  final String petAge;
  final String petSex;

  // Información de la vacunación
  final String vaccineName;
  final String observations;

  // Evidencia fotográfica
  final String photoUrl;

  // Ubicación GPS
  final double latitude;
  final double longitude;

  // Fecha del registro
  final DateTime createdAt;

  // Sector donde se realizó la vacunación
  final String sectorId;
  final String sectorName;

  // Vacunador responsable del registro
  final String vaccinatorId;
  final String vaccinatorName;

  // Estado de sincronización
  final bool isSynced;

  VaccinationModel({
    required this.id,
    required this.ownerName,
    required this.ownerCedula,
    required this.ownerPhone,
    required this.petType,
    required this.petName,
    required this.petAge,
    required this.petSex,
    required this.vaccineName,
    required this.observations,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.sectorId,
    required this.sectorName,
    required this.vaccinatorId,
    required this.vaccinatorName,
    required this.isSynced,
  });

  // Convierte Firestore a VaccinationModel
  factory VaccinationModel.fromMap(Map<String, dynamic> map, String id) {
    return VaccinationModel(
      id: id,
      ownerName: map['ownerName'] ?? '',
      ownerCedula: map['ownerCedula'] ?? '',
      ownerPhone: map['ownerPhone'] ?? '',
      petType: map['petType'] ?? '',
      petName: map['petName'] ?? '',
      petAge: map['petAge'] ?? '',
      petSex: map['petSex'] ?? '',
      vaccineName: map['vaccineName'] ?? '',
      observations: map['observations'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      latitude: (map['latitude'] ?? 0).toDouble(),
      longitude: (map['longitude'] ?? 0).toDouble(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      sectorId: map['sectorId'] ?? '',
      sectorName: map['sectorName'] ?? '',
      vaccinatorId: map['vaccinatorId'] ?? '',
      vaccinatorName: map['vaccinatorName'] ?? '',
      isSynced: map['isSynced'] ?? true,
    );
  }

  // Convierte VaccinationModel a mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'ownerName': ownerName,
      'ownerCedula': ownerCedula,
      'ownerPhone': ownerPhone,
      'petType': petType,
      'petName': petName,
      'petAge': petAge,
      'petSex': petSex,
      'vaccineName': vaccineName,
      'observations': observations,
      'photoUrl': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'sectorId': sectorId,
      'sectorName': sectorName,
      'vaccinatorId': vaccinatorId,
      'vaccinatorName': vaccinatorName,
      'isSynced': isSynced,
    };
  }

  // Permite crear una copia del registro con nuevos valores
  VaccinationModel copyWith({
    String? id,
    String? ownerName,
    String? ownerCedula,
    String? ownerPhone,
    String? petType,
    String? petName,
    String? petAge,
    String? petSex,
    String? vaccineName,
    String? observations,
    String? photoUrl,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    String? sectorId,
    String? sectorName,
    String? vaccinatorId,
    String? vaccinatorName,
    bool? isSynced,
  }) {
    return VaccinationModel(
      id: id ?? this.id,
      ownerName: ownerName ?? this.ownerName,
      ownerCedula: ownerCedula ?? this.ownerCedula,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      petType: petType ?? this.petType,
      petName: petName ?? this.petName,
      petAge: petAge ?? this.petAge,
      petSex: petSex ?? this.petSex,
      vaccineName: vaccineName ?? this.vaccineName,
      observations: observations ?? this.observations,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      sectorId: sectorId ?? this.sectorId,
      sectorName: sectorName ?? this.sectorName,
      vaccinatorId: vaccinatorId ?? this.vaccinatorId,
      vaccinatorName: vaccinatorName ?? this.vaccinatorName,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}