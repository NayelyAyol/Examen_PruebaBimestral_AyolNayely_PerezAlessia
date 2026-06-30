import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/vaccinator_model.dart';

class VaccinatorService extends ChangeNotifier {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool get _isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  final List<VaccinatorModel> _demoVaccinators = [];

  VaccinatorService() {
    if (!_isFirebaseInitialized) {
      _initDemoData();
    }
  }

  void _initDemoData() {
    _demoVaccinators.addAll([
      VaccinatorModel(
        id: 'demo_vac_1',
        cedula: '1729998887',
        nombres: 'Pedro',
        apellidos: 'Ramírez',
        telefono: '0990001112',
        email: 'pedro@vet.com',
        status: 'Activo',
        assignedSectorIds: ['sec_1'],
        createdBy: 'demo_brigada_uid',
      ),
      VaccinatorModel(
        id: 'demo_vac_2',
        cedula: '1729998888',
        nombres: 'María',
        apellidos: 'Gómez',
        telefono: '0990001113',
        email: 'maria@vet.com',
        status: 'Activo',
        assignedSectorIds: ['sec_3'],
        createdBy: 'demo_brigada_uid',
      ),
    ]);
  }

  // Obtiene vacunadores filtrados opcionalmente por creador
  Stream<List<VaccinatorModel>> getVaccinatorsStream({String? createdById}) {
    if (_isFirebaseInitialized) {
      Query query = _db.collection('usuarios').where('rol', isEqualTo: 'vacunador');
      if (createdById != null) {
        query = query.where('createdBy', isEqualTo: createdById);
      }
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return VaccinatorModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
            isPendingSync: doc.metadata.hasPendingWrites,
          );
        }).toList();
      });
    } else {
      if (createdById != null) {
        return Stream.value(_demoVaccinators.where((v) => v.createdBy == createdById).toList());
      }
      return Stream.value(_demoVaccinators);
    }
  }

  // Obtiene los vacunadores asignados a un sector específico
  Stream<List<VaccinatorModel>> getVaccinatorsBySector(String sectorId) {
    if (_isFirebaseInitialized) {
      return _db
          .collection('usuarios')
          .where('rol', isEqualTo: 'vacunador')
          .where('assignedSectorIds', arrayContains: sectorId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return VaccinatorModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
            isPendingSync: doc.metadata.hasPendingWrites,
          );
        }).toList();
      });
    } else {
      final list = _demoVaccinators.where((v) => v.assignedSectorIds.contains(sectorId)).toList();
      return Stream.value(list);
    }
  }

  // Guarda un nuevo vacunador en Firestore o local
  Future<void> saveVaccinatorProfile(
    String uid,
    VaccinatorModel vaccinator,
  ) async {
    if (_isFirebaseInitialized) {
      final data = vaccinator.toMap();

      data['rol'] = 'vacunador';
      data['name'] = vaccinator.nombreCompleto;
      data['isFirstLogin'] = true;

      await _db.collection('usuarios').doc(uid).set(data);
    } else {
      _demoVaccinators.add(vaccinator.copyWith(id: uid));
      notifyListeners();
    }
  }

  // Actualiza la información de un vacunador
  Future<void> updateVaccinator(VaccinatorModel vaccinator) async {
    if (_isFirebaseInitialized) {
      final data = vaccinator.toMap();

      data['rol'] = 'vacunador';
      data['name'] = vaccinator.nombreCompleto;

      await _db.collection('usuarios').doc(vaccinator.id).update(data);
    } else {
      final index = _demoVaccinators.indexWhere((v) => v.id == vaccinator.id);
      if (index != -1) {
        _demoVaccinators[index] = vaccinator;
        notifyListeners();
      }
    }
  }

  // Elimina un vacunador
  Future<void> deleteVaccinator(String id) async {
    if (_isFirebaseInitialized) {
      await _db.collection('usuarios').doc(id).delete();
    } else {
      _demoVaccinators.removeWhere((v) => v.id == id);
      notifyListeners();
    }
  }
}