import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/coordinator_model.dart';
import '../models/sector_model.dart';

class FirestoreService extends ChangeNotifier {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  bool _isFirebaseInitialized = false;

  final List<SectorModel> _demoSectors = [];
  final List<CoordinatorModel> _demoCoordinators = [];

  FirestoreService(bool isFirebaseInitialized) {
    _isFirebaseInitialized = isFirebaseInitialized;
    if (!_isFirebaseInitialized) {
      _initDemoData();
    }
  }

  void _initDemoData() {
    _demoCoordinators.addAll([
      CoordinatorModel(
        id: 'demo_brigada_uid',
        cedula: '1723456789',
        nombres: 'Ana',
        apellidos: 'López',
        telefono: '0998765432',
        email: 'brigada@vet.com',
        status: 'Activo',
        assignedSectorIds: ['sec_1', 'sec_3'],
      ),
    ]);

    _demoSectors.addAll([
      SectorModel(
        id: 'sec_1',
        name: 'Sector Centro Histórico',
        zone: 'Centro',
        description: 'Campaña de vacunación antirrábica en plazas principales.',
        assignedCoordinatorId: 'demo_brigada_uid',
        assignedCoordinatorName: 'Ana López',
      ),
      SectorModel(
        id: 'sec_2',
        name: 'Sector Carcelén',
        zone: 'Norte',
        description: 'Censo de mascotas callejeras y vacunación.',
        assignedCoordinatorId: null,
        assignedCoordinatorName: null,
      ),
      SectorModel(
        id: 'sec_3',
        name: 'Sector Villa Flora',
        zone: 'Sur',
        description: 'Atención primaria veterinaria y desparasitación.',
        assignedCoordinatorId: 'demo_brigada_uid',
        assignedCoordinatorName: 'Ana López',
      ),
      SectorModel(
        id: 'sec_4',
        name: 'Sector Cumbayá',
        zone: 'Valles',
        description: 'Monitoreo y vacunación de mascotas.',
        assignedCoordinatorId: null,
        assignedCoordinatorName: null,
      ),
    ]);
  }

  Stream<List<SectorModel>> getSectorsStream() {
    if (_isFirebaseInitialized) {
      return _db.collection('sectores').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return SectorModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } else {
      return Stream.value(_demoSectors);
    }
  }

  Future<String> addSector(SectorModel sector) async {
    if (_isFirebaseInitialized) {
      final ref = await _db.collection('sectores').add(sector.toMap());
      return ref.id;
    } else {
      final newId = 'sec_${DateTime.now().millisecondsSinceEpoch}';
      _demoSectors.add(sector.copyWith(id: newId));
      notifyListeners();
      return newId;
    }
  }

  Future<void> updateSector(SectorModel sector) async {
    if (_isFirebaseInitialized) {
      await _db.collection('sectores').doc(sector.id).update(sector.toMap());
    } else {
      final index = _demoSectors.indexWhere((s) => s.id == sector.id);
      if (index != -1) {
        _demoSectors[index] = sector;
        notifyListeners();
      }
    }
  }

  Future<void> deleteSector(String id) async {
    if (_isFirebaseInitialized) {
      await _db.collection('sectores').doc(id).delete();
    } else {
      _demoSectors.removeWhere((s) => s.id == id);
      notifyListeners();
    }
  }

  Stream<List<CoordinatorModel>> getCoordinatorsStream() {
    if (_isFirebaseInitialized) {
      return _db
          .collection('usuarios')
          .where('rol', isEqualTo: 'coordinador_brigada')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CoordinatorModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } else {
      return Stream.value(_demoCoordinators);
    }
  }

