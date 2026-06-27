import '../models/sector_model.dart';
import 'firestore_service.dart';

class SeedService {
  // Lista de barrios precargados para Quito, Ecuador (mínimo 5 sectores)
  static final List<SectorModel> _preloadedSectors = [
    SectorModel(
      id: '', // Se autogenerará en Firestore
      name: 'Centro Histórico (Quito)',
      zone: 'Centro',
      description: 'Sector patrimonial. Campaña especial de vacunación felina y canina en plazas.',
      status: 'Pendiente',
    ),
    SectorModel(
      id: '',
      name: 'La Carolina',
      zone: 'Norte',
      description: 'Sector comercial y parque. Puntos de esterilización móvil en el parque central.',
      status: 'Pendiente',
    ),
    SectorModel(
      id: '',
      name: 'Villa Flora',
      zone: 'Sur',
      description: 'Sector residencial del sur. Brigadas de desparasitación puerta a puerta.',
      status: 'Pendiente',
    ),
    SectorModel(
      id: '',
      name: 'Carcelén',
      zone: 'Norte',
      description: 'Sector residencial del extremo norte. Control de sobrepoblación de mascotas.',
      status: 'Pendiente',
    ),
    SectorModel(
      id: '',
      name: 'Cumbayá',
      zone: 'Valles',
      description: 'Valle de Quito. Campaña educativa y atención de salud animal en clínicas móviles.',
      status: 'Pendiente',
    ),
  ];

  // Ejecuta la precarga si la colección sectores está vacía
  static Future<void> checkAndSeed(FirestoreService firestoreService) async {
    try {
      bool isEmpty = await firestoreService.checkSectorsEmpty();
      if (isEmpty) {
        await firestoreService.seedSectors(_preloadedSectors);
        print("====== SEED AUTOMÁTICO REALIZADO: 5 sectores de Quito precargados en Firestore ======");
      }
    } catch (e) {
      print("Error al ejecutar el seed de sectores: $e");
    }
  }
}
