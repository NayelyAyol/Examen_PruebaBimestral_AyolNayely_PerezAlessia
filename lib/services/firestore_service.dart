import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sector_model.dart';
import '../models/coordinator_model.dart';

class FirestoreService extends ChangeNotifier {
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  bool _isFirebaseInitialized = false;

  // Listas en memoria para el Modo Demo
  final List<SectorModel> _demoSectors = [];
  final List<CoordinatorModel> _demoCoordinators = [];

  FirestoreService(bool isFirebaseInitialized) {
    _isFirebaseInitialized = isFirebaseInitialized;
    if (!_isFirebaseInitialized) {
      _initDemoData();
    }
  }

  void _initDemoData() {
    // Inicializar coordinadores demo
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

    // Inicializar sectores demo
    _demoSectors.addAll([
      SectorModel(
        id: 'sec_1',
        name: 'Sector Centro Histórico',
        zone: 'Centro',
        description: 'Campaña de vacunación antirrábica en plazas principales.',
        status: 'En Proceso',
        assignedCoordinatorId: 'demo_brigada_uid',
        assignedCoordinatorName: 'Ana López',
      ),
      SectorModel(
        id: 'sec_2',
        name: 'Sector Carcelén',
        zone: 'Norte',
        description: 'Censo de mascotas callejeras y esterilización.',
        status: 'Pendiente',
        assignedCoordinatorId: null,
        assignedCoordinatorName: null,
      ),
      SectorModel(
        id: 'sec_3',
        name: 'Sector Villa Flora',
        zone: 'Sur',
        description: 'Atención primaria veterinaria y desparasitación.',
        status: 'Completado',
        assignedCoordinatorId: 'demo_brigada_uid',
        assignedCoordinatorName: 'Ana López',
      ),
      SectorModel(
        id: 'sec_4',
        name: 'Sector Cumbayá',
        zone: 'Valles',
        description: 'Monitoreo de aves urbanas y control de parásitos.',
        status: 'Pendiente',
        assignedCoordinatorId: null,
        assignedCoordinatorName: null,
      ),
      SectorModel(
        id: 'sec_5',
        name: 'Sector La Mariscal',
        zone: 'Norte',
        description: 'Campaña educativa sobre tenencia responsable.',
        status: 'Pendiente',
        assignedCoordinatorId: null,
        assignedCoordinatorName: null,
      ),
    ]);
  }

  // ==========================================
  // OPERACIONES DE SECTORES (CRUD)
  // ==========================================

