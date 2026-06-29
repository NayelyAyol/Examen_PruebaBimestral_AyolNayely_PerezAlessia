import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/vaccination_model.dart';

class VaccinationService extends ChangeNotifier {
  final CollectionReference _db = FirebaseFirestore.instance.collection('vacunas');

  Future<void> saveVaccination(VaccinationModel vaccination) async {
    try {
      await _db.add(vaccination.toMap());
    } catch (e) {
      throw Exception('Error al guardar: $e');
    }
  }

  Future<void> updateVaccination(VaccinationModel vaccination) async {
    try {
      await _db.doc(vaccination.id).update(vaccination.toMap());
    } catch (e) {
      throw Exception('Error al actualizar: $e');
    }
  }

  Future<void> deleteVaccination(String id) async {
    try {
      await _db.doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar: $e');
    }
  }

  Stream<List<VaccinationModel>> getVaccinations() {
    return _db.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return VaccinationModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}