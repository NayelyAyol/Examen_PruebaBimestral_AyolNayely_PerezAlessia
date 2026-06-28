import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vaccination_model.dart';

class VaccinationService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtiene todas las vacunaciones registradas
  Stream<List<VaccinationModel>> getVaccinationsStream() {
    return _db
        .collection('vaccinations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VaccinationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtiene las vacunaciones realizadas por un vacunador
  Stream<List<VaccinationModel>> getVaccinationsByVaccinator(
    String vaccinatorId,
  ) {
    return _db
        .collection('vaccinations')
        .where('vaccinatorId', isEqualTo: vaccinatorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VaccinationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Obtiene las vacunaciones registradas por sector
  Stream<List<VaccinationModel>> getVaccinationsBySector(String sectorId) {
    return _db
        .collection('vaccinations')
        .where('sectorId', isEqualTo: sectorId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VaccinationModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Registra una nueva vacunación
  Future<String> addVaccination(VaccinationModel vaccination) async {
    final ref = await _db.collection('vaccinations').add(vaccination.toMap());
    return ref.id;
  }

  // Actualiza una vacunación existente
  Future<void> updateVaccination(VaccinationModel vaccination) async {
    await _db
        .collection('vaccinations')
        .doc(vaccination.id)
        .update(vaccination.toMap());
  }

  // Elimina una vacunación
  Future<void> deleteVaccination(String id) async {
    await _db.collection('vaccinations').doc(id).delete();
  }
}