  // Escuchar sectores en tiempo real
  Stream<List<SectorModel>> getSectorsStream() {
    if (_isFirebaseInitialized) {
      return _db.collection('sectores').snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return SectorModel.fromMap(doc.data(), doc.id);
        }).toList();
      });
    } else {
      // Retorna un stream local simulado
      return Stream.value(_demoSectors);
    }
  }

  // Crear un sector
  Future<void> addSector(SectorModel sector) async {
    if (_isFirebaseInitialized) {
      // Firestore Real
      await _db.collection('sectores').add(sector.toMap());
    } else {
      // Modo Demo
      String newId = 'sec_${DateTime.now().millisecondsSinceEpoch}';
      _demoSectors.add(sector.copyWith(id: newId));
      notifyListeners();
    }
  }

  // Actualizar un sector
  Future<void> updateSector(SectorModel sector) async {
    if (_isFirebaseInitialized) {
      await _db.collection('sectores').doc(sector.id).update(sector.toMap());
    } else {
      int index = _demoSectors.indexWhere((s) => s.id == sector.id);
      if (index != -1) {
        _demoSectors[index] = sector;
        notifyListeners();
      }
    }
  }

  // Eliminar un sector
  Future<void> deleteSector(String id) async {
    if (_isFirebaseInitialized) {
      await _db.collection('sectores').doc(id).delete();
    } else {
      _demoSectors.removeWhere((s) => s.id == id);
      notifyListeners();
    }
  }

  // ==========================================
  // OPERACIONES DE COORDINADORES (CRUD)
  // ==========================================

  // Escuchar coordinadores en tiempo real (de la colección usuarios con rol coordinador_brigada)
  Stream<List<CoordinatorModel>> getCoordinatorsStream() {
    if (_isFirebaseInitialized) {
      return _db
          .collection('usuarios')
          .where('role', isEqualTo: 'coordinador_brigada')
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

  // Crear Coordinador (El Auth se crea por fuera en AuthService)
  Future<void> saveCoordinatorProfile(String uid, CoordinatorModel coordinator) async {
    if (_isFirebaseInitialized) {
      // Guardar perfil en la colección usuarios
      Map<String, dynamic> data = coordinator.toMap();
      data['role'] = 'coordinador_brigada';
      data['isFirstLogin'] = true;
      data['name'] = coordinator.nombreCompleto; // Campo name para login
      await _db.collection('usuarios').doc(uid).set(data);

      // Sincronizar asignación de sectores
      await syncSectorAssignments(uid, coordinator.nombreCompleto, coordinator.assignedSectorIds);
    } else {
      // Modo Demo
      _demoCoordinators.add(coordinator.copyWith(id: uid));
      await syncSectorAssignments(uid, coordinator.nombreCompleto, coordinator.assignedSectorIds);
      notifyListeners();
    }
  }

  // Actualizar Coordinador
  Future<void> updateCoordinator(CoordinatorModel coordinator) async {
    if (_isFirebaseInitialized) {
      Map<String, dynamic> data = coordinator.toMap();
      data['role'] = 'coordinador_brigada';
      data['name'] = coordinator.nombreCompleto;
      await _db.collection('usuarios').doc(coordinator.id).update(data);

      // Sincronizar asignación de sectores
      await syncSectorAssignments(coordinator.id, coordinator.nombreCompleto, coordinator.assignedSectorIds);
    } else {
      int index = _demoCoordinators.indexWhere((c) => c.id == coordinator.id);
      if (index != -1) {
        _demoCoordinators[index] = coordinator;
        await syncSectorAssignments(coordinator.id, coordinator.nombreCompleto, coordinator.assignedSectorIds);
        notifyListeners();
      }
    }
  }

  // Desactivar o eliminar coordinador
  Future<void> deleteCoordinator(String uid) async {
    if (_isFirebaseInitialized) {
      // Desasignar sectores primero
      await syncSectorAssignments(uid, '', []);
      // Eliminar de Firestore
      await _db.collection('usuarios').doc(uid).delete();
    } else {
      // Desasignar sectores en demo
      await syncSectorAssignments(uid, '', []);
      _demoCoordinators.removeWhere((c) => c.id == uid);
      notifyListeners();
    }
  }

  // Sincronizar asignación de sectores en doble vía
  Future<void> syncSectorAssignments(String coordinatorId, String coordinatorName, List<String> assignedSectorIds) async {
    if (_isFirebaseInitialized) {
      // 1. Obtener todos los sectores que actualmente tienen asignado a este coordinador
      QuerySnapshot currentAssigned = await _db
          .collection('sectores')
          .where('assignedCoordinatorId', isEqualTo: coordinatorId)
          .get();

      // 2. Limpiar la asignación de los sectores que ya no están en la lista
      for (var doc in currentAssigned.docs) {
        if (!assignedSectorIds.contains(doc.id)) {
          await _db.collection('sectores').doc(doc.id).update({
            'assignedCoordinatorId': null,
            'assignedCoordinatorName': null,
          });
        }
      }

      // 3. Asignar el coordinador a los sectores seleccionados
      for (var sectorId in assignedSectorIds) {
        await _db.collection('sectores').doc(sectorId).update({
          'assignedCoordinatorId': coordinatorId,
          'assignedCoordinatorName': coordinatorName.isEmpty ? null : coordinatorName,
        });
      }
    } else {
      // Sincronización en Modo Demo
      // 1. Limpiar sectores viejos
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

      // 2. Asignar sectores nuevos
      for (var sectorId in assignedSectorIds) {
        int idx = _demoSectors.indexWhere((s) => s.id == sectorId);
        if (idx != -1) {
          _demoSectors[idx] = _demoSectors[idx].copyWith(
            assignedCoordinatorId: coordinatorId,
            assignedCoordinatorName: coordinatorName.isEmpty ? null : coordinatorName,
          );
        }
      }
    }
  }

  // Sembrar sectores (se llama desde SeedService)
  Future<void> seedSectors(List<SectorModel> sectors) async {
    if (_isFirebaseInitialized) {
      for (var sector in sectors) {
        await _db.collection('sectores').add(sector.toMap());
      }
    } else {
      _demoSectors.clear();
      _demoSectors.addAll(sectors);
      notifyListeners();
    }
  }

  // Retorna una lista estática para validación rápida
  Future<bool> checkSectorsEmpty() async {
    if (_isFirebaseInitialized) {
      QuerySnapshot snap = await _db.collection('sectores').limit(1).get();
      return snap.docs.isEmpty;
    } else {
      return _demoSectors.isEmpty;
    }
  }
}
