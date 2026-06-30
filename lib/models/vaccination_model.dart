import 'package:cloud_firestore/cloud_firestore.dart';

class VaccinationModel {
  final String id;
  final String nombrePropietario;
  final String cedulaPropietario;
  final String telefono;
  final String tipoMascota;
  final String nombreMascota;
  final String edadAproximada;
  final String sexo;
  final String vacunaAplicada;
  final String observaciones;
  final String fotografia;
  final double latitud;
  final double longitud;
  final DateTime fechaHora;

  final String vacunadorId;
  final String vacunadorNombre;
  final String sectorId;
  final String sectorNombre;
  final bool isPendingSync;

  VaccinationModel({
    required this.id,
    required this.nombrePropietario,
    required this.cedulaPropietario,
    required this.telefono,
    required this.tipoMascota,
    required this.nombreMascota,
    required this.edadAproximada,
    required this.sexo,
    required this.vacunaAplicada,
    required this.observaciones,
    required this.fotografia,
    required this.latitud,
    required this.longitud,
    required this.fechaHora,
    this.vacunadorId = '',
    this.vacunadorNombre = '',
    this.sectorId = '',
    this.sectorNombre = '',
    this.isPendingSync = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombrePropietario': nombrePropietario,
      'cedulaPropietario': cedulaPropietario,
      'telefono': telefono,
      'tipoMascota': tipoMascota,
      'nombreMascota': nombreMascota,
      'edadAproximada': edadAproximada,
      'sexo': sexo,
      'vacunaAplicada': vacunaAplicada,
      'observaciones': observaciones,
      'fotografia': fotografia,
      'latitud': latitud,
      'longitud': longitud,
      'fechaHora': Timestamp.fromDate(fechaHora),

      'vacunadorId': vacunadorId,
      'vacunadorNombre': vacunadorNombre,

      'sectorId': sectorId,
      'sectorNombre': sectorNombre,
    };
  }

  factory VaccinationModel.fromFirestore(String id, Map<String, dynamic> map, {bool isPendingSync = false}) {
    return VaccinationModel(
      id: id,
      nombrePropietario: map['nombrePropietario'] ?? '',
      cedulaPropietario: map['cedulaPropietario'] ?? '',
      telefono: map['telefono'] ?? '',
      tipoMascota: map['tipoMascota'] ?? 'Perro',
      nombreMascota: map['nombreMascota'] ?? '',
      edadAproximada: map['edadAproximada'] ?? '',
      sexo: map['sexo'] ?? 'Macho',
      vacunaAplicada: map['vacunaAplicada'] ?? '',
      observaciones: map['observaciones'] ?? '',
      fotografia: map['fotografia'] ?? '',
      latitud: (map['latitud'] as num?)?.toDouble() ?? 0,
      longitud: (map['longitud'] as num?)?.toDouble() ?? 0,
      fechaHora: (map['fechaHora'] as Timestamp?)?.toDate() ?? DateTime.now(),

      vacunadorId: map['vacunadorId'] ?? '',
      vacunadorNombre: map['vacunadorNombre'] ?? '',

      sectorId: map['sectorId'] ?? '',
      sectorNombre: map['sectorNombre'] ?? '',
      isPendingSync: isPendingSync,
    );
  }

  VaccinationModel copyWith({
    String? id,
    String? nombrePropietario,
    String? cedulaPropietario,
    String? telefono,
    String? tipoMascota,
    String? nombreMascota,
    String? edadAproximada,
    String? sexo,
    String? vacunaAplicada,
    String? observaciones,
    String? fotografia,
    double? latitud,
    double? longitud,
    DateTime? fechaHora,
    String? vacunadorId,
    String? vacunadorNombre,
    String? sectorId,
    String? sectorNombre,
    bool? isPendingSync,
  }) {
    return VaccinationModel(
      id: id ?? this.id,
      nombrePropietario: nombrePropietario ?? this.nombrePropietario,
      cedulaPropietario: cedulaPropietario ?? this.cedulaPropietario,
      telefono: telefono ?? this.telefono,
      tipoMascota: tipoMascota ?? this.tipoMascota,
      nombreMascota: nombreMascota ?? this.nombreMascota,
      edadAproximada: edadAproximada ?? this.edadAproximada,
      sexo: sexo ?? this.sexo,
      vacunaAplicada: vacunaAplicada ?? this.vacunaAplicada,
      observaciones: observaciones ?? this.observaciones,
      fotografia: fotografia ?? this.fotografia,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fechaHora: fechaHora ?? this.fechaHora,
      vacunadorId: vacunadorId ?? this.vacunadorId,
      vacunadorNombre: vacunadorNombre ?? this.vacunadorNombre,
      sectorId: sectorId ?? this.sectorId,
      sectorNombre: sectorNombre ?? this.sectorNombre,
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }
}
