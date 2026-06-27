import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/coordinator_model.dart';
import '../../models/sector_model.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';

class CoordinatorsListView extends StatelessWidget {
  const CoordinatorsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: VetTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Coordinadores de Brigada'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: VetTheme.primary,
        onPressed: () {
          Navigator.pushNamed(context, '/coordinator_form');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: StreamBuilder<List<CoordinatorModel>>(
          stream: firestoreService.getCoordinatorsStream(),
          builder: (context, coordSnapshot) {
            if (coordSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: VetTheme.primary));
            }

            if (coordSnapshot.hasError) {
              return Center(child: Text('Error al cargar datos: ${coordSnapshot.error}'));
            }

            final coordinators = coordSnapshot.data ?? [];

            if (coordinators.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: VetTheme.textLight.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text(
                      'No hay coordinadores registrados.',
                      style: TextStyle(color: VetTheme.textLight, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return StreamBuilder<List<SectorModel>>(
              stream: firestoreService.getSectorsStream(),
              builder: (context, sectorsSnapshot) {
                final sectors = sectorsSnapshot.data ?? [];

                return ListView.separated(
                  padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 80.0, top: 10.0),
                  itemCount: coordinators.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final coordinator = coordinators[index];
                    
                    // Obtener nombres de sectores asignados
                    final assignedSectors = sectors
                        .where((s) => coordinator.assignedSectorIds.contains(s.id))
                        .map((s) => s.name.replaceAll(' (Quito)', ''))
                        .toList();

                    final bool isActive = coordinator.status == 'Activo';

                    return GlassCard(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  coordinator.nombreCompleto,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: VetTheme.textDark,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isActive ? Colors.green : VetTheme.accent).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: (isActive ? Colors.green : VetTheme.accent).withOpacity(0.3)),
                                ),
                                child: Text(
                                  coordinator.status,
                                  style: TextStyle(
                                    color: isActive ? Colors.green : VetTheme.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Cédula y Teléfono
                          Row(
                            children: [
                              const Icon(Icons.badge_outlined, size: 16, color: VetTheme.primary),
                              const SizedBox(width: 4),
                              Text('C.I: ${coordinator.cedula}', style: const TextStyle(color: VetTheme.textLight, fontSize: 13)),
                              const SizedBox(width: 16),
                              const Icon(Icons.phone_outlined, size: 16, color: VetTheme.primary),
                              const SizedBox(width: 4),
                              Text(coordinator.telefono, style: const TextStyle(color: VetTheme.textLight, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          
                          // Correo
                          Row(
                            children: [
                              const Icon(Icons.email_outlined, size: 16, color: VetTheme.primary),
                              const SizedBox(width: 4),
                              Text(coordinator.email, style: const TextStyle(color: VetTheme.textLight, fontSize: 13)),
                            ],
                          ),
                          const Divider(height: 24, thickness: 1, color: VetTheme.glassBorder),

                          // Sectores Asignados
                          const Text(
                            'Sectores Asignados:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: VetTheme.textDark, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          if (assignedSectors.isEmpty)
                            const Text(
                              'Ningún sector asignado.',
                              style: TextStyle(color: VetTheme.accent, fontSize: 13, fontStyle: FontStyle.italic),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: assignedSectors.map((secName) {
                                return Chip(
                                  label: Text(
                                    secName,
                                    style: const TextStyle(color: VetTheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: VetTheme.primary.withOpacity(0.1),
                                  side: BorderSide(color: VetTheme.primary.withOpacity(0.2)),
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                );
                              }).toList(),
                            ),

                          const Divider(height: 24, thickness: 1, color: VetTheme.glassBorder),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit_outlined, color: VetTheme.primary, size: 18),
                                label: const Text('Editar y Asignar', style: TextStyle(color: VetTheme.primary, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  Navigator.pushNamed(context, '/coordinator_form', arguments: coordinator);
                                },
                              ),
                              const SizedBox(width: 12),
                              TextButton.icon(
                                icon: const Icon(Icons.delete_outline, color: VetTheme.accent, size: 18),
                                label: const Text('Eliminar', style: TextStyle(color: VetTheme.accent, fontWeight: FontWeight.bold)),
                                onPressed: () => _confirmDelete(context, firestoreService, coordinator),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirestoreService firestoreService, CoordinatorModel coordinator) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¿Eliminar Coordinador?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('¿Estás seguro de que deseas eliminar a "${coordinator.nombreCompleto}"? Se desasignarán todos sus sectores de forma automática.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: VetTheme.textLight)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await firestoreService.deleteCoordinator(coordinator.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Coordinador "${coordinator.nombreCompleto}" eliminado correctamente.'),
                      backgroundColor: VetTheme.accent,
                    ),
                  );
                }
              },
              child: const Text('Eliminar', style: TextStyle(color: VetTheme.accent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