  Future<void> saveCoordinatorProfile(
    String uid,
    CoordinatorModel coordinator,
  ) async {
    if (_isFirebaseInitialized) {
      final data = coordinator.toMap();
      data['rol'] = 'coordinador_brigada';
      data['isFirstLogin'] = true;
      data['name'] = coordinator.nombreCompleto;

      await _db.collection('usuarios').doc(uid).set(data);

      await syncSectorAssignments(
        uid,
        coordinator.nombreCompleto,
        coordinator.assignedSectorIds,
      );
    } else {
      _demoCoordinators.add(coordinator.copyWith(id: uid));
      await syncSectorAssignments(
        uid,
        coordinator.nombreCompleto,
        coordinator.assignedSectorIds,
      );
      notifyListeners();
    }
  }

  Future<void> updateCoordinator(CoordinatorModel coordinator) async {
    if (_isFirebaseInitialized) {
      final data = coordinator.toMap();
      data['rol'] = 'coordinador_brigada';
      data['name'] = coordinator.nombreCompleto;

      await _db.collection('usuarios').doc(coordinator.id).update(data);

      await syncSectorAssignments(
        coordinator.id,
        coordinator.nombreCompleto,
        coordinator.assignedSectorIds,
      );
    } else {
      final index = _demoCoordinators.indexWhere((c) => c.id == coordinator.id);
      if (index != -1) {
        _demoCoordinators[index] = coordinator;
        await syncSectorAssignments(
          coordinator.id,
          coordinator.nombreCompleto,
          coordinator.assignedSectorIds,
        );
        notifyListeners();
      }
    }
  }

  Future<void> deleteCoordinator(String uid) async {
    if (_isFirebaseInitialized) {
      await syncSectorAssignments(uid, '', []);
      await _db.collection('usuarios').doc(uid).delete();
    } else {
      await syncSectorAssignments(uid, '', []);
      _demoCoordinators.removeWhere((c) => c.id == uid);
      notifyListeners();
    }
  }

  Future<void> syncSectorAssignments(
    String coordinatorId,
    String coordinatorName,
    List<String> assignedSectorIds,
  ) async {
    if (_isFirebaseInitialized) {
      final currentAssigned = await _db
          .collection('sectores')
          .where('assignedCoordinatorId', isEqualTo: coordinatorId)
          .get();

      for (final doc in currentAssigned.docs) {
        if (!assignedSectorIds.contains(doc.id)) {
          await _db.collection('sectores').doc(doc.id).update({
            'assignedCoordinatorId': null,
            'assignedCoordinatorName': null,
          });
        }
      }

      for (final sectorId in assignedSectorIds) {
        await _db.collection('sectores').doc(sectorId).update({
          'assignedCoordinatorId': coordinatorId,
          'assignedCoordinatorName':
              coordinatorName.isEmpty ? null : coordinatorName,
        });
      }
    } else {
      for (var i = 0; i < _demoSectors.length; i++) {
        if (_demoSectors[i].assignedCoordinatorId == coordinatorId) {
          if (!assignedSectorIds.contains(_demoSectors[i].id)) {
            _demoSectors[i] = _demoSectors[i].copyWith(
              assignedCoordinatorId: null,
              assignedCoordinatorName: null,
            );
          }
        }
      }

      for (final sectorId in assignedSectorIds) {
        final index = _demoSectors.indexWhere((s) => s.id == sectorId);
        if (index != -1) {
          _demoSectors[index] = _demoSectors[index].copyWith(
            assignedCoordinatorId: coordinatorId,
            assignedCoordinatorName:
                coordinatorName.isEmpty ? null : coordinatorName,
          );
        }
      }

      notifyListeners();
    }
  }

  Future<void> seedSectors(List<SectorModel> sectors) async {
    if (_isFirebaseInitialized) {
      for (final sector in sectors) {
        await _db.collection('sectores').add(sector.toMap());
      }
    } else {
      _demoSectors.clear();
      _demoSectors.addAll(sectors);
      notifyListeners();
    }
  }

  Future<bool> checkSectorsEmpty() async {
    if (_isFirebaseInitialized) {
      final snap = await _db.collection('sectores').limit(1).get();
      return snap.docs.isEmpty;
    } else {
      return _demoSectors.isEmpty;
    }
  }
}