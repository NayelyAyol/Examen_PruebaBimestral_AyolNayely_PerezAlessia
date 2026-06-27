import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import '../../models/sector_model.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';

class SectorsListView extends StatefulWidget {
  const SectorsListView({super.key});

  @override
  State<SectorsListView> createState() => _SectorsListViewState();
}

class _SectorsListViewState extends State<SectorsListView> {
  String _selectedStatus = 'Todos';
  String _selectedZone = 'Todos';

  final List<String> _statuses = ['Todos', 'Pendiente', 'En Proceso', 'Completado'];
  final List<String> _zones = ['Todos', 'Norte', 'Sur', 'Centro', 'Valles'];

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: VetTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Gestión de Sectores'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: VetTheme.primary,
        onPressed: () {
          Navigator.pushNamed(context, '/sector_form');
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: Column(
          children: [
            // Filtros en la parte superior
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.filter_alt_outlined, color: VetTheme.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Filtros de Búsqueda',
                          style: TextStyle(fontWeight: FontWeight.bold, color: VetTheme.textDark, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Filtro Estado
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Estado',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _statuses.map((status) {
                              return DropdownMenuItem(value: status, child: Text(status));
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedStatus = val!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Filtro Zona
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedZone,
                            decoration: const InputDecoration(
                              labelText: 'Zona',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _zones.map((zone) {
                              return DropdownMenuItem(value: zone, child: Text(zone));
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedZone = val!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Lista de Sectores
            Expanded(
              child: StreamBuilder<List<SectorModel>>(
                stream: firestoreService.getSectorsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: VetTheme.primary));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
                  }

                  var sectors = snapshot.data ?? [];

                  // Aplicar filtros localmente para agilidad
                  if (_selectedStatus != 'Todos') {
                    sectors = sectors.where((s) => s.status == _selectedStatus).toList();
                  }
                  if (_selectedZone != 'Todos') {
                    sectors = sectors.where((s) => s.zone == _selectedZone).toList();
                  }

                  if (sectors.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 64, color: VetTheme.textLight.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'No se encontraron sectores con estos filtros.',
                            style: TextStyle(color: VetTheme.textLight, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 80.0, top: 10.0),
                    itemCount: sectors.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final sector = sectors[index];
                      Color statusColor = VetTheme.textLight;
                      if (sector.status == 'En Proceso') statusColor = Colors.orange;
                      if (sector.status == 'Completado') statusColor = Colors.green;

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
                                    sector.name,
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
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    sector.status,
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: VetTheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Zona: ${sector.zone}',
                                  style: const TextStyle(color: VetTheme.textLight, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.person_outline, size: 16, color: VetTheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'Coord: ${sector.assignedCoordinatorName ?? "Ninguno"}',
                                  style: const TextStyle(color: VetTheme.textLight, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              sector.description,
                              style: const TextStyle(color: VetTheme.textLight, fontSize: 14, height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Divider(height: 24, thickness: 1, color: VetTheme.glassBorder),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Botón Editar
                                TextButton.icon(
                                  icon: const Icon(Icons.edit, color: VetTheme.primary, size: 18),
                                  label: const Text('Editar', style: TextStyle(color: VetTheme.primary, fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/sector_form', arguments: sector);
                                  },
                                ),
                                const SizedBox(width: 12),
                                // Botón Eliminar
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline, color: VetTheme.accent, size: 18),
                                  label: const Text('Eliminar', style: TextStyle(color: VetTheme.accent, fontWeight: FontWeight.bold)),
                                  onPressed: () => _confirmDelete(context, firestoreService, sector),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FirestoreService firestoreService, SectorModel sector) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('¿Eliminar Sector?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text('¿Estás seguro de que deseas eliminar el sector "${sector.name}"? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: VetTheme.textLight)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await firestoreService.deleteSector(sector.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sector "${sector.name}" eliminado correctamente.'),
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
