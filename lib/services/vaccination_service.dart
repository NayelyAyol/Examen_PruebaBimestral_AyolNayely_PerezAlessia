import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vaccination_model.dart';

class VaccinationService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Todas las vacunaciones: solo para coordinador de campaña
  Stream<List<VaccinationModel>> getVaccinationsStream() {
    return _db
        .collection('vaccinations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => VaccinationModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Vacunaciones propias: para vacunador
  Stream<List<VaccinationModel>> getVaccinationsByVaccinator(
    String vaccinatorId,
  ) {
    return _db
        .collection('vaccinations')
        .where('vaccinatorId', isEqualTo: vaccinatorId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => VaccinationModel.fromMap(doc.data(), doc.id))
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Vacunaciones de un sector
  Stream<List<VaccinationModel>> getVaccinationsBySector(String sectorId) {
    return _db
        .collection('vaccinations')
        .where('sectorId', isEqualTo: sectorId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => VaccinationModel.fromMap(doc.data(), doc.id))
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Vacunaciones de varios sectores: para coordinador de brigada
  Stream<List<VaccinationModel>> getVaccinationsBySectors(
    List<String> sectorIds,
  ) {
    if (sectorIds.isEmpty) {
      return Stream.value([]);
    }

    return _db
        .collection('vaccinations')
        .where('sectorId', whereIn: sectorIds.take(10).toList())
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => VaccinationModel.fromMap(doc.data(), doc.id))
          .toList();

      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<String> addVaccination(VaccinationModel vaccination) async {
    final ref = await _db.collection('vaccinations').add(vaccination.toMap());
    return ref.id;
  }

  Future<void> updateVaccination(VaccinationModel vaccination) async {
    await _db
        .collection('vaccinations')
        .doc(vaccination.id)
        .update(vaccination.toMap());
  }

  Future<void> deleteVaccination(String id) async {
    await _db.collection('vaccinations').doc(id).delete();
  }
}