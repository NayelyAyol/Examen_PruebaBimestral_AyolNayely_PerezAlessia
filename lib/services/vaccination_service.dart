import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vaccination_model.dart';

class VaccinationService extends ChangeNotifier {
  final CollectionReference _db =
      FirebaseFirestore.instance.collection('vacunaciones');

  Future<void> saveVaccination(VaccinationModel vaccination) async {
    await _db.add(vaccination.toMap());
  }

  Future<void> updateVaccination(VaccinationModel vaccination) async {
    await _db.doc(vaccination.id).update(vaccination.toMap());
  }

  Future<void> deleteVaccination(String id) async {
    await _db.doc(id).delete();
  }

  Stream<List<VaccinationModel>> getVaccinations() {
    return _db.snapshots().map(_mapAndSortSnapshot);
  }

  Stream<List<VaccinationModel>> getVaccinationsByVaccinator(String uid) {
    return _db
        .where('vacunadorId', isEqualTo: uid)
        .snapshots()
        .map(_mapAndSortSnapshot);
  }

  Stream<List<VaccinationModel>> getVaccinationsBySector(String sectorId) {
    return _db
        .where('sectorId', isEqualTo: sectorId)
        .snapshots()
        .map(_mapAndSortSnapshot);
  }

  Stream<List<VaccinationModel>> getVaccinationsBySectorAndVaccinator(
    String sectorId,
    String vacunadorId,
  ) {
    return _db
        .where('sectorId', isEqualTo: sectorId)
        .where('vacunadorId', isEqualTo: vacunadorId)
        .snapshots()
        .map(_mapAndSortSnapshot);
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