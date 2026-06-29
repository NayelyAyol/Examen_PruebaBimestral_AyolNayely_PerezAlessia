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
    return _db.orderBy('fechaHora', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return VaccinationModel.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }

  Stream<List<VaccinationModel>> getVaccinationsByVaccinator(String uid) {
    return _db
        .where('vacunadorId', isEqualTo: uid)
        .orderBy('fechaHora', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VaccinationModel.fromFirestore(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
      }).toList();
    });
  }
}