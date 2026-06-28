import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vaccinator_model.dart';

class VaccinatorService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtiene todos los vacunadores registrados
  Stream<List<VaccinatorModel>> getVaccinatorsStream() {
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'vacunador')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VaccinatorModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtiene los vacunadores asignados a un sector específico
  Stream<List<VaccinatorModel>> getVaccinatorsBySector(String sectorId) {
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'vacunador')
        .where('assignedSectorIds', arrayContains: sectorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VaccinatorModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Guarda un nuevo vacunador en Firestore
  Future<void> saveVaccinatorProfile(
    String uid,
    VaccinatorModel vaccinator,
  ) async {
    final data = vaccinator.toMap();

    data['rol'] = 'vacunador';
    data['role'] = 'vacunador';
    data['name'] = vaccinator.nombreCompleto;
    data['isFirstLogin'] = true;

    await _db.collection('usuarios').doc(uid).set(data);
  }

  // Actualiza la información de un vacunador
  Future<void> updateVaccinator(VaccinatorModel vaccinator) async {
    final data = vaccinator.toMap();

    data['rol'] = 'vacunador';
    data['role'] = 'vacunador';
    data['name'] = vaccinator.nombreCompleto;

    await _db.collection('usuarios').doc(vaccinator.id).update(data);
  }

  // Elimina un vacunador
  Future<void> deleteVaccinator(String id) async {
    await _db.collection('usuarios').doc(id).delete();
  }
}