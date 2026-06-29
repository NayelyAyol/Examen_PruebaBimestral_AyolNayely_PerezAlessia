import '../models/sector_model.dart';
import 'firestore_service.dart';

class SeedService {
  static final List<SectorModel> _preloadedSectors = [
    SectorModel(
      id: '',
      name: 'Centro Histórico (Quito)',
      zone: 'Centro',
      description:
          'Sector patrimonial. Campaña especial de vacunación felina y canina en plazas.',
    ),
    SectorModel(
      id: '',
      name: 'La Carolina',
      zone: 'Norte',
      description:
          'Sector comercial y parque. Puntos de vacunación móvil en el parque central.',
    ),
    SectorModel(
      id: '',
      name: 'Villa Flora',
      zone: 'Sur',
      description:
          'Sector residencial del sur. Brigadas de vacunación puerta a puerta.',
    ),
    SectorModel(
      id: '',
      name: 'Carcelén',
      zone: 'Norte',
      description:
          'Sector residencial del extremo norte. Control y vacunación de mascotas.',
    ),
    SectorModel(
      id: '',
      name: 'Cumbayá',
      zone: 'Valles',
      description:
          'Valle de Quito. Campaña educativa y atención de salud animal en clínicas móviles.',
    ),
  ];

  static Future<void> checkAndSeed(FirestoreService firestoreService) async {
    try {
      final isEmpty = await firestoreService.checkSectorsEmpty();

      if (isEmpty) {
        await firestoreService.seedSectors(_preloadedSectors);
        print(
          '====== SEED AUTOMÁTICO REALIZADO: 5 sectores de Quito precargados ======',
        );
      }
    } catch (e) {
      print('Error al ejecutar el seed de sectores: $e');
    }
  }
}