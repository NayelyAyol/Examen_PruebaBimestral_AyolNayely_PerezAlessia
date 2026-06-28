import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/sector_model.dart';
import '../../theme/vet_theme.dart';
import '../../widgets/glass_card.dart';

class BrigadaDashboard extends StatelessWidget {
  const BrigadaDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Brigadista'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: VetTheme.textDark),
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: VetTheme.backgroundGradient,
        child: StreamBuilder<List<SectorModel>>(
          stream: firestoreService.getSectorsStream(),
          builder: (context, snapshot) {
            final sectors = snapshot.data ?? [];

            // Filtrar sólo los sectores asignados a este coordinador
            final mySectors = sectors
                .where((s) => s.assignedCoordinatorId == user?.uid)
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera de bienvenida
                  GlassCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: VetTheme.primary.withOpacity(0.2),
                          child: const Icon(
                            Icons.pets,
                            color: VetTheme.primary,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenido, ${user?.name ?? "Brigadista"}',
                                style: const TextStyle(
                                  color: VetTheme.textDark,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Coordinador de Brigada',
                                style: TextStyle(
                                  color: VetTheme.textLight,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Acceso a la gestión de vacunadores
                  GlassCard(
                    child: ListTile(
                      leading: const Icon(
                        Icons.vaccines_outlined,
                        color: VetTheme.primary,
                        size: 32,
                      ),
                      title: const Text(
                        'Gestionar Vacunadores',
                        style: TextStyle(
                          color: VetTheme.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text(
                        'Crear, editar y asignar vacunadores a sectores',
                        style: TextStyle(color: VetTheme.textLight),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: VetTheme.textLight,
                      ),
                      onTap: () {
                        Navigator.pushNamed(context, '/vaccinators');
                      },
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Mis Sectores Asignados',
                    style: TextStyle(
                      color: VetTheme.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (mySectors.isEmpty)
                    GlassCard(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_late_outlined,
                              size: 48,
                              color: VetTheme.textLight.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No tienes sectores asignados en este momento.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: VetTheme.textLight,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mySectors.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final sector = mySectors[index];
                        return _buildSectorCard(
                          context,
                          firestoreService,
                          sector,
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Información de ayuda de roles en modo demo
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: VetTheme.primary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Información del Rol',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: VetTheme.textDark,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Como Coordinador de Brigada, puedes ver tus sectores asignados, actualizar su estado y gestionar los vacunadores de tu brigada.',
                          style: TextStyle(
                            color: VetTheme.textLight.withOpacity(0.9),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectorCard(
    BuildContext context,
    FirestoreService firestoreService,
    SectorModel sector,
  ) {
    Color statusColor = VetTheme.textLight;
    if (sector.status == 'En Proceso') statusColor = Colors.orange;
    if (sector.status == 'Completado') statusColor = Colors.green;

    return GlassCard(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  sector.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Zona: ${sector.zone}',
            style: const TextStyle(
              color: VetTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sector.description,
            style: const TextStyle(
              color: VetTheme.textLight,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const Divider(height: 24, thickness: 1, color: VetTheme.glassBorder),

          // Cambiar de estado rápido
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Actualizar estado:',
                style: TextStyle(
                  color: VetTheme.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  _statusButton(
                    context,
                    firestoreService,
                    sector,
                    'En Proceso',
                    Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _statusButton(
                    context,
                    firestoreService,
                    sector,
                    'Completado',
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusButton(
    BuildContext context,
    FirestoreService firestoreService,
    SectorModel sector,
    String targetStatus,
    Color color,
  ) {
    final bool isCurrent = sector.status == targetStatus;

    return ElevatedButton(
      onPressed: isCurrent
          ? null
          : () async {
              SectorModel updatedSector =
                  sector.copyWith(status: targetStatus);
              await firestoreService.updateSector(updatedSector);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Sector "${sector.name}" actualizado a $targetStatus',
                    ),
                    backgroundColor: color,
                  ),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrent ? color.withOpacity(0.2) : color,
        foregroundColor: Colors.white,
        disabledForegroundColor: color.withOpacity(0.6),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        targetStatus,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}