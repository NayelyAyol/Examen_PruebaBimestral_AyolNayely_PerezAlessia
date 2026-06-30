import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/vaccination_model.dart';
import 'storage_service.dart';

class VaccinationService extends ChangeNotifier {
  FirebaseFirestore get _dbFirestore => FirebaseFirestore.instance;
  CollectionReference get _db => _dbFirestore.collection('vacunaciones');
  final StorageService _storageService = StorageService();
  Timer? _syncTimer;

  bool get _isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  final List<VaccinationModel> _demoVaccinations = [];

  VaccinationService() {
    if (!_isFirebaseInitialized) {
      _initDemoData();
    } else {
      // Start periodic synchronization of offline vaccinations
      _startSyncTimer();
    }
  }

  void _initDemoData() {
    _demoVaccinations.addAll([
      VaccinationModel(
        id: 'demo_vac_rec_1',
        nombrePropietario: 'Juan Pérez',
        cedulaPropietario: '1712345678',
        telefono: '0991234567',
        tipoMascota: 'Perro',
        nombreMascota: 'Toby',
        edadAproximada: '3',
        sexo: 'Macho',
        vacunaAplicada: 'Antirrábica',
        observaciones: 'Paciente sano.',
        fotografia: '',
        latitud: -0.180653,
        longitud: -78.467834,
        fechaHora: DateTime.now().subtract(const Duration(days: 1)),
        vacunadorId: 'demo_vac_1',
        vacunadorNombre: 'Pedro Ramírez',
        sectorId: 'sec_1',
        sectorNombre: 'Sector Centro Histórico',
      ),
    ]);
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncOfflineVaccinations();
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  // Upload local images to Firebase Storage and update Firestore documents when online
  Future<void> syncOfflineVaccinations() async {
    if (!_isFirebaseInitialized) return;

    try {
      final snapshot = await _db.get();
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String photoPath = data['fotografia'] ?? '';

        // If the photography is a local file path
        if (photoPath.isNotEmpty &&
            !photoPath.startsWith('http://') &&
            !photoPath.startsWith('https://')) {
          final file = File(photoPath);
          if (file.existsSync()) {
            try {
              debugPrint("Auto-sync: Subiendo foto local a Storage: $photoPath");
              final downloadUrl = await _storageService.uploadVaccinationPhoto(file);
              
              debugPrint("Auto-sync: Foto subida con éxito. Nueva URL: $downloadUrl");
              await _db.doc(doc.id).update({
                'fotografia': downloadUrl,
              });
            } catch (uploadError) {
              debugPrint("Auto-sync: Error al subir imagen de vacunación $photoPath: $uploadError");
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Auto-sync: Error en el proceso de sincronización: $e");
    }
  }

  Future<void> saveVaccination(VaccinationModel vaccination) async {
    if (_isFirebaseInitialized) {
      await _db.add(vaccination.toMap());
      // Trigger instant sync check in case we just went online
      syncOfflineVaccinations();
    } else {
      final newVac = VaccinationModel(
        id: 'demo_v_${DateTime.now().millisecondsSinceEpoch}',
        nombrePropietario: vaccination.nombrePropietario,
        cedulaPropietario: vaccination.cedulaPropietario,
        telefono: vaccination.telefono,
        tipoMascota: vaccination.tipoMascota,
        nombreMascota: vaccination.nombreMascota,
        edadAproximada: vaccination.edadAproximada,
        sexo: vaccination.sexo,
        vacunaAplicada: vaccination.vacunaAplicada,
        observaciones: vaccination.observaciones,
        fotografia: vaccination.fotografia,
        latitud: vaccination.latitud,
        longitud: vaccination.longitud,
        fechaHora: vaccination.fechaHora,
        vacunadorId: vaccination.vacunadorId,
        vacunadorNombre: vaccination.vacunadorNombre,
        sectorId: vaccination.sectorId,
        sectorNombre: vaccination.sectorNombre,
      );
      _demoVaccinations.add(newVac);
      notifyListeners();
    }
  }

  Future<void> updateVaccination(VaccinationModel vaccination) async {
    if (_isFirebaseInitialized) {
      await _db.doc(vaccination.id).update(vaccination.toMap());
      syncOfflineVaccinations();
    } else {
      final index = _demoVaccinations.indexWhere((v) => v.id == vaccination.id);
      if (index != -1) {
        final updatedVac = VaccinationModel(
          id: vaccination.id,
          nombrePropietario: vaccination.nombrePropietario,
          cedulaPropietario: vaccination.cedulaPropietario,
          telefono: vaccination.telefono,
          tipoMascota: vaccination.tipoMascota,
          nombreMascota: vaccination.nombreMascota,
          edadAproximada: vaccination.edadAproximada,
          sexo: vaccination.sexo,
          vacunaAplicada: vaccination.vacunaAplicada,
          observaciones: vaccination.observaciones,
          fotografia: vaccination.fotografia,
          latitud: vaccination.latitud,
          longitud: vaccination.longitud,
          fechaHora: vaccination.fechaHora,
          vacunadorId: vaccination.vacunadorId,
          vacunadorNombre: vaccination.vacunadorNombre,
          sectorId: vaccination.sectorId,
          sectorNombre: vaccination.sectorNombre,
        );
        _demoVaccinations[index] = updatedVac;
        notifyListeners();
      }
    }
  }

  Future<void> deleteVaccination(String id) async {
    if (_isFirebaseInitialized) {
      await _db.doc(id).delete();
    } else {
      _demoVaccinations.removeWhere((v) => v.id == id);
      notifyListeners();
    }
  }

  Stream<List<VaccinationModel>> getVaccinations() {
    if (_isFirebaseInitialized) {
      return _db.snapshots().map(_mapAndSortSnapshot);
    } else {
      _demoVaccinations.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
      return Stream.value(_demoVaccinations);
    }
  }

  Stream<List<VaccinationModel>> getVaccinationsByVaccinator(String uid) {
    if (_isFirebaseInitialized) {
      return _db
          .where('vacunadorId', isEqualTo: uid)
          .snapshots()
          .map(_mapAndSortSnapshot);
    } else {
      final list = _demoVaccinations.where((v) => v.vacunadorId == uid).toList();
      list.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
      return Stream.value(list);
    }
  }

  Stream<List<VaccinationModel>> getVaccinationsBySector(String sectorId) {
    if (_isFirebaseInitialized) {
      return _db
          .where('sectorId', isEqualTo: sectorId)
          .snapshots()
          .map(_mapAndSortSnapshot);
    } else {
      final list = _demoVaccinations.where((v) => v.sectorId == sectorId).toList();
      list.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
      return Stream.value(list);
    }
  }

  Stream<List<VaccinationModel>> getVaccinationsBySectorAndVaccinator(
    String sectorId,
    String vacunadorId,
  ) {
    if (_isFirebaseInitialized) {
      return _db
          .where('sectorId', isEqualTo: sectorId)
          .where('vacunadorId', isEqualTo: vacunadorId)
          .snapshots()
          .map(_mapAndSortSnapshot);
    } else {
      final list = _demoVaccinations.where((v) => v.sectorId == sectorId && v.vacunadorId == vacunadorId).toList();
      list.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
      return Stream.value(list);
    }
  }

  List<VaccinationModel> _mapAndSortSnapshot(QuerySnapshot snapshot) {
    final list = snapshot.docs.map((doc) {
      return VaccinationModel.fromFirestore(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );
    }).toList();

    list.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));

    return list;
  }
}