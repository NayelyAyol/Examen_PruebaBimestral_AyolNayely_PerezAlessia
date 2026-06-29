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
    };
  }

  factory VaccinationModel.fromFirestore(String id, Map<String, dynamic> map) {
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
      latitud: (map['latitud'] as num?)?.toDouble() ?? 0.0,
      longitud: (map['longitud'] as num?)?.toDouble() ?? 0.0,
      fechaHora: (map['fechaHora'] as Timestamp?)?.toDate() ?? DateTime.now(),
      vacunadorId: map['vacunadorId'] ?? '',
      vacunadorNombre: map['vacunadorNombre'] ?? '',
    );
  }
